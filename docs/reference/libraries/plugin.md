# plugin.sh

Funções para gerenciamento de metadados de plugins.

> **Nota:** Funções Git foram movidas para [git.sh](git.md).

## Funções de Metadata

### `validate_plugin_config()`

Valida se um plugin possui um `plugin.json` válido.

**Validações:**

- Arquivo `plugin.json` existe
- JSON é válido (sintaxe)
- Campo `name` está presente e não vazio
- Campo `version` está presente e não vazio

**Retorno:** 0 se válido, 1 se inválido

```bash
if validate_plugin_config "/opt/susa/plugins/myplugin"; then
    echo "Plugin válido"
else
    echo "Plugin inválido ou plugin.json ausente"
    exit 1
fi
```

### `read_plugin_config()`

Lê todos os metadados do `plugin.json` do plugin.

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** String no formato `name|version|description|directory`

**Nota:** Retorna erro (exit 1) se plugin.json não existir ou for inválido.

```bash
config=$(read_plugin_config "/opt/susa/plugins/myplugin")
IFS='|' read -r name version description directory <<< "$config"

echo "Nome: $name"
echo "Versão: $version"
echo "Descrição: $description"
echo "Diretório: $directory"
```

### `detect_plugin_version()`

Detecta a versão de um plugin do arquivo `plugin.json`.

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** Versão do plugin ou erro se plugin.json não existir

**Nota:** ⚠️ `plugin.json` é obrigatório. Retorna erro se não encontrado.

```bash
version=$(detect_plugin_version "/opt/susa/plugins/myplugin")
if [ $? -eq 0 ]; then
    echo "Versão: $version"
else
    echo "Erro: plugin.json não encontrado"
fi
```

### `get_plugin_name()`

Obtém o nome do plugin do arquivo `plugin.json`.

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** Nome do plugin ou erro se inválido

```bash
name=$(get_plugin_name "/opt/susa/plugins/myplugin")
echo "Nome: $name"
```

### `get_plugin_description()`

Obtém a descrição do plugin do arquivo `plugin.json`.

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** Descrição do plugin ou string vazia se não especificada

```bash
description=$(get_plugin_description "/opt/susa/plugins/myplugin")
if [ -n "$description" ]; then
    echo "Descrição: $description"
fi
```

### `get_plugin_directory()`

Obtém o subdiretório onde os comandos estão localizados (campo `directory` do `plugin.json`).

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** Nome do subdiretório ou string vazia se não especificado

```bash
directory=$(get_plugin_directory "/opt/susa/plugins/myplugin")
if [ -n "$directory" ]; then
    echo "Comandos em: $directory/"
    commands_path="$plugin_dir/$directory"
else
    echo "Comandos na raiz"
    commands_path="$plugin_dir"
fi
```

### `count_plugin_commands()`

Conta quantos comandos um plugin possui.

**Parâmetros:**

- `$1` - Diretório do plugin

**Comportamento:**

- Se plugin tem campo `directory` no plugin.json, conta apenas comandos dentro desse subdiretório
- Caso contrário, conta comandos na raiz

```bash
count=$(count_plugin_commands "/opt/susa/plugins/myplugin")
echo "Plugin tem $count comandos"
```

### `get_plugin_categories()`

Obtém lista de categorias (diretórios de primeiro nível) do plugin.

**Parâmetros:**

- `$1` - Diretório do plugin

**Retorno:** Lista de categorias separadas por vírgula

**Comportamento:**

- Se plugin tem campo `directory` no plugin.json, lista categorias dentro desse subdiretório
- Caso contrário, lista categorias na raiz

```bash
categories=$(get_plugin_categories "/opt/susa/plugins/myplugin")
echo "Categorias: $categories"
# Output: deploy,backup,setup
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
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

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
    # Valida plugin.json (OBRIGATÓRIO)
    if ! validate_plugin_config "$PLUGINS_DIR/$name"; then
        log_error "Plugin inválido: plugin.json não encontrado ou inválido"
        echo ""
        echo "O plugin deve ter um arquivo plugin.json com:"
        echo "  • name: Nome do plugin (obrigatório)"
        echo "  • version: Versão semver (obrigatório)"
        echo "  • description: Descrição (opcional)"
        echo "  • directory: Subdiretório de comandos (opcional)"
        rm -rf "$PLUGINS_DIR/$name"
        exit 1
    fi

    # Lê metadados do plugin
    version=$(detect_plugin_version "$PLUGINS_DIR/$name")
    description=$(get_plugin_description "$PLUGINS_DIR/$name")
    count=$(count_plugin_commands "$PLUGINS_DIR/$name")
    categories=$(get_plugin_categories "$PLUGINS_DIR/$name")

    log_success "Plugin $name v$version instalado!"
    [ -n "$description" ] && log_info "$description"
    log_info "Total de comandos: $count"
    log_info "Categorias: $categories"
else
    log_error "Falha ao clonar plugin"
    exit 1
fi
```

## Boas Práticas

1. **Sempre valide plugin.json** após clonar usando `validate_plugin_config()`
2. **Rejeite plugins inválidos** e remova o diretório clonado
3. **Normalize URLs** antes de clonar usando `normalize_git_url()`
4. **Verifique git instalado** antes de usar - use `ensure_git_installed()` de [git.sh](git.md)
5. **Valide acesso ao repo** antes de clonar - use `validate_repo_access()` de [git.sh](git.md)
6. **Detecte SSH automaticamente** usando `has_github_ssh_access()` de [git.sh](git.md) para melhor UX
7. **Ofereça opção `--ssh`** para usuários forçarem autenticação SSH
8. **Use metadados do plugin.json** (descrição, versão, directory) para melhor feedback
9. **Forneça feedback claro** em caso de plugin.json inválido ou ausente

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
