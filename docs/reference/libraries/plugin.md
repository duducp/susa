# plugin.sh

Funções para gerenciamento de metadados de plugins.

> **Nota:** Funções Git foram movidas para [git.sh](git.md).

## Funções de Metadata

### `detect_plugin_version()`

Detecta a versão de um plugin no diretório.

**Lógica:**

1. Verifica `version.txt`
2. Se não existe, retorna "0.0.0"

```bash
version=$(detect_plugin_version "/opt/susa/plugins/myplugin")
echo "Versão: $version"
```

### `count_plugin_commands()`

Conta quantos comandos um plugin possui.

```bash
count=$(count_plugin_commands "/opt/susa/plugins/myplugin")
echo "Plugin tem $count comandos"
```

### `clone_plugin()`

Clona plugin de um repositório Git e remove pasta .git.

**Parâmetros:**

- `$1` - URL do repositório
- `$2` - Diretório de destino

```bash
if clone_plugin "https://github.com/user/plugin.git" "/opt/susa/plugins/plugin"; then
    echo "Plugin clonado com sucesso"
fi
```

### `normalize_git_url()`

Converte formato `user/repo` para URL completa. Suporta GitHub, GitLab e Bitbucket.

**Parâmetros:**

- `$1` - URL ou formato `user/repo`
- `$2` - Force SSH (opcional, padrão: false)
- `$3` - Provider (opcional, padrão: github). Valores: `github`, `gitlab`, `bitbucket`

**Comportamento:**

- Se `user/repo`: converte para SSH (se disponível ou forçado) ou HTTPS
- Detecta automaticamente SSH para cada provedor
- Se URL completa HTTPS + force SSH: converte para SSH
- Caso contrário: retorna URL inalterada

```bash
# GitHub (padrão)
url=$(normalize_git_url "user/repo")
echo "$url"  # git@github.com:user/repo.git (se SSH disponível)

# GitLab
url=$(normalize_git_url "user/repo" "false" "gitlab")
echo "$url"  # https://gitlab.com/user/repo.git

# Bitbucket com SSH forçado
url=$(normalize_git_url "user/repo" "true" "bitbucket")
echo "$url"  # git@bitbucket.org:user/repo.git

# Converter HTTPS para SSH
url=$(normalize_git_url "https://gitlab.com/user/repo.git" "true")
echo "$url"  # git@gitlab.com:user/repo.git
```

### `extract_plugin_name()`

Extrai nome do plugin da URL.

```bash
name=$(extract_plugin_name "https://github.com/user/awesome-plugin.git")
echo "$name"  # awesome-plugin
```

## Exemplo Completo

```bash
#!/bin/bash
```bash
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/git.sh"
source "$LIB_DIR/logger.sh"

# Parse argumentos
use_ssh="false"
if [ "$2" = "--ssh" ]; then
    use_ssh="true"
fi

# Garante git instalado
ensure_git_installed || exit 1

# Normaliza URL (com detecção/forçar SSH)
url=$(normalize_git_url "$1" "$use_ssh")
name=$(extract_plugin_name "$url")

log_info "Instalando plugin: $name"
log_debug "URL: $url"

# Valida acesso ao repositório
if ! validate_repo_access "$url"; then
    log_error "Não foi possível acessar o repositório"
    echo ""
    echo "Possíveis causas:"
    echo "  • Repositório não existe"
    echo "  • Repositório privado sem acesso"
    echo "  • Credenciais não configuradas"
    exit 1
fi

# Clona plugin
if clone_plugin "$url" "$PLUGINS_DIR/$name"; then
    version=$(detect_plugin_version "$PLUGINS_DIR/$name")
    count=$(count_plugin_commands "$PLUGINS_DIR/$name")

    log_success "Plugin $name v$version instalado!"
    log_info "Total de comandos: $count"
else
    log_error "Falha ao clonar plugin"
    exit 1
fi
```

## Boas Práticas

1. **Sempre normalize URLs** antes de clonar usando `normalize_git_url()`
2. **Verifique git instalado** antes de usar - use `ensure_git_installed()` de [git.sh](git.md)
3. **Valide acesso ao repo** antes de clonar - use `validate_repo_access()` de [git.sh](git.md)
4. **Detecte SSH automaticamente** usando `has_github_ssh_access()` de [git.sh](git.md) para melhor UX
5. **Ofereça opção `--ssh`** para usuários forçarem autenticação SSH
6. **Valide estrutura do plugin** após clonar contando comandos
7. **Forneça feedback claro** em caso de falha de acesso (mensagens úteis)

## Repositórios Privados

### Detecção Automática

A biblioteca detecta automaticamente se SSH está configurado (via [git.sh](git.md)):

```bash
# Usuário com SSH configurado
url=$(normalize_git_url "org/private-plugin")
# Retorna: git@github.com:org/private-plugin.git

# Usuário sem SSH
url=$(normalize_git_url "org/private-plugin")
# Retorna: https://github.com/org/private-plugin.git
```

### Validação de Acesso

Sempre valide antes de clonar para evitar falhas tardias (use função de [git.sh](git.md)):

```bash
if ! validate_repo_access "$url"; then
    # Mensagens de erro específicas aqui
    exit 1
fi

# Agora pode clonar com segurança
clone_plugin "$url" "$dest"
```
