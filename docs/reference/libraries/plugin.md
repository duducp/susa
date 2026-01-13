# plugin.sh

Funções para gerenciamento de plugins.

## Funções

### `ensure_git_installed()`

Verifica se git está instalado.

**Retorno:**

- `0` - git disponível
- `1` - git não encontrado

```bash
ensure_git_installed || {
    echo "Git é necessário"
    exit 1
}
```

### `detect_plugin_version()`

Detecta a versão de um plugin no diretório.

**Lógica:**

1. Verifica `version.txt`
2. Se não existe, verifica `VERSION`
3. Se não existe, retorna "1.0.0"

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

Converte formato `user/repo` para URL completa do GitHub.

```bash
url=$(normalize_git_url "user/repo")
echo "$url"  # https://github.com/user/repo.git

url=$(normalize_git_url "https://gitlab.com/user/repo.git")
echo "$url"  # https://gitlab.com/user/repo.git
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
source "$CLI_DIR/lib/plugin.sh"
source "$CLI_DIR/lib/logger.sh"

# Garante git instalado
ensure_git_installed || exit 1

# Normaliza URL
url=$(normalize_git_url "$1")
name=$(extract_plugin_name "$url")

log_info "Instalando plugin: $name"

# Clone plugin
plugin_dir="/opt/susa/plugins/$name"

if clone_plugin "$url" "$plugin_dir"; then
    version=$(detect_plugin_version "$plugin_dir")
    count=$(count_plugin_commands "$plugin_dir")

    log_success "Plugin $name v$version instalado!"
    log_info "Total de comandos: $count"
else
    log_error "Falha ao clonar plugin"
    exit 1
fi
```

## Boas Práticas

1. Sempre normalize URLs antes de clonar
2. Verifique se git está instalado antes de usar
3. Valide estrutura do plugin após clonar
