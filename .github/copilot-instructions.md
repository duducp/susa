# Copilot Instructions - SUSA CLI

Este documento contém diretrizes e conhecimento sobre o projeto SUSA CLI para auxiliar o GitHub Copilot.

## 📋 Índice

1. [Quick Reference](#-quick-reference) - Comandos e padrões mais usados
2. [Arquitetura do Projeto](#️-arquitetura-do-projeto) - Estrutura de diretórios
3. [Sistema de Categorias, Comandos e Plugins](#-sistema-de-categorias-comandos-e-plugins)
4. [Sistema de Contexto de Comandos](#-sistema-de-contexto-de-comandos)
5. [Sistema de Logs e Verbosidade](#-sistema-de-logs-e-verbosidade)
6. [Sistema de Cache](#-sistema-de-cache)
7. [Bibliotecas Core](#-bibliotecas-core---guia-de-uso)
8. [Padrões de Código](#-padrões-de-código)
9. [Fluxo de Dados](#-fluxo-de-dados)
10. [Padrões de Performance](#-padrões-de-performance)
11. [Testing Guidelines](#-testing-guidelines)
12. [Documentação de Comandos](#-documentação-de-comandos)
13. [Learning Resources](#-learning-resources)

---

## 🎯 Quick Reference

### Comandos Mais Usados

```bash
# Cache - SEMPRE use para múltiplas consultas
cache_load
is_installed_cached "podman-desktop"
get_installed_version_cached "podman-desktop"

# Registry - NUNCA use jq diretamente
registry_plugin_exists "$file" "nome"
registry_get_plugin_info "$file" "nome" "version"

# Instalações - Preferir funções cached
register_or_update_software_in_lock "podman-desktop" "1.0.0"
get_installed_from_cache

# Contexto - Acesso automático à estrutura do comando
context_get "command.category"    # Categoria do comando
context_get "command.full"        # Comando completo
context_get "command.args"        # Lista de argumentos

# Logs - Sistema global de verbosidade
log_info "Mensagem informativa"
log_debug "Debug (apenas com -v)"
log_debug2 "Debug detalhado (apenas com -vv)"
log_trace "Trace de execução (apenas com -vvv)"
log_success "✓ Operação concluída"
log_error "✗ Erro crítico"
```

### Flags Globais

O SUSA processa automaticamente as seguintes flags **antes** de executar qualquer comando:

```bash
# Verbosidade (níveis progressivos)
susa -v [comando]          # Nível 1: Debug básico (DEBUG=1, VERBOSE_LEVEL=1)
susa -vv [comando]         # Nível 2: Debug detalhado (VERBOSE_LEVEL=2)
susa -vvv [comando]        # Nível 3: Trace completo (VERBOSE_LEVEL=3, TRACE=1)

# Alternativas longas
susa --verbose [comando]   # Igual a -v
susa --verbose=2 [comando] # Igual a -vv
susa --verbose=3 [comando] # Igual a -vvv

# Modo silencioso (prioridade sobre -v)
susa -q [comando]          # Modo quiet (SILENT=1, desativa DEBUG/TRACE)
susa --quiet [comando]     # Igual a -q

# Agrupamento
susa --group [comando]     # Ativa agrupamento (SUSA_GROUP=1)

# Flags podem ser combinadas
susa -v --group setup --list
susa -vv setup docker      # Debug detalhado
```

**⚠️ Importante sobre Flags Globais:**

1. **--quiet tem prioridade absoluta:**
   - Silencia **todos** os logs (incluindo debug, trace)
   - Útil para scripts/automação
   - Exemplo: `susa -v --quiet setup` → modo quiet (sem logs)

2. **Níveis de verbosidade:**
   - Nível 0 (padrão): Apenas info, success, warning, error
   - Nível 1 (-v): + `log_debug()`
   - Nível 2 (-vv): + `log_debug2()`
   - Nível 3 (-vvv): + `log_trace()`

3. **Não mapeie em comandos individuais:**
   ```bash
   # ❌ ERRADO - Não faça isso nos comandos
   case "$1" in
       -v|--verbose) export DEBUG=1; shift ;;  # Já é feito globalmente
       -q|--quiet) export SILENT=1; shift ;;   # Já é feito globalmente
   esac

   # ✅ CORRETO - As flags já estão processadas
   # Apenas use as funções de log normalmente
   log_debug "Isso só aparece com -v ou superior"
   log_debug2 "Isso só aparece com -vv ou superior"
   log_trace "Isso só aparece com -vvv"
   ```

### Ordem de Source de Bibliotecas

> **🎉 Carregamento Automático:** As bibliotecas essenciais (`color.sh`, `logger.sh`, `cache.sh`, `lock.sh`, `context.sh`, `config.sh`, `gum.sh`) são carregadas automaticamente no início da execução de cada comando pelo `core/susa`. **Você não precisa fazer `source` delas nos seus comandos!**

**Bibliotecas carregadas automaticamente:**
- `color.sh` - Cores e formatação
- `logger.sh` - Sistema de logs
- `os.sh` - Detecção de sistema
- `cache.sh` - Cache genérico nomeado
- `lock.sh` - Cache do susa.lock
- `context.sh` - Contexto de execução
- `config.sh` - Parser de configurações
- `cli.sh` - Funções do CLI
- `gum.sh` - Interface gráfica de terminal (spinners, prompts)

**Bibliotecas que você precisa carregar manualmente (quando necessário):**
```bash
source "$LIB_DIR/internal/installations.sh"  # Se gerenciar instalações
source "$LIB_DIR/internal/registry.sh"       # Se trabalhar com plugins
source "$LIB_DIR/github.sh"                  # Se baixar do GitHub
source "$LIB_DIR/string.sh"                  # Se manipular strings
source "$LIB_DIR/sudo.sh"                    # Se precisar de sudo
source "$LIB_DIR/shell.sh"                   # Se trabalhar com shells
```

### Padrões Críticos

| ✅ Fazer | ❌ Evitar |
|----------|-----------|
| `cache_load` antes de loop | `jq` direto no lock file |
| `is_installed_cached()` | `is_installed()` em loop |
| `registry_get_plugin_info()` | `jq` direto no registry |
| `cache_refresh()` após sync | Cache stale após modificações |
| `log_debug()` para debug | `echo` para debug |
| Usar flags globais `-v/-vv/-vvv/-q` | Mapear essas flags em cada comando |
| `log_info()` para mensagens | `echo` direto |

---

## 🏗️ Arquitetura do Projeto

### Estrutura de Diretórios

```
susa/
├── core/
│   ├── susa                    # Executável principal
│   ├── cli.json                # Metadados do CLI
│   └── lib/                    # Bibliotecas compartilhadas
│       ├── *.sh                # Bibliotecas públicas (color, logger, github, etc)
│       └── internal/           # Bibliotecas internas (cache, registry, installations)
├── commands/
│   ├── self/                   # Comandos de gerenciamento do CLI
│   ├── setup/                  # Comandos de instalação de software
│   └── [categoria]/            # Outras categorias de comandos
├── plugins/                    # Plugins instalados
│   └── registry.json           # Registro de plugins
├── config/
│   └── settings.conf           # Configurações globais
└── docs/                       # Documentação
```

## 🔧 Sistema de Categorias, Comandos e Plugins

### Categorias

Categorias organizam comandos em grupos lógicos. Cada categoria tem um arquivo `category.json`:

**Estrutura do category.json:**
```json
{
  "name": "Setup",
  "description": "Instalação e atualização de softwares e ferramentas",
  "entrypoint": "main.sh"  // Opcional - script executado pela categoria
}
```

**Tipos de categorias:**
1. **Top-level:** Diretamente em `commands/` (ex: `setup`, `self`)
2. **Subcategorias:** Aninhadas (ex: `self/plugin`, `self/cache`)

**Entrypoint (opcional):**
- Se categoria tem `entrypoint`, executa `main.sh` ao invés de listar comandos
- Exemplo: `susa setup --list` executa `commands/setup/main.sh --list`
- Script pode implementar `show_complement_help()` para adicionar info na listagem

### Comandos

Comandos são scripts executáveis dentro de categorias. Cada comando tem:
- **Diretório:** `commands/[categoria]/[comando]/`
- **Arquivo de config:** `command.json`
- **Script principal:** `main.sh`

**Estrutura do command.json:**
```json
{
  "name": "Docker",
  "description": "Instala Docker CLI e Engine (plataforma de containers)",
  "entrypoint": "main.sh",
  "sudo": ["linux", "mac"],  // Sistemas que requerem sudo (array vazio [] = não requer)
  "group": "container",      // Agrupa comandos relacionados
  "os": ["linux", "mac"],    // Sistemas operacionais compatíveis
  "envs": {                  // Variáveis de ambiente específicas
    "DOCKER_DOWNLOAD_BASE_URL": "https://download.docker.com"
  }
}
```

**Campos importantes:**
- `name`: Nome exibido no help
- `description`: Descrição do comando
- `entrypoint`: Script a executar (sempre `main.sh`)
- `sudo`: Array de sistemas que requerem privilégios root (["linux", "mac"], ["linux"], ou [] para nenhum)
- `group`: Agrupa comandos na listagem (ex: "container", "runtime")
- `os`: Array com sistemas suportados (`linux`, `mac`, `windows`)
- `envs`: Variáveis de ambiente injetadas antes da execução

**Indicadores na listagem:**
- `✓` - Software já instalado (categoria setup)
- `[sudo]` - Requer privilégios de administrador
- `[plugin]` - Comando vem de plugin instalado
- `[dev]` - Plugin em modo desenvolvimento

**Descoberta de comandos:**
1. CLI lê `susa.lock` (gerado por `susa self lock`)
2. Busca em `commands/[categoria]/[comando]/command.json`
3. Busca em plugins instalados
4. Valida compatibilidade de OS

### Plugins

Plugins estendem o CLI com novos comandos e categorias. Há dois tipos:

#### 1. Plugins Remotos (GitHub)

**Instalação:**
```bash
susa self plugin add https://github.com/usuario/meu-plugin
```

**Localização:** `plugins/meu-plugin/`

**Processo:**
1. Clone do repositório
2. Validação do `plugin.json`
3. Registro em `plugins/registry.json`
4. Regeneração do `susa.lock`

#### 2. Plugins de Desenvolvimento (Local)

**Instalação:**
```bash
susa self plugin add /caminho/local/meu-plugin --dev
```

**Características:**
- Marcado com `"dev": true` no registry
- Usa caminho local no campo `source`
- Permite desenvolvimento iterativo sem commit
- Indicador `[dev]` na listagem de comandos

**Estrutura do plugin.json:**
```json
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Descrição do plugin",
  "directory": "commands"  // Opcional - onde ficam as categorias
}
```

**Campos:**
- `name`: Identificador único do plugin (obrigatório)
- `version`: Versão semântica (obrigatório)
- `description`: Descrição curta (opcional)
- `directory`: Subdiretório com categorias (opcional, padrão: raiz do plugin)

**Estrutura de arquivos:**
```
meu-plugin/
├── plugin.json
└── commands/              # Se directory="commands"
    └── dev/               # Nova categoria
        ├── category.json
        └── test/          # Novo comando
            ├── command.json
            └── main.sh
```

**Registry (plugins/registry.json):**
```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "remote-plugin",
      "source": "https://github.com/user/plugin",
      "version": "1.0.0",
      "installedAt": "2026-01-16T10:00:00Z",
      "dev": false
    },
    {
      "name": "dev-plugin",
      "source": "/home/user/projects/dev-plugin",
      "version": "0.1.0",
      "installedAt": "2026-01-16T11:00:00Z",
      "dev": true
    }
  ]
}
```

### Fluxo de Execução

**1. Descoberta de comandos:**
```
susa [categoria] [comando] [args]
  ↓
1. Validar categoria existe
2. Buscar comando em commands/categoria/comando/
3. Buscar comando em plugins/*/commands/categoria/comando/
4. Buscar comando em dev plugins (via registry.json)
5. Validar OS compatível
6. Carregar command.json
  ↓
Executar main.sh com argumentos
```

**2. Geração do lock file:**
```
susa self lock
  ↓
1. Escanear commands/*/category.json
2. Escanear commands/*/*/command.json
3. Escanear plugins/*/plugin.json
4. Escanear plugins/*/commands/ (se directory definido)
5. Escanear dev plugins do registry
6. Gerar JSON consolidado em susa.lock
7. Atualizar cache
```

**3. Listagem com cache:**
```
susa setup
  ↓
1. cache_load (carrega susa.lock em memória)
2. cache_query '.categories[] | select(.name == "Setup")'
3. cache_get_category_commands "setup"
4. Filtrar por OS atual
5. Agrupar por 'group' field
6. Adicionar indicadores (✓, [sudo], [plugin], [dev])
7. Exibir formatado
```

### Bibliotecas de Suporte

**config.sh** - Leitura de metadados
```bash
get_category_info "$lock_file" "setup" "description"
get_command_info "$lock_file" "setup" "docker" "description"
is_command_compatible "$lock_file" "setup" "docker" "linux"
get_category_commands "setup" "linux"
requires_sudo "$lock_file" "setup" "docker"
```

**plugin.sh** - Gerenciamento de plugins
```bash
validate_plugin_config "/path/to/plugin"
read_plugin_config "/path/to/plugin"  # Retorna: name|version|description|directory
detect_plugin_version "/path/to/plugin"
get_plugin_name "/path/to/plugin"
```

**cli.sh** - Helpers para comandos
```bash
build_command_path        # Ex: "self plugin add"
get_command_config_file   # Retorna caminho do command.json
show_usage "[options]"    # Exibe: "susa self plugin add [options]"
show_description          # Lê description do command.json
```

## 🎯 Sistema de Contexto de Comandos

### Como Funciona

O SUSA captura automaticamente toda a estrutura do comando sendo executado e disponibiliza via contexto:

1. **Inicialização:** Automática pelo `executor.sh` antes de executar qualquer comando
2. **Armazenamento:** Cache em memória usando sistema de cache nomeado
3. **Acesso:** Funções especializadas para cada campo
4. **Limpeza:** Automática ao final da execução

### Campos Capturados

Quando você executa `susa setup podman-desktop install --force`, o contexto contém:

```bash
type: "command"                # Tipo: "command" ou "category"
category: "setup"              # Categoria raiz
full_category: "setup"         # Categoria completa (com subcategorias)
parent: ""                     # Categoria pai (se subcategoria)
current: "podman-desktop"      # Comando ou última parte da categoria
action: "install"              # Primeira ação (não-flag, separado de args)
full: "susa setup podman-desktop install --force"  # Comando completo
path: "/path/to/commands/setup/podman-desktop"     # Caminho absoluto
args: ["--force"]              # Argumentos (após a action)
args_count: 1                  # Número de argumentos
```

### Funções de Contexto (Já Carregadas Automaticamente)

```bash
# Obter informações do comando usando context_get()
context_get "command.type"          # Tipo (command ou category)
context_get "command.category"      # Categoria do comando
context_get "command.current"       # Nome do comando ou categoria
context_get "command.action"        # Primeira ação
context_get "command.full"          # Comando completo
context_get "command.path"          # Caminho do comando
context_get "command.args_count"    # Número de argumentos

# Obter argumentos
context_get "command.args"          # Todos (um por linha)
context_get "command.arg.0"         # Argumento por índice
context_get "command.arg.1"         # Segundo argumento

# Funções genéricas de contexto
context_set "key" "value"           # Definir valor
context_get "key"                   # Obter valor
context_has "key"                   # Verificar existência
context_remove "key"                # Remover valor
context_get_all                     # Obter tudo como JSON
```

### Exemplos de Uso

```zsh
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

main() {
    # Detectar modo de execução pela ação
    local action=$(context_get "command.action")
    case "$action" in
        install) do_install ;;
        update)  do_update ;;
        *)       show_help ;;
    esac

    # Log com contexto
    local full_command=$(context_get "command.full")
    log_info "Executando: $full_command"

    # Processar argumentos
    local args_count=$(context_get "command.args_count")
    for ((i=0; i<args_count; i++)); do
        local arg=$(context_get "command.arg.$i")
        process_arg "$arg"
    done
}

main "$@"
```

### Testar Contexto

```bash
# Verificar valores do contexto em seu comando
context_get "command.full"
context_get_all  # Ver todo o contexto como JSON
```

## � Sistema de Logs e Verbosidade

### Como Funciona

O SUSA implementa um sistema unificado de logs com níveis progressivos de verbosidade, processados **globalmente** antes da execução de comandos.

### Níveis de Verbosidade

| Nível | Flag | Variáveis | Funções Ativas |
|-------|------|-----------|----------------|
| 0 (padrão) | - | - | `log_info`, `log_success`, `log_warning`, `log_error` |
| 1 | `-v`, `--verbose` | `DEBUG=1`, `VERBOSE_LEVEL=1` | + `log_debug()` |
| 2 | `-vv`, `--verbose=2` | `DEBUG=1`, `VERBOSE_LEVEL=2` | + `log_debug2()` |
| 3 | `-vvv`, `--verbose=3` | `DEBUG=1`, `TRACE=1`, `VERBOSE_LEVEL=3` | + `log_trace()` |
| Silencioso | `-q`, `--quiet` | `SILENT=1` | Nenhum (todos suprimidos) |

### Funções de Log Disponíveis

```bash
# Logs básicos (sempre visíveis, exceto com --quiet)
log_info "Iniciando instalação..."
log_success "✓ Docker instalado com sucesso"
log_warning "⚠ Versão desatualizada detectada"
log_error "✗ Falha ao baixar arquivo"
log_output "Texto formatado sem timestamp"  # Para output customizado

# Logs de debug (requerem -v ou superior)
log_debug "Detectando sistema operacional..."  # Visível com -v
log_debug2 "URL de download: https://..."      # Visível com -vv
log_trace "Chamando função detect_os_arch()"  # Visível com -vvv

# Funções auxiliares para lógica condicional
if is_debug_enabled; then
    # Operação cara que só executa em modo debug
    generate_detailed_report
fi

if is_trace_enabled; then
    # Trace ultra-detalhado (profiling, etc)
    profile_function_calls
fi
```

### Boas Práticas de Log

```bash
# ✅ CORRETO - Usar funções de log apropriadas
install_podman_desktop() {
    log_info "Instalando Podman Desktop..."
    log_debug "Plataforma: $platform"
    log_debug2 "Checksum: $checksum"
    log_trace "Entrando em download_and_verify()"

    if download_file "$url"; then
        log_success "Podman Desktop instalado com sucesso"
    else
        log_error "Falha ao baixar Podman Desktop"
        return 1
    fi
}

# ❌ ERRADO - Não use echo direto
install_podman_desktop() {
    echo "Instalando Podman Desktop..."  # Não respeita --quiet
    echo "DEBUG: platform=$platform"  # Sempre visível
}

# ❌ ERRADO - Não mapeie flags globais em comandos
main() {
    case "$1" in
        -v|--verbose) export DEBUG=1; shift ;;  # Desnecessário
        -q|--quiet) export SILENT=1; shift ;;   # Desnecessário
    esac
}

# ✅ CORRETO - Flags já estão processadas
main() {
    # Apenas use as funções de log normalmente
    log_debug "Debug automático se -v foi passado"
}
```

### Exemplos de Uso por Nível

**Nível 0 (padrão):**
```bash
susa setup podman-desktop
# Output:
# [INFO] 2026-01-19 10:00:00 - Instalando Podman Desktop...
# [SUCCESS] 2026-01-19 10:00:05 - Podman Desktop 1.0.0 instalado com sucesso
```

**Nível 1 (-v):**
```bash
susa -v setup podman-desktop
# Output anterior +
# [DEBUG] Detectando sistema operacional: Linux
# [DEBUG] Plataforma: linux-x86_64
# [DEBUG] Versão mais recente: 1.0.0
```

**Nível 2 (-vv):**
```bash
susa -vv setup podman-desktop
# Output anterior +
# [DEBUG2] URL de download: https://github.com/containers/podman-desktop/releases/...
# [DEBUG2] Checksum verificado: OK
# [DEBUG2] Pacote instalado com sucesso
```

**Nível 3 (-vvv):**
```bash
susa -vvv setup podman-desktop
# Output anterior +
# [TRACE] Chamando detect_os_arch()
# [TRACE] Executando: curl -fsSL https://...
# [TRACE] Cache hit: version=1.0.0
```

**Modo silencioso (-q):**
```bash
susa -q setup podman-desktop
# Sem output (útil para automação)
exit_code=$?
```

### Comportamento de --quiet

- **Prioridade absoluta:** `--quiet` desativa todos os logs, independente da posição
- **Ignora -v:** `susa -v --quiet` ou `susa --quiet -v` → modo silencioso
- **Uso recomendado:** Scripts de automação, cronjobs, pipelines CI/CD

```bash
# Em scripts
if susa -q setup docker; then
    echo "Instalação concluída"  # Seu próprio output
else
    echo "Falha na instalação"
    exit 1
fi
```

### Testar Verbosidade

```bash
# Testar diferentes níveis no seu comando
susa -v setup uv --info      # Debug básico
susa -vv setup uv --info     # Debug detalhado
susa -vvv setup uv --info    # Trace completo
susa -q setup uv --info      # Silencioso
```

## �🚀 Sistema de Cache

### Como Funciona

O SUSA implementa um sistema de cache em memória para otimizar leituras do arquivo `susa.lock`:

1. **Localização:** `${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/lock.cache`
2. **Invalidação:** Automática quando `susa.lock` é modificado
3. **Carregamento:** Lazy loading na primeira consulta
4. **Formato:** JSON minificado em memória

### Bibliotecas e Cache

#### ✅ SEMPRE usar cache para:
- Listar comandos disponíveis
- Verificar existência de plugins
- Consultar metadados de categorias
- **Consultas múltiplas em loop**

#### ❌ NUNCA usar cache para:
- Escrever no lock file
- Dados após `sync_installations()` (usar `cache_refresh()`)
- Modificações em registry.json

### Funções de Cache

> **⚠️ Importante:** Funções de acesso ao lock file (`cache_load`, `cache_query`, `cache_get_*`) foram movidas para `lock.sh`.

#### Core (core/lib/cache.sh)

```bash
# Sistema genérico de cache nomeado
cache_named_load "mydata"
cache_named_set "mydata" "key" "value"
cache_named_get "mydata" "key"
cache_named_query "mydata" '.field'
cache_named_clear "mydata"
```

#### Lock File (core/lib/internal/lock.sh)

```bash
# Carregar cache do lock file
cache_load

# Consultar dados do cache
cache_query '.installations[].name'

# Funções especializadas
cache_get_categories
cache_get_plugins
cache_get_category_commands "setup"

# Atualizar cache após modificações
cache_refresh

# Limpar cache
cache_clear
```

**Para usar funções do lock:**
```bash
source "$LIB_DIR/internal/lock.sh"  # Já carrega cache.sh automaticamente
cache_load
```

## 📚 Bibliotecas Core - Guia de Uso

### internal/installations.sh

**Funções Otimizadas (Preferir):**
```bash
# ✅ Usa cache - rápido para múltiplas consultas
cache_load
is_installed_cached "podman-desktop"
get_installed_version_cached "podman-desktop"
get_installed_from_cache  # Lista todos instalados

# ✅ Para escrita no lock
register_or_update_software_in_lock "podman-desktop" "1.0.0"
remove_software_in_lock "podman-desktop"
```

**Funções Legadas (Usar quando necessário):**
```bash
# ⚠️ Lê do disco a cada chamada - mais lento
is_installed "podman-desktop"              # Para casos isolados
get_installed_version "podman-desktop"     # Para casos isolados
```

**Quando usar cada uma:**
- **Uma verificação:** Use função sem cache
- **Loop ou múltiplas verificações:** Use `cache_load` + funções cached
- **Após sync:** Use `cache_refresh()` antes de consultar

### internal/registry.sh

**Funções Disponíveis:**
```bash
# Verificações
registry_plugin_exists "$file" "plugin-name"
registry_is_dev_plugin "$file" "plugin-name"

# Consultas
registry_get_plugin_info "$file" "plugin-name" "version"
registry_get_plugin_by_source "$file" "/path/to/plugin"
registry_count_plugins "$file"
registry_get_all_plugin_names "$file"

# Modificações
registry_add_plugin "$file" "name" "source" "version" "false"
registry_remove_plugin "$file" "name"
```

**❌ NUNCA faça:**
```bash
# Ruim - acesso direto ao registry
jq -r '.plugins[] | select(.name == "x")' "$registry_file"

# ✅ Bom - use funções da biblioteca
registry_get_plugin_info "$registry_file" "x" "version"
```

### github.sh

**Funções Disponíveis:**
```bash
# Obter versões
github_get_latest_version "owner/repo"
github_get_version_from_raw "owner/repo" "main" "version.json" "version"
github_get_latest_version_with_fallback "owner/repo" "main" "cli.json" "version"

# Downloads
github_download_release "$url" "$output" "description"
github_verify_checksum "$file" "$checksum" "sha256"

# Detecção de sistema
github_detect_os_arch "standard"  # Returns "linux:x64"
```

## 🎨 Padrões de Código

### Nomenclatura

```bash
# Funções públicas (sem underscore)
is_installed()
get_latest_version()
cache_load()

# Funções internas (com underscore)
_cache_init()
_query_installation_field()
_mark_installed_software_in_lock()

# Funções com cache (sufixo _cached)
is_installed_cached()
get_installed_version_cached()
```

### Estrutura de Comandos

```zsh
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# ✨ Bibliotecas essenciais já estão carregadas automaticamente!
# Carregue apenas as bibliotecas específicas que você precisa:
source "$LIB_DIR/internal/installations.sh"  # Se usar instalações
source "$LIB_DIR/github.sh"                  # Se usar GitHub

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    # ... resto da ajuda
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help) show_help; exit 0 ;;
            -v | --verbose) export DEBUG=1; shift ;;
            *) log_error "Opção inválida: $1"; exit 1 ;;
        esac
    done

    # Lógica principal aqui
}

# Execute main
main "$@"
```

### Tratamento de Erros

```bash
# ✅ Bom - verificar antes de usar
if [ ! -f "$file" ]; then
    log_error "Arquivo não encontrado: $file"
    return 1
fi

# ✅ Bom - usar set -e e || para tratamento
command_that_might_fail || {
    log_error "Falha ao executar comando"
    return 1
}

# ❌ Ruim - não verificar erros
result=$(command_that_might_fail)
```

### Logs e Output

```bash
# Debug (apenas se DEBUG=1)
log_debug "Informação de debug"

# Informacional
log_info "Processando..."

# Sucesso
log_success "✓ Operação concluída!"

# Warning
log_warning "⚠ Atenção!"

# Erro
log_error "✗ Erro crítico"

# Output sem timestamp
log_output "Resultado: valor"
```

## 🔄 Fluxo de Dados

### Lock File (susa.lock)

**Estrutura:**
```json
{
  "version": "1.0.0",
  "generatedAt": "2026-01-16T...",
  "categories": [...],
  "commands": [...],
  "plugins": [...],
  "installations": [
    {
      "name": "docker",
      "installed": true,
      "version": "24.0.5",
      "installedAt": "2026-01-14T..."
    }
  ]
}
```

**Modificação:**
1. Sempre use funções de `installations.sh` ou `lock.sh`
2. Após modificar, considere atualizar o cache
3. Nunca edite manualmente em produção

### Registry (plugins/registry.json)

**Estrutura:**
```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "my-plugin",
      "source": "https://github.com/...",
      "version": "1.0.0",
      "installedAt": "2026-01-14T...",
      "dev": false
    }
  ]
}
```

**Modificação:**
1. Use funções de `registry.sh`
2. Para dev plugins, marque `dev: true` e use caminho local em `source`

## 🔍 Dependency Chain

```
cli.sh
  ↓
installations.sh → cache.sh, json.sh
  ↓
registry.sh (standalone)
  ↓
plugin.sh → git.sh
  ↓
lock.sh → cache.sh, json.sh
  ↓
config.sh → registry.sh, json.sh, cache.sh, plugin.sh, lock.sh
```

**Ordem de carregamento segura:**
1. logger.sh, color.sh (sem dependências)
2. json.sh (sem dependências)
3. cache.sh (sem dependências)
4. git.sh (sem dependências)
5. registry.sh (sem dependências)
6. plugin.sh (depende de git.sh)
7. lock.sh (depende de json.sh, cache.sh)
8. installations.sh (depende de json.sh, cache.sh)
9. config.sh (depende de registry, json, cache, plugin, lock)

## 🎯 Padrões de Performance

### Anti-patterns (Evitar)

```bash
# ❌ Ruim - loop com leituras repetidas
for software in docker podman poetry; do
    if is_installed "$software"; then
        version=$(get_installed_version "$software")
        echo "$software: $version"
    fi
done

# ❌ Ruim - chamadas jq diretas
jq -r '.installations[].name' "$lock_file"

# ❌ Ruim - não usar cache disponível
local count=$(jq '.plugins | length' "$registry_file")
```

### Best Practices (Seguir)

```bash
# ✅ Bom - carregar cache uma vez
cache_load
for software in docker podman poetry; do
    if is_installed_cached "$software"; then
        version=$(get_installed_version_cached "$software")
        echo "$software: $version"
    fi
done

# ✅ Bom - usar funções de biblioteca
local installations=$(get_installed_from_cache)

# ✅ Bom - usar funções especializadas
local count=$(registry_count_plugins "$registry_file")
```

## 🧪 Testing Guidelines

### Manual Testing

```bash
# Testar com debug
DEBUG=1 susa setup podman-desktop --info

# Testar cache
susa self cache list

# Verificar lock
jq . ~/.susa/susa.lock

# Testar performance
time susa setup --list
```

### Common Issues

1. **Cache desatualizado:** Execute `cache_refresh()` após modificar lock
2. **Funções não encontradas:** Verifique se biblioteca foi carregada com `source`
3. **Permission denied:** Verifique permissões de `~/.susa` e `/tmp/susa-$USER`
4. **jq not found:** Instale jq (`apt install jq` ou `brew install jq`)

## 📝 Commit Messages

Siga o padrão Conventional Commits:

```
feat(setup): add postgres installation command
fix(cache): refresh cache after sync_installations
perf(installations): add cached versions of query functions
docs(readme): update installation instructions
refactor(registry): use helper functions instead of direct jq
```

## 🔐 Security Notes

- Nunca commitar credenciais ou tokens
- Validar entrada de usuário antes de usar em comandos
- Usar `chmod 700` para diretórios de cache
- Sanitizar caminhos com `readlink -f` antes de usar

## 📝 Documentação de Comandos

### Estrutura de Documentação

Cada comando deve ter documentação no diretório `docs/reference/commands/[categoria]/[comando].md`:

**Localização:**
```
docs/
└── reference/
    └── commands/
        ├── .pages           # Lista categorias
        ├── index.md         # Overview de comandos
        ├── setup/
        │   ├── .pages       # Lista comandos da categoria
        │   ├── index.md     # Overview da categoria
        │   └── docker.md    # Documentação do comando
        └── self/
            ├── .pages
            ├── index.md
            └── info.md
```

### Padrão de Documentação

**Princípio:** Seja **direto ao ponto**. O usuário deve entender exatamente como funciona com pouco texto.

**Estrutura recomendada:**

```markdown
# [Nome do Comando]

[Uma linha descrevendo o que faz - máximo 80 caracteres]

## O que faz?

[2-3 parágrafos concisos explicando a funcionalidade]

## Como usar

\```bash
susa [categoria] [comando] [opções]
\```

## Opções

| Opção | Descrição |
|-------|-----------|
| `-h, --help` | Mostra ajuda |
| `--flag` | Descrição breve |

## Exemplos

\```bash
# Exemplo 1 - caso mais comum
susa categoria comando

# Exemplo 2 - com opções
susa categoria comando --flag
\```

## Veja também

- [Comando relacionado](../outro-comando.md)
```

**Características importantes:**
- ✅ **Títulos curtos e diretos**
- ✅ **Exemplos práticos** (sempre inclua o caso de uso mais comum)
- ✅ **Tabelas para opções** (mais fácil de escanear)
- ✅ **Links para comandos relacionados**
- ❌ **Evite parágrafos longos** (máximo 3-4 linhas)
- ❌ **Não repita informações** que já estão no help do comando

### Registrando no .pages

Após criar a documentação, adicione ao arquivo `.pages` da categoria:

**Exemplo: `docs/reference/commands/setup/.pages`**
```yaml
title: Setup
nav:
  - Visão Geral: index.md
  - Docker: docker.md       # Adicione aqui
  - Podman: podman.md
  - Poetry: poetry.md
```

### Vinculando no index.md

Se for um comando importante, adicione referência no `docs/index.md`:

```markdown
## 📚 Documentação

- [Referência de Comandos](reference/commands/index.md)
  - [Setup](reference/commands/setup/index.md) - Instalação de software
  - [Self](reference/commands/self/index.md) - Gerenciamento do CLI
```

### Exemplos de Boas Documentações

- **Concisa:** [`docs/reference/commands/self/info.md`](docs/reference/commands/self/info.md) - 50 linhas, tudo que precisa
- **Completa mas direta:** [`docs/reference/commands/setup/docker.md`](docs/reference/commands/setup/docker.md) - Cobre tudo, mas em seções escaneáveis

### Checklist de Documentação

Ao criar documentação de um novo comando:

- [ ] Criar arquivo `.md` em `docs/reference/commands/[categoria]/`
- [ ] Título e descrição de uma linha
- [ ] Seção "O que faz?" (2-3 parágrafos máximo)
- [ ] Seção "Como usar" com sintaxe básica
- [ ] Tabela de opções (se houver)
- [ ] Seção "Exemplos" com casos práticos
- [ ] Links para comandos relacionados
- [ ] Adicionar ao `.pages` da categoria
- [ ] (Opcional) Vincular no `index.md` se for comando importante

## 🎓 Learning Resources

- **Documentação:** `docs/` directory
- **Exemplos:** `commands/setup/podman-desktop/main.sh` (bem documentado)
- **Testes:** Execute comandos com `--help` para ver opções
- **Cache:** Execute `susa self cache list --detailed` para entender o estado

---

**Última atualização:** 2026-01-18
**Versão do documento:** 1.0.0
