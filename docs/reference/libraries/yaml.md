# yaml.sh

Parser YAML usando yq para configurações.

## Configuração Inicial

Antes de usar, defina:

```bash
GLOBAL_CONFIG_FILE="/path/to/cli.yaml"
CLI_DIR="/path/to/susa"
```

## Funções - Config Global

### `get_yaml_field()`

Obtém campos do arquivo cli.yaml.

**Parâmetros:**

- `$1` - Caminho do arquivo yaml
- `$2` - Campo (name, description, version, commands_dir, plugins_dir)

**Uso:**

```bash
name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
```

### `discover_categories()`

Descobre categorias da estrutura de diretórios (commands/ e plugins/).

```bash
categories=$(discover_categories)
for cat in $categories; do
    echo "Categoria: $cat"
done
```

### `get_category_info()`

Obtém informações de uma categoria do config.yaml dela.

**Parâmetros:**

- `$1` - Caminho do arquivo yaml global
- `$2` - Nome da categoria
- `$3` - Campo (name, description)

```bash
desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "setup" "description")
echo "Categoria setup: $desc"
```

## Funções - Discovery de Comandos

### `is_command_dir()`

Verifica se um diretório é um comando (tem config.yaml com campo script).

**Retorno:**

- `0` - É um comando
- `1` - Não é comando (é subcategoria)

```bash
if is_command_dir "/opt/susa/commands/setup/asdf"; then
    echo "É um comando"
else
    echo "É uma subcategoria"
fi
```

### `discover_items_in_category()`

Descobre comandos e subcategorias em uma categoria.

**Parâmetros:**

- `$1` - Diretório base (commands/ ou plugins/nome)
- `$2` - Caminho da categoria (ex: "setup" ou "setup/python")
- `$3` - Tipo: "commands", "subcategories", ou "all" (padrão: "all")

**Retorno:** Linhas no formato `command:nome` ou `subcategory:nome`

```bash
# Todos os itens
discover_items_in_category "$CLI_DIR/commands" "setup" "all"

# Apenas comandos
discover_items_in_category "$CLI_DIR/commands" "setup" "commands" | sed 's/^command://'
```

### `get_category_commands()`

Obtém comandos de uma categoria.

```bash
commands=$(get_category_commands "setup")
for cmd in $commands; do
    echo "Comando: $cmd"
done
```

## Funções - Config de Comandos

### `get_command_config_field()`

Lê um campo do config.yaml de um comando.

**Parâmetros:**

- `$1` - Caminho do arquivo config.yaml
- `$2` - Campo (category, id, name, description, script, sudo, os)

```bash
name=$(get_command_config_field "/opt/susa/commands/setup/asdf/config.yaml" "name")
```

### `find_command_config()`

Encontra o arquivo config.yaml de um comando.

```bash
config=$(find_command_config "setup" "asdf")
echo "$config"  # /opt/susa/commands/setup/asdf/config.yaml
```

### `get_command_info()`

Obtém informação de um comando específico.

**Parâmetros:**

- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - ID do comando
- `$4` - Campo (name, description, script, sudo, os)

```bash
script=$(get_command_info "$GLOBAL_CONFIG_FILE" "setup" "asdf" "script")
needs_sudo=$(get_command_info "$GLOBAL_CONFIG_FILE" "setup" "asdf" "sudo")
```

### `is_command_compatible()`

Verifica se comando é compatível com o SO atual.

```bash
current_os=$(get_simple_os)

if is_command_compatible "$GLOBAL_CONFIG_FILE" "setup" "asdf" "$current_os"; then
    echo "Comando compatível"
fi
```

### `requires_sudo()`

Verifica se comando requer sudo.

```bash
if requires_sudo "$GLOBAL_CONFIG_FILE" "setup" "asdf"; then
    log_warning "Este comando requer sudo"
fi
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/internal/yaml.sh"
source "$LIB_DIR/os.sh"

# Configuração
GLOBAL_CONFIG_FILE="$CORE_DIR/cli.yaml"

# Obtém info global
cli_name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
cli_version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")

echo "$cli_name v$cli_version"

# Lista categorias e comandos
categories=$(discover_categories)
current_os=$(get_simple_os)

for category in $categories; do
    cat_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$category" "description")
    echo "Categoria: $cat_desc"

    commands=$(get_category_commands "$category")
    for cmd in $commands; do
        if is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
            cmd_name=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "name")
            echo "  - $cmd_name"
        fi
    done
done
```

## Funções - Variáveis de Ambiente

### `load_env_files()`

> **✨ Novo na versão 1.0+**

Carrega e exporta variáveis de ambiente de arquivos .env.

**Parâmetros:**

- `$1` - Diretório base para resolver caminhos relativos
- `$@` - Lista de caminhos de arquivos .env (relativos ou absolutos)

**Comportamento:**

- Carrega variáveis de múltiplos arquivos .env na ordem especificada
- Suporta caminhos relativos (resolvidos a partir do base_dir) e absolutos
- Ignora arquivos inexistentes silenciosamente
- Suporta comentários (`#`) e linhas vazias
- Suporta aspas simples e duplas
- Expande variáveis como `$HOME`, `$USER`, etc.
- Respeita variáveis já definidas (não sobrescreve sistema ou config)

**Formato do arquivo .env:**

```bash
# Comentários são suportados
DATABASE_URL="postgresql://localhost/mydb"
API_KEY="your-key"

# Expansão de variáveis
CONFIG_DIR="$HOME/.config/app"

# Aspas simples ou duplas
APP_NAME="My Application"
VERSION='1.0.0'
```

**Uso:**

```bash
# Carregar múltiplos arquivos .env
load_env_files "$config_dir" ".env" ".env.local"

# Com caminhos absolutos
load_env_files "/" "/etc/myapp/.env" "$HOME/.env"
```

### `load_command_envs()`

Carrega e exporta variáveis de ambiente de arquivos .env e da seção `envs` do config.yaml de um comando.

**Parâmetros:**

- `$1` - Caminho do arquivo config.yaml do comando

**Comportamento:**

1. Carrega arquivos .env (se especificados em `env_files:`)
2. Carrega seção `envs:` do config.yaml
3. Exporta cada variável como variável de ambiente
4. Expande variáveis como `$HOME`, `$USER`, etc.
5. Respeita variáveis já definidas (não sobrescreve sistema)
6. Chamado automaticamente pelo framework antes de executar o comando

**Funciona em:**

- ✅ Comandos built-in (em `commands/`)
- ✅ Comandos de plugins (em `plugins/`)
- ✅ Subcategorias e comandos aninhados

**Uso:**

```bash
# Carregamento automático (framework faz isso)
load_command_envs "$CONFIG_FILE"

# No script do comando, as variáveis já estão disponíveis
local timeout="${MY_TIMEOUT:-30}"
local url="${MY_API_URL:-https://default.com}"
```

**Exemplo de config.yaml (com .env files):**

```yaml
name: "My Command"
description: "Meu comando"
entrypoint: "main.sh"
sudo: false
os: ["linux"]

# Arquivos .env (opcional)
env_files:
  - ".env"              # Configurações base
  - ".env.local"        # Configurações locais

# Variáveis diretas (maior prioridade que .env)
envs:
  MY_API_URL: "https://api.example.com"
  MY_TIMEOUT: "30"
  MY_INSTALL_DIR: "$HOME/.myapp"
  MY_MAX_RETRIES: "3"
```

**Exemplo de arquivo .env:**

```bash
# .env
DATABASE_URL="postgresql://localhost/mydb"
REDIS_URL="redis://localhost:6379"
DEBUG_MODE="false"
```

**Exemplo de uso no script:**

```bash
#!/bin/bash
set -euo pipefail


# Variáveis do config.yaml já estão exportadas
install_app() {
    local api_url="${MY_API_URL:-https://api.example.com}"
    local timeout="${MY_TIMEOUT:-30}"
    local install_dir="${MY_INSTALL_DIR:-$HOME/.myapp}"

    log_info "Instalando em: $install_dir"
    curl --max-time "$timeout" "$api_url/download" -o /tmp/app.tar.gz
    tar -xzf /tmp/app.tar.gz -C "$install_dir"
}

install_app "$@"
```

**Características:**

- ✅ Expansão automática de variáveis (`$HOME` → `/home/user`)
- ✅ Isolamento entre comandos (não vazam)
- ✅ Respeita ordem de precedência (Sistema > Config envs > Global > .env)
- ✅ Suporta qualquer variável de ambiente válida
- ✅ Funciona em comandos built-in e plugins
- ✅ Suporta múltiplos arquivos .env
- ✅ Caminhos relativos ao diretório do config.yaml
- ✅ Arquivos .env inexistentes são ignorados silenciosamente

**Ordem de Precedência (maior → menor):**

1. **Variáveis de Sistema** (maior prioridade)
   - `export VAR=value` ou `VAR=value comando`
2. **Variáveis do Config** - `config.yaml` → `envs:`
3. **Variáveis Globais** - `config/settings.conf`
4. **Arquivos .env** (menor prioridade entre fontes configuráveis)
   - Na ordem especificada em `env_files:`
   - Último arquivo tem prioridade sobre anteriores
5. **Valores Padrão** (mais baixa)
   - `${VAR:-default}` no script

**Exemplo de precedência completa:**

```yaml
# config.yaml
env_files:
  - ".env"
  - ".env.local"
envs:
  TIMEOUT: "60"
```

```bash
# .env
TIMEOUT="40"
API_URL="https://api.example.com"

# .env.local
DATABASE_URL="postgresql://localhost/mydb"

# config/settings.conf
TIMEOUT="30"

# Script
timeout="${TIMEOUT:-10}"
api_url="${API_URL:-https://default.com}"

# Resultados:
./core/susa comando                  # → TIMEOUT=60 (do config.yaml envs)
                                     # → API_URL=https://api.example.com (do .env)
TIMEOUT=90 ./core/susa comando       # → TIMEOUT=90 (do sistema - maior prioridade)
```

**Notas:**

- Não é necessário chamar manualmente; o framework faz isso automaticamente
- Use sempre valores de fallback no script: `${VAR:-default}`
- Variáveis são isoladas; cada comando tem seu próprio ambiente
- Override via sistema sempre tem prioridade

> **📖 Para mais detalhes**, veja [Guia de Variáveis de Ambiente](../../guides/envs.md).

## Boas Práticas

1. Sempre defina `GLOBAL_CONFIG_FILE` e `CLI_DIR` no início
2. Use `is_command_compatible()` antes de executar comandos
3. Cache resultados de funções pesadas em loops
