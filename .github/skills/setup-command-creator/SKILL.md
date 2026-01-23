---
name: Setup Command Architect
description: Especialista em criar comandos para setup de ferramentas e softwares
model: claude-sonnet-4.5
---

# Arquitetura de comandos de Setup

## 🎯 Escopo

Esta skill é **específica para comandos de setup** na categoria `setup/`. Para outras categorias (como `self`, comandos utilitários, etc), consulte a documentação geral em `.github/copilot-instructions.md`.

## 📋 Protocolo de Análise e Correção

**Quando solicitado a verificar conformidade de um comando:**

1. **Sempre mostrar resumo da análise** com:
   - ✅ Conformidades (o que está correto)
   - ⚠️ Não-conformidades e melhorias necessárias

2. **Se houver melhorias:**
   - Listar claramente cada correção necessária
   - **PERGUNTAR ao usuário** se deseja que as correções sejam aplicadas
   - **NÃO aplicar** correções automaticamente sem confirmação

3. **Após confirmação:**
   - Aplicar todas as correções em batch (quando possível)
   - Executar comandos de finalização: `make format` → `make lint` → `susa self lock`

## ⚡ Quick Reference

**Criar novo comando de setup:**

1. Estrutura: `commands/setup/[nome]/` com `category.json`, `main.sh`, `utils/common.sh`, subcomandos `install/`, `update/`, `uninstall/`
2. Funções obrigatórias em `common.sh`: `check_installation()`, `get_current_version()`, `get_latest_version()`
3. Todo entrypoint deve ter: `[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"`
4. Categoria principal deve ter: flag `--info` chamando `show_software_info()`
5. Preferir bibliotecas: Homebrew → Flatpak → Snap → GitHub → apt/dnf (nessa ordem)
6. **Finalizar:** `make format` → `make lint` → `susa self lock` (nessa ordem!)

**Ver exemplo completo:** `commands/setup/bruno/` (Desktop App) ou `commands/setup/lazypg/` (CLI Tool)

**Bibliotecas essenciais:**

- `installations.sh` - Lock file, show_software_info
- `homebrew.sh` / `flatpak.sh` / `snap.sh` - Gerenciadores
- `github.sh` - Download releases
- `os.sh` - Detecção de sistema

**Índice de Funções Mais Usadas:**

| Biblioteca | Função | Quando usar |
|------------|--------|-------------|
| `installations.sh` | `show_software_info()` | Exibir status de instalação |
| `installations.sh` | `register_or_update_software_in_lock()` | Após instalar/atualizar |
| `installations.sh` | `remove_software_in_lock()` | Após desinstalar |
| `homebrew.sh` | `homebrew_install()` | Instalar no macOS |
| `homebrew.sh` | `homebrew_is_installed()` | Verificar instalação macOS |
| `flatpak.sh` | `flatpak_install()` | Instalar desktop app Linux |
| `flatpak.sh` | `flatpak_is_installed()` | Verificar instalação Flatpak |
| `snap.sh` | `snap_install()` | Instalar via Snap (requer sudo) |
| `github.sh` | `github_get_latest_version()` | Obter versão mais recente |
| `github.sh` | `github_download_release()` | Baixar release do GitHub |
| `os.sh` | `is_mac()` / `is_linux()` | Detectar sistema operacional |
| `os.sh` | `get_distro_id()` | Obter distro Linux |

---

## 📑 Índice

### 🎯 Fundamentos

1. [Visão Geral](#-visão-geral)
2. [Estrutura de Arquivos](#-estrutura-de-arquivos)
3. [Metadados Obrigatórios](#-metadados-obrigatórios)

### 📋 Regras Obrigatórias

1. [Funções Obrigatórias vs Opcionais](#-funções-obrigatórias-vs-opcionais)
2. [Padrões Obrigatórios em Entrypoints](#️-padrões-obrigatórios-em-entrypoints)

### 🎯 Boas Práticas

1. [Boas Práticas de Implementação](#-boas-práticas-de-implementação)
2. [Anti-patterns (Evitar)](#-anti-patterns-evitar)

### 📚 Referências

1. [Bibliotecas Disponíveis](#-bibliotecas-disponíveis)
2. [Templates de Código](#-templates-de-código)
3. [Exemplos Completos](#-exemplos-completos)
4. [Checklist de Desenvolvimento](#-checklist-de-desenvolvimento)

---

## 🎯 Visão Geral

O SUSA CLI organiza comandos em **categorias** e **subcategorias**, com suporte a **plugins externos**. Comandos de **setup** seguem um padrão específico:

- **Estrutura obrigatória:** `install`, `update`, `uninstall` como subcomandos
- **Funções compartilhadas:** Definidas em `utils/common.sh`
- **Integração com lock file:** Rastreamento de instalações via `susa.lock`
- **Suporte multiplataforma:** macOS (Homebrew) e Linux (Flatpak/apt/dnf)

Cada comando é modular, testável e segue padrões estritos de estrutura de arquivos.

## 📁 Estrutura de Arquivos

### Comando com Subcategorias (padrão recomendado)

```text
commands/
└── setup/
    ├── category.json               # Metadados da categoria setup
    ├── main.sh                     # Script de orchestração/help do setup
    └── [categoria]/                # Categoria do comando de setup
        ├── category.json           # Metadados da categoria pai
        ├── main.sh                 # Script de orchestração/help
        ├── install/
        │   ├── command.json        # Metadados do subcomando
        │   └── main.sh             # Script de instalação
        ├── update/
        │   ├── command.json
        │   └── main.sh
        ├── uninstall/
        │   ├── command.json
        │   └── main.sh
        └── utils/
            └── common.sh          # Funções compartilhadas
```

**Exemplo Real:** `commands/setup/bruno/`

## 📝 Metadados Obrigatórios

### category.json

Sempre que for uma categoria ou subcategorias, o arquivo `category.json` é obrigatório.

```json
{
  "name": "Nome da Categoria",
  "description": "Descrição curta da categoria",
  "entrypoint": "main.sh"
}
```

### command.json

Sempre que for um comando, o arquivo `command.json` é obrigatório.

```json
{
  "name": "Nome do Comando",
  "description": "Descrição curta do comando",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"],            // Opcional: SO compatíveis (veja quando usar abaixo)
  "sudo": true,                      // Opcional: Requer sudo (veja quando usar abaixo)
  "group": "container"               // Opcional: Agrupa na listagem
}
```

**⚠️ Quando usar `os: [...]`:**

Use o campo `os` no `command.json` dos **subcomandos** para especificar compatibilidade de sistema operacional:

**Software disponível apenas para macOS:**
```json
{
  "name": "Install",
  "description": "Instala o software",
  "entrypoint": "main.sh",
  "os": ["mac"]
}
```

**Software disponível apenas para Linux:**
```json
{
  "name": "Install",
  "description": "Instala o software",
  "entrypoint": "main.sh",
  "os": ["linux"]
}
```

**Software disponível para ambos (macOS e Linux):**
```json
{
  "name": "Install",
  "description": "Instala o software",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"]
}
```

**Quando omitir `os`:**
- Se o software está disponível para **ambos** os sistemas operacionais
- O CLI assume compatibilidade universal quando `os` não está presente

**Exemplos práticos:**

```json
// ✅ CORRETO - iterm2 apenas para macOS
// commands/setup/iterm/install/command.json
{
  "name": "Install",
  "description": "Instala o iTerm2",
  "entrypoint": "main.sh",
  "os": ["mac"]
}

// ✅ CORRETO - Flatpak apenas para Linux
// commands/setup/some-app/install/command.json
{
  "name": "Install",
  "description": "Instala o app via Flatpak",
  "entrypoint": "main.sh",
  "os": ["linux"]
}

// ✅ CORRETO - Disponível para ambos
// commands/setup/bruno/install/command.json
{
  "name": "Install",
  "description": "Instala o Bruno",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"]
}
```

**⚠️ Quando usar `sudo: true`:**

Marque `sudo: true` no `command.json` dos **subcomandos** quando:

- Usar **Snap** para instalação (requer `sudo snap install`)
- Usar **gerenciadores nativos** Linux: apt, dnf, pacman (requerem sudo)
- Copiar arquivos para `/usr/local/bin`, `/opt`, `/etc` ou outros diretórios do sistema
- Modificar permissões ou ownership de arquivos do sistema

**Não use `sudo: true` quando:**

- Usar **Homebrew** (macOS) - gerenciado pelo usuário
- Usar **Flatpak** (Linux) - instalação por usuário (sem sudo)
- Instalar em `~/.local/bin` ou outros diretórios do usuário
- Baixar releases do GitHub para diretórios do usuário

**Exemplos:**

```json
// ✅ CORRETO - Snap requer sudo
// commands/setup/software/install/command.json
{
  "name": "Install",
  "description": "Instala o software",
  "entrypoint": "main.sh",
  "sudo": true
}

// ✅ CORRETO - apt/dnf requer sudo
// commands/setup/postgres/install/command.json
{
  "name": "Install",
  "description": "Instala PostgreSQL Client",
  "entrypoint": "main.sh",
  "sudo": true
}

// ❌ NÃO NECESSÁRIO - Flatpak não requer sudo
// commands/setup/bruno/install/command.json
{
  "name": "Install",
  "description": "Instala o Bruno",
  "entrypoint": "main.sh"
  // sudo: false ou omitir
}
```

## ⚙️ Padrões Obrigatórios em Entrypoints

### 🔒 Verificação SUSA_SHOW_HELP (OBRIGATÓRIO)

**Todos os entrypoints** (categoria principal e subcomandos) **DEVEM** ter esta verificação ao final do arquivo:

```bash
# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Por que é obrigatório?**

Quando o usuário executa `--help`, o sistema precisa:

1. Processar o `command.json` ou `category.json` para obter metadados
2. Chamar `show_complement_help()` se existir
3. **NÃO executar** a função `main()` (que contém a lógica do comando)

**Sem essa verificação:**

```bash
# ❌ ERRADO - main() executa sempre
main() {
    # Lógica de instalação/atualização/etc
}
main "$@"  # Executa até no --help!
```

**Problemas que isso causa:**

- O `--help` tenta executar lógica do comando
- Pode falhar se argumentos obrigatórios não forem passados
- Pode executar operações destrutivas inadvertidamente

**Com a verificação correta:**

```bash
# ✅ CORRETO - main() não executa durante --help
main() {
    # Lógica segura
}
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Quando `SUSA_SHOW_HELP=1`:**

- Sistema processa metadados
- Chama `show_complement_help()` se existir
- Monta e exibe o help formatado
- **Pula completamente a execução de `main()`**

### 📋 Flag --info (OBRIGATÓRIO na categoria principal)

**Todo comando de setup** deve implementar a flag `--info` no entrypoint da **categoria principal**:

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info  # Função da biblioteca installations.sh
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup [comando] --help${NC} para ver opções"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Por que `--info` é obrigatório?**

**Por que implementar `--info`:**

- Permite consultar status sem executar instalação
- Interface padrão em todos os comandos de setup
- Essencial para automação e scripts

**Uso:**

```bash
# Exibe: estado, versão atual, versão disponível
susa setup bruno --info
```

> **📖 Detalhes:** `show_software_info()` é uma função da biblioteca `installations.sh` que usa automaticamente as [três funções obrigatórias](#-funções-obrigatórias-em-utilscommonsh) de `common.sh`. Não reimplemente esta função. Veja mais detalhes em [Funções que NÃO devem estar em common.sh](#-funções-que-não-devem-estar-em-commonsh).

**Localização da flag `--info`:**

| Local | Obrigatório? | Motivo |
|-------|--------------|--------|
| Categoria principal (`main.sh`) | ✅ Sim | Ponto de entrada principal para consultas |
| Subcomandos (install/update/etc) | ❌ Não | Já disponível na categoria principal |

**Exemplo completo:**

```bash
#!/bin/bash
# commands/setup/bruno/main.sh

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# OPCIONAL - Informações extras no help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
}

# OBRIGATÓRIO - Parse de argumentos com --info
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info  # Função da lib
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                exit 1
                ;;
        esac
    done

    display_help
}

# OBRIGATÓRIO - Verificação SUSA_SHOW_HELP
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

## 🔧 Estrutura dos Scripts

### main.sh (Categoria Pai com Subcategorias)

**Características:**

- Mostra help/informações quando executado sem subcomando
- Implementa `show_complement_help()` para info adicional na listagem
- Não executa ações de instalação/desinstalação diretamente

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries (as essenciais já estão carregadas)
source "$LIB_DIR/internal/installations.sh"  # Se gerenciar instalações
source "$LIB_DIR/os.sh"                      # Se detectar SO
source "$LIB_DIR/flatpak.sh"                 # Se usar Flatpak (Linux)
source "$LIB_DIR/homebrew.sh"                # Se usar Homebrew (macOS)
source "$UTILS_DIR/common.sh"                # Funções compartilhadas

# OPCIONAL - Show additional info in category listing
show_complement_help() {
    # Se houver opções adicionais (como --info), mostrar PRIMEIRO
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Descrição detalhada do software (1-2 linhas)"
    log_output "  Informações relevantes sobre sua funcionalidade"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Recurso 1"
    log_output "  • Recurso 2"
    log_output "  • Recurso 3"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup [comando] --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

> **📖 Nota:** `show_software_info` e `display_help` são funções das bibliotecas (veja [Funções que NÃO devem estar em common.sh](#-funções-que-não-devem-estar-em-commonsh))

### main.sh (Subcomando - install)

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"      # Se usar Flatpak (Linux)
source "$LIB_DIR/homebrew.sh"     # Se usar Homebrew (macOS)
source "$LIB_DIR/github.sh"       # Se baixar releases do GitHub
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Descrição detalhada do software (2-3 linhas)"
    log_output "  Explicação sobre sua funcionalidade e propósito"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup [comando] install              # Instala o software"
    log_output "  susa setup [comando] install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}[comando-para-executar]${NC}"
    log_output "  Ou abra pelo menu de aplicações"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Recurso 1"
    log_output "  • Recurso 2"
    log_output "  • Recurso 3"
}

# Install on macOS
install_macos() {
    if ! homebrew_is_installed "$HOMEBREW_PACKAGE"; then
        homebrew_install "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
    else
        log_warning "$SOFTWARE_NAME já está instalado via Homebrew"
    fi
    return 0
}

# Install on Linux
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$SOFTWARE_NAME"
    return $?
}

# Main function
main() {
    if check_installation; then
        log_info "$SOFTWARE_NAME $(get_current_version) já está instalado."
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa setup [comando] update${NC} para atualizar"
        return 0
    fi

    log_info "Iniciando instalação do $SOFTWARE_NAME..."

    if is_mac; then
        install_macos
    else
        install_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "[nome-software]" "$installed_version"

            log_success "$SOFTWARE_NAME $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  Execute: ${LIGHT_CYAN}[comando-para-executar]${NC}"
        else
            log_error "$SOFTWARE_NAME foi instalado mas não está acessível"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**⚠️ Importante:**

- `show_complement_help()` é opcional mas recomendada para comandos install
- Substitua `[nome-software]` pelo nome do software no lock (ex: "bruno", "vscode")
- Use `SOFTWARE_NAME`, `HOMEBREW_PACKAGE`, `FLATPAK_APP_ID` definidos em `common.sh`

### main.sh (Subcomando - update)

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando $SOFTWARE_NAME..."

    if ! check_installation; then
        log_error "$SOFTWARE_NAME não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup [comando] install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        if homebrew_is_installed "$HOMEBREW_PACKAGE"; then
            homebrew_update "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
        else
            log_error "$SOFTWARE_NAME não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_update "$FLATPAK_APP_ID" "$SOFTWARE_NAME"
        else
            log_error "$SOFTWARE_NAME não está instalado via Flatpak"
            return 1
        fi
    fi

    local new_version=$(get_current_version)
    register_or_update_software_in_lock "[nome-software]" "$new_version"

    if [ "$current_version" = "$new_version" ]; then
        log_info "$SOFTWARE_NAME já estava na versão mais recente ($current_version)"
    else
        log_success "$SOFTWARE_NAME atualizado com sucesso para versão $new_version!"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

### main.sh (Subcomando - uninstall)

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    local skip_confirm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    log_info "Desinstalando $SOFTWARE_NAME..."

    if ! check_installation; then
        log_info "$SOFTWARE_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$skip_confirm" = "false" ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o $SOFTWARE_NAME $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        if homebrew_is_installed "$HOMEBREW_PACKAGE"; then
            homebrew_uninstall "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
        else
            log_warning "$SOFTWARE_NAME não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_uninstall "$FLATPAK_APP_ID" "$SOFTWARE_NAME"
        else
            log_warning "$SOFTWARE_NAME não está instalado via Flatpak"
            return 1
        fi
    fi

    if ! check_installation; then
        remove_software_in_lock "[nome-software]"
        log_success "$SOFTWARE_NAME desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar $SOFTWARE_NAME completamente"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

### utils/common.sh (Funções Compartilhadas)

```bash
#!/bin/bash
# [Software] Common Utilities
# Shared functions used across install, update and uninstall

# Constants
SOFTWARE_NAME="Nome do Software"
HOMEBREW_PACKAGE="package-name"      # Para macOS (cask ou formula)
FLATPAK_APP_ID="com.example.App"    # Para Linux

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$HOMEBREW_PACKAGE"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$HOMEBREW_PACKAGE"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if software is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_PACKAGE"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}
```

> **⚠️ Importante:** Não reimplemente `show_software_info` ou `display_help` - elas vêm das bibliotecas. Veja [Funções que NÃO devem estar em common.sh](#-funções-que-não-devem-estar-em-commonsh).

**Padrões por tipo de software:**

| Tipo de Software | macOS | Linux |
|------------------|-------|-------|
| Desktop Apps | Homebrew Cask | Flatpak |
| CLI Tools | Homebrew Formula | GitHub Releases |
| System Services | Homebrew Formula | apt/dnf/pacman |

**Exemplos de constantes:**

```bash
# Desktop Application (Bruno)
SOFTWARE_NAME="Bruno"
HOMEBREW_PACKAGE="bruno"          # Cask
FLATPAK_APP_ID="com.usebruno.Bruno"

# CLI Tool (LazyPG)
SOFTWARE_NAME="lazypg"
HOMEBREW_PACKAGE="lazypg"         # Formula
# Linux: usar GitHub Releases diretamente

# System Package (PostgreSQL)
SOFTWARE_NAME="PostgreSQL Client"
HOMEBREW_PACKAGE="libpq"          # Formula
# Linux: usar apt/dnf/pacman
```

## � Funções Obrigatórias vs Opcionais

### ✅ Funções Obrigatórias em utils/common.sh

Todo comando de setup **DEVE** implementar estas três funções em `utils/common.sh`:

```bash
# 1. Verificar se o software está instalado
check_installation() {
    # OBRIGATÓRIO
    # Retorna 0 (sucesso) se instalado, 1 (falha) se não instalado
    # Usado por: install, update, uninstall
}

# 2. Obter versão atual instalada
get_current_version() {
    # OBRIGATÓRIO
    # Retorna a versão instalada ou "desconhecida" se não instalado
    # Usado por: install, update, --info
}

# 3. Obter versão mais recente disponível
get_latest_version() {
    # OBRIGATÓRIO
    # Retorna a versão mais recente disponível para instalação
    # Usado por: install, update, --info
}
```

**Por que são obrigatórias?**

- `check_installation()` - Evita reinstalações e valida sucesso da instalação
- `get_current_version()` - Registra versão no lock file e exibe em `--info`
- `get_latest_version()` - Permite verificar se há atualizações disponíveis

### 🔧 Funções Opcionais em utils/common.sh

Você pode adicionar funções auxiliares conforme necessário:

```bash
# Funções específicas do software
get_config_path()      # Caminho de configuração
backup_config()        # Backup de configurações
detect_install_method() # Para softwares com múltiplos métodos
```

### ❌ Funções que NÃO devem estar em common.sh

Estas funções já existem nas bibliotecas internas:

```bash
# ❌ NÃO CRIAR - já existe em installations.sh
show_software_info()   # Exibe info da instalação

# ❌ NÃO CRIAR - já existe em display.sh
display_help()         # Exibe lista de subcomandos
show_usage()           # Exibe sintaxe do comando
show_description()     # Exibe descrição do command.json
```

## 🎨 Customizando a Exibição de Help

### show_complement_help() - Informações Extras (Opcional)

Adiciona informações complementares ao help padrão **sem substituí-lo**.

**Onde implementar:**

- No `main.sh` da categoria principal (aparece na listagem de comandos)
- No `main.sh` dos subcomandos (aparece no help do subcomando)

**Quando usar:**

- Para adicionar descrição detalhada do software
- Para mostrar exemplos de uso
- Para listar recursos principais
- Para instruções de pós-instalação

**Estrutura recomendada:**

1. **"Opções adicionais"** - PRIMEIRA seção (quando houver flags como --info)
2. **"O que é"** - Descrição do software
3. **"Recursos principais"** - Lista de features
4. **"Exemplos"** / **"Pós-instalação"** - Apenas em subcomandos (install/update)

**⚠️ Nota:** Se o comando não tiver opções adicionais (como --info), omita a seção "Opções adicionais" e comece direto com "O que é".

**Exemplo - main.sh da categoria principal:**

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# OPCIONAL - Adiciona informações extras na listagem
show_complement_help() {
    # Se houver opções adicionais (como --info), mostrar PRIMEIRO
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Cliente REST API open-source (alternativa ao Postman)"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Interface intuitiva para testar APIs"
    log_output "  • Suporte a GraphQL, WebSocket e gRPC"
    log_output "  • Versionamento de coleções com Git"
}

main() {
    case "$1" in
        --info) show_software_info; exit 0 ;;
    esac
    display_help
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Exemplo - main.sh do subcomando install:**

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# OPCIONAL - Adiciona informações extras no help do install
show_complement_help() {
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup bruno install              # Instala o Bruno"
    log_output "  susa setup bruno install -v           # Instalação verbosa"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}bruno${NC}"
    log_output "  Ou abra pelo menu de aplicações"
}

main() {
    # ... lógica de instalação
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Output com show_complement_help():**

```text
$ susa setup bruno --help

Bruno - Cliente REST API open-source

USO:
  susa setup bruno [comando]

COMANDOS:
  install    Instala o Bruno
  update     Atualiza o Bruno
  uninstall  Remove o Bruno

O que é:
  Cliente REST API open-source (alternativa ao Postman)

Recursos principais:
  • Interface intuitiva para testar APIs
  • Suporte a GraphQL, WebSocket e gRPC
  • Versionamento de coleções com Git

Opções adicionais:
  --info          Mostra informações da instalação
```

### show_help() - Help Completamente Customizado (Raro)

Substitui **completamente** o help padrão. Use apenas quando o padrão não atende.

**Quando usar:**

- Comando com estrutura muito diferente do padrão
- Necessidade de help totalmente customizado
- **Raramente necessário** - preferir `show_complement_help()`

**Exemplo:**

```bash
#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
source "$UTILS_DIR/common.sh"

# Substitui COMPLETAMENTE o help padrão
show_help() {
    log_output "${BOLD}${BLUE}Bruno${NC} - Cliente REST API"
    log_output ""
    log_output "${BOLD}USO BÁSICO:${NC}"
    log_output "  susa setup bruno install     # Instalar"
    log_output "  susa setup bruno update      # Atualizar"
    log_output "  susa setup bruno uninstall   # Remover"
    log_output ""
    log_output "${BOLD}OPÇÕES:${NC}"
    log_output "  --info     Informações da instalação"
    log_output "  -h, --help Mostra esta mensagem"
    log_output ""
    log_output "Documentação: https://docs.usebruno.com"
}

main() {
    case "$1" in
        --info) show_software_info; exit 0 ;;
    esac

    # Não chama display_help - usa show_help customizado
    show_help
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**⚠️ Importante sobre show_help():**

- Se `show_help()` existir, o sistema **não chama** `display_help()` automaticamente
- Você é responsável por exibir todas as informações necessárias
- **Preferir `show_complement_help()`** que complementa ao invés de substituir

**Diferenças resumidas:**

| Função | Tipo | Quando usar | Substitui help padrão? |
|--------|------|-------------|------------------------|
| `show_complement_help()` | Opcional | Adicionar informações extras | ❌ Não (complementa) |
| `show_help()` | Raro | Help totalmente customizado | ✅ Sim (substitui) |

## 🎯 Boas Práticas de Implementação

### ✅ SEMPRE Usar Bibliotecas Oficiais do SUSA

**Regra de Ouro:** Se existe uma biblioteca do SUSA para a funcionalidade que você precisa, **USE-A**. Não reimplemente.

#### Preferência por Gerenciadores de Pacotes

**Ordem de preferência para instalações:**

1. **Homebrew (macOS)** - Se o software está disponível no Homebrew, SEMPRE use a lib (❌ sem sudo)
2. **Flatpak (Linux - Desktop Apps)** - Para aplicações gráficas no Linux, SEMPRE use a lib (❌ sem sudo)
3. **Snap (Linux - Alternativa)** - Se Flatpak não disponível, SEMPRE use a lib (✅ **requer sudo**)
4. **GitHub Releases** - Para CLI tools, use a lib de download (⚠️ sudo apenas se instalar em `/usr/local/bin`)
5. **Gerenciadores Nativos** - apt/dnf/pacman (✅ **requer sudo**)

**Resumo de sudo por gerenciador:**

| Gerenciador | Requer sudo? | Motivo |
|-------------|--------------|--------|
| Homebrew | ❌ Não | Gerenciado pelo usuário |
| Flatpak | ❌ Não | Instalação por usuário |
| Snap | ✅ **Sim** | Modifica sistema |
| apt/dnf/pacman | ✅ **Sim** | Modificam sistema |
| GitHub → `~/.local/bin` | ❌ Não | Diretório do usuário |
| GitHub → `/usr/local/bin` | ✅ **Sim** | Diretório do sistema |

**Por que essa ordem?**

- ✅ **Consistência:** Libs do SUSA garantem comportamento uniforme
- ✅ **Manutenibilidade:** Atualizações nas libs beneficiam todos
- ✅ **Logging/Error handling:** Já integrados
- ✅ **Cross-platform:** Funciona consistentemente

**❌ NÃO FAÇA:**

```bash
# ERRADO - Reimplementar lógica
install_app() {
    flatpak install -y flathub "$1"
    echo "Instalado"
}
```

**✅ FAÇA:**

```bash
# CORRETO - Usar biblioteca oficial
source "$LIB_DIR/flatpak.sh"
flatpak_install "com.example.App" "App Name"
```

### ♻️ Reutilizar Código - Evite Duplicação

Se perceber código duplicado:

1. Verifique se já existe biblioteca
2. Se reutilizável, crie uma lib
3. Se específico, mantenha em `utils/common.sh`

**Padrão consistente = fácil manutenção**

## 📚 Bibliotecas Disponíveis

### ✨ Carregadas Automaticamente

Essas bibliotecas são carregadas automaticamente pelo core antes de executar qualquer comando:

- `color.sh` - Cores e formatação (`$RED`, `$GREEN`, `$YELLOW`, `$BLUE`, `$CYAN`, `$NC`)
- `logger.sh` - Sistema de logs (`log_info`, `log_debug`, `log_success`, `log_error`)
- `os.sh` - Detecção de sistema (`is_mac`, `is_linux`, `get_distro_id`)
- `cache.sh` - Cache genérico nomeado
- `lock.sh` - Cache do susa.lock
- `context.sh` - Contexto de execução (`context_get`, `context_set`)
- `config.sh` - Parser de configurações
- `cli.sh` - Funções do CLI
- `display.sh` - Funções de exibição (`display_help`)

### 🔧 Carregar Manualmente (quando necessário)

**⚠️ Importante:** Sempre verifique se a biblioteca que você precisa já existe antes de implementar manualmente!

```bash
# Gerenciamento de Instalações
source "$LIB_DIR/internal/installations.sh"  # Rastreamento no lock file, show_software_info

# Gerenciadores de Pacotes (PREFERIR SEMPRE QUE DISPONÍVEL)
source "$LIB_DIR/homebrew.sh"                # Homebrew (macOS) - Desktop apps e CLI tools
source "$LIB_DIR/flatpak.sh"                 # Flatpak (Linux) - Desktop apps
source "$LIB_DIR/snap.sh"                    # Snap (Linux) - Alternativa ao Flatpak

# Downloads e Releases
source "$LIB_DIR/github.sh"                  # Download de releases do GitHub

# Utilidades
source "$LIB_DIR/string.sh"                  # Manipulação de strings (trim, lowercase, etc)
source "$LIB_DIR/table.sh"                   # Formatação de tabelas
source "$LIB_DIR/sudo.sh"                    # Execução com sudo (prompt amigável)
```

**Quando usar cada uma:**

| Biblioteca | Usar quando... |
|------------|----------------|
| `homebrew.sh` | Software disponível no Homebrew (macOS) |
| `flatpak.sh` | Desktop app disponível no Flathub (Linux) |
| `snap.sh` | Desktop app não disponível no Flatpak (Linux) |
| `github.sh` | CLI tool distribuído via GitHub Releases |
| `installations.sh` | Registrar/consultar instalações no lock |
| `string.sh` | Manipular strings (trim, uppercase, lowercase) |
| `table.sh` | Exibir dados tabulares formatados |
| `sudo.sh` | Executar comandos com privilégios de admin |

### 📖 Referência Rápida de Funções

#### installations.sh

```bash
# Verificar instalação (usa cache para performance)
is_installed_cached "software-name"
get_installed_version_cached "software-name"
get_installed_from_cache  # Lista todos instalados

# Registrar no lock file
register_or_update_software_in_lock "software-name" "version"
remove_software_in_lock "software-name"

# Exibir informações (obtém automaticamente do contexto)
show_software_info                           # Usa contexto
show_software_info "software" "binary-name"  # Especifica manualmente
```

#### os.sh

```bash
# Detecção de sistema
is_mac              # true se macOS
is_linux            # true se Linux
get_distro_id       # ubuntu, debian, fedora, arch, etc
get_distro_version  # Versão da distribuição
```

#### flatpak.sh

```bash
# Gerenciamento Flatpak (Linux) - PREFERIR para Desktop Apps
flatpak_install "com.example.App" "App Name"
flatpak_update "com.example.App" "App Name"
flatpak_uninstall "com.example.App" "App Name"
flatpak_is_installed "com.example.App"
flatpak_get_installed_version "com.example.App"
flatpak_get_latest_version "com.example.App"
```

#### snap.sh

```bash
# Gerenciamento Snap (Linux) - Alternativa ao Flatpak
snap_install "package-name" "App Name"
snap_update "package-name" "App Name"
snap_uninstall "package-name" "App Name"
snap_is_installed "package-name"
snap_get_installed_version "package-name"
```

#### homebrew.sh

```bash
# Gerenciamento Homebrew (macOS)
homebrew_is_available                            # Verifica se Homebrew está instalado
homebrew_install "package-name" "Display Name"
homebrew_update "package-name" "Display Name"
homebrew_uninstall "package-name" "Display Name"
homebrew_is_installed "package-name"
homebrew_get_installed_version "package-name"
homebrew_get_latest_version "package-name"       # Para casks
homebrew_get_latest_version_formula "formula"    # Para formulas
```

#### github.sh

```bash
# Download de releases do GitHub
github_get_latest_version "owner/repo"
github_get_latest_version "owner/repo" "true"  # Remove 'v' prefix
github_download_release "$url" "$output" "Description"
github_verify_checksum "$file" "$checksum" "sha256"

# Detecção automática de sistema
github_detect_os_arch "standard"  # Retorna "linux:x64", "darwin:arm64", etc
```

#### context.sh

```bash
# Obter informações do comando atual
context_get "command.type"          # "command" ou "category"
context_get "command.category"      # Categoria do comando
context_get "command.current"       # Nome do comando
context_get "command.action"        # Primeira ação (ex: "install")
context_get "command.full"          # Comando completo
context_get "command.args_count"    # Número de argumentos
context_get "command.arg.0"         # Argumento por índice
```

#### string.sh

```bash
# Manipulação de strings
string_trim "  text  "              # Remove espaços das pontas
string_lowercase "TEXT"             # Converte para minúsculas
string_uppercase "text"             # Converte para maiúsculas
string_contains "haystack" "needle" # Verifica se contém substring
string_starts_with "text" "prefix" # Verifica se começa com
string_ends_with "text" "suffix"   # Verifica se termina com
```

#### table.sh

```bash
# Formatação de tabelas
table_print "Header1|Header2|Header3" "row1col1|row1col2|row1col3" "row2col1|row2col2|row2col3"
# Exibe tabela formatada com bordas e alinhamento automático
```

#### cache.sh e lock.sh

```bash
# Sistema de cache (já carregado automaticamente)
cache_load                          # Carrega susa.lock em memória
cache_query '.installations[].name' # Consulta com jq
cache_refresh                       # Atualiza cache após modificações

# Cache nomeado (para dados customizados)
cache_named_load "mydata"
cache_named_set "mydata" "key" "value"
cache_named_get "mydata" "key"
```

## 🎨 Sistema de Logs

```bash
# Básicos (sempre visíveis, exceto com --quiet)
log_info "Mensagem informativa"
log_success "✓ Operação concluída"
log_warning "⚠ Atenção"
log_error "✗ Erro crítico"
log_output "Texto sem timestamp"

# Debug (requerem -v/-vv/-vvv)
log_debug "Debug básico (visível com -v)"
log_debug2 "Debug detalhado (visível com -vv)"
log_trace "Trace completo (visível com -vvv)"
```

## ✅ Checklist de Criação de Comando

### Para Comando com Subcategorias (Recomendado)

- [ ] Criar diretório `commands/setup/[comando]/`
- [ ] Criar `category.json` com metadados da categoria
- [ ] Criar `main.sh` da categoria principal com:
  - [ ] Implementar `--info` chamando `show_software_info()`
  - [ ] Opcional: `show_complement_help()` para info adicional
  - [ ] **Obrigatório:** `[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"` ao final
- [ ] Criar diretório `utils/` com `common.sh`
- [ ] Definir constantes em `common.sh` (SOFTWARE_NAME, HOMEBREW_PACKAGE, etc)
- [ ] Implementar **funções obrigatórias** em `common.sh`:
  - [ ] `check_installation()` - Verifica se está instalado
  - [ ] `get_current_version()` - Obtém versão instalada
  - [ ] `get_latest_version()` - Obtém versão mais recente
- [ ] **NÃO criar** `show_software_info()` em `common.sh` (já existe na lib)
- [ ] **NÃO criar** `display_help()` em `common.sh` (já existe na lib)
- [ ] Criar subcomando `install/` com:
  - [ ] `command.json` (metadados)
  - [ ] `main.sh` (lógica de instalação)
  - [ ] Opcional: `show_complement_help()` para info detalhada
  - [ ] **Obrigatório:** `[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"` ao final
- [ ] Criar subcomando `update/` com:
  - [ ] `command.json` (metadados)
  - [ ] `main.sh` (lógica de atualização)
  - [ ] **Obrigatório:** `[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"` ao final
- [ ] Criar subcomando `uninstall/` com:
  - [ ] `command.json` (metadados)
  - [ ] `main.sh` (lógica de desinstalação com confirmação)
  - [ ] **Obrigatório:** `[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"` ao final
- [ ] Usar `register_or_update_software_in_lock()` após instalação/atualização
- [ ] Usar `remove_software_in_lock()` após desinstalação
- [ ] **Adicionar campo `os` em command.json dos subcomandos:**
  - [ ] `"os": ["mac"]` - Se software disponível **apenas para macOS**
  - [ ] `"os": ["linux"]` - Se software disponível **apenas para Linux**
  - [ ] `"os": ["linux", "mac"]` - Se software disponível para **ambos**
  - [ ] Omitir `os` - Se compatível universalmente (mesma lógica em ambos)
- [ ] **Adicionar campo `sudo: true` em command.json dos subcomandos** se:
  - [ ] Usar Snap (requer `sudo snap install`)
  - [ ] Usar apt/dnf/pacman (requerem sudo)
  - [ ] Instalar em `/usr/local/bin`, `/opt`, `/etc` (diretórios do sistema)
  - [ ] Não usar se: Homebrew, Flatpak, ou instalação em `~/.local/bin`
- [ ] Testar instalação: `susa setup [comando] install`
- [ ] Testar atualização: `susa setup [comando] update`
- [ ] Testar desinstalação: `susa setup [comando] uninstall`
- [ ] Testar help: `susa setup [comando] --help`
- [ ] Testar info: `susa setup [comando] --info`

### Comandos de Finalização (OBRIGATÓRIOS)

⚠️ **Execute estes comandos APENAS após finalizar toda a lógica do comando.**

Após criar ou modificar qualquer comando, **SEMPRE** execute estes comandos na ordem:

```bash
# 1. Formatar código automaticamente (shfmt, prettier)
make format

# 2. Validar sintaxe bash e padrões de código (shellcheck)
make lint

# 3. Regenerar o lock file (atualiza índice de comandos)
susa self lock
```

**Por que são obrigatórios:**

1. **`make format`** - Formata código para manter consistência de estilo (shfmt, prettier). Deve ser executado **primeiro** para normalizar o código.
2. **`make lint`** - Valida sintaxe bash, detecta erros comuns, verifica conformidade com padrões (shellcheck). Executar **após** formatação garante validação do código já normalizado.
3. **`susa self lock`** - Atualiza o `susa.lock` com os novos comandos/categorias. Executar **por último** após código validado e formatado.

**Ordem importa:**
- `make format` primeiro (normaliza código)
- `make lint` segundo (valida código formatado)
  - **Se falhar:** Corrija os erros reportados e execute novamente até passar
- `susa self lock` por último (índice do código validado)

**Se o lint falhar:**
1. Leia os erros reportados pelo shellcheck
2. Corrija cada erro no código
3. Execute `make lint` novamente
4. Repita até todos os erros serem corrigidos
5. Só então execute `susa self lock`

### Validações Finais (OBRIGATÓRIAS)

Após executar os comandos de finalização, **valide** se tudo está funcionando:

```bash
# 1. Verificar se comando aparece na listagem
susa setup

# 2. Testar flag --info (comando básico de validação)
susa setup [comando] --info

# 3. Verificar help da categoria principal
susa setup [comando] --help

# 4. Verificar help de cada subcomando
susa setup [comando] install --help
susa setup [comando] update --help
susa setup [comando] uninstall --help
```

**Checklist de Validação Completo:**

- [ ] **Listagem:** Comando aparece em `susa setup`
  - [ ] Nome está correto e legível
  - [ ] Descrição é clara e concisa
  - [ ] Indicador `[sudo]` aparece se campo `sudo: true`
  - [ ] Indicador de grupo aparece se definido

- [ ] **Info básico:** `susa setup [comando] --info` funciona
  - [ ] Exibe nome do software
  - [ ] Mostra status (instalado/não instalado)
  - [ ] Exibe versão atual (se instalado)
  - [ ] Exibe versão mais recente disponível
  - [ ] Sem erros ou mensagens estranhas

- [ ] **Help principal:** `susa setup [comando] --help`
  - [ ] Exibe nome e descrição
  - [ ] Lista todos os subcomandos (install, update, uninstall)
  - [ ] Mostra `show_complement_help()` se definido
  - [ ] Menciona flag `--info` se implementada
  - [ ] Sem erros de bash/sintaxe

- [ ] **Help dos subcomandos:**
  - [ ] `install --help` exibe descrição e opções
  - [ ] `update --help` exibe descrição e opções
  - [ ] `uninstall --help` exibe descrição e opções
  - [ ] Cada um mostra `show_complement_help()` se definido

**Output esperado de `susa setup [comando] --info`:**

```text
┌─────────────────────────────────────┐
│ [Nome do Software] - Informações    │
└─────────────────────────────────────┘

Status: ○ Não instalado
# Ou: Status: ● Instalado

Versão atual: -
# Ou: Versão atual: 1.2.3

Versão mais recente: 1.2.4
```

**Troubleshooting de Validação:**

| Problema | Causa Provável | Solução |
|----------|----------------|----------|
| Comando não aparece | Lock não regenerado | Execute `susa self lock` |
| --info não funciona | Falta flag em main.sh | Adicione case `--info)` |
| Help quebra | Erro de sintaxe bash | Execute `make lint` |
| Versão "desconhecida" | `get_current_version()` falha | Veja [Resolução de Problemas](#-resolução-de-problemas) |
| Subcomando não lista | `command.json` inválido | Valide JSON com `jq` |

**Testes Funcionais Adicionais (Recomendado):**

```bash
# Testar com verbosidade
susa -v setup [comando] install

# Testar modo quiet
susa -q setup [comando] install

# Testar dry-run (se implementado)
susa setup [comando] install --dry-run

# Verificar indicadores após instalação
susa setup  # Deve mostrar ✓ se instalado
```

### Para Comando Simples (sem subcategorias)

- [ ] Criar diretório `commands/setup/[comando]/`
- [ ] Criar `command.json` (metadados do comando)
- [ ] Criar `main.sh` (script principal)
- [ ] Implementar lógica no main.sh
- [ ] Adicionar campo `os` em command.json se necessário
- [ ] Adicionar campo `sudo` em comman (se falhar, corrija e execute novamente até passar)
- [ ] **Regenerar índice:** `susa self lock`

**Validações finais:**
- [ ] **Verificar listagem:** `susa setup` (comando deve aparecer)
- [ ] **Testar info básico:** `susa setup [comando] --info` (deve retornar dados corretos)
- [ ] **Testar help principal:** `susa setup [comando] --help` (deve exibir subcomandos)
- [ ] **Testar help de subcomandos:**
  - [ ] `susa setup [comando] install --help`
  - [ ] `susa setup [comando] update --help`
  - [ ] `susa setup [comando] uninstall --help`
⚠️ **Execute APENAS após finalizar toda a lógica do comando.**

**Comandos de finalização (na ordem):**
- [ ] **Formatar código:** `make format`
- [ ] **Validar sintaxe:** `make lint`
- [ ] **Regenerar índice:** `susa self lock`

**Validações finais:**
- [ ] **Verificar listagem:** `susa setup` (comando deve aparecer)
- [ ] **Testar info básico:** `susa setup [comando] --info` (deve retornar dados corretos)

**Testes funcionais:**
- [ ] Verificar se indicador `✓` aparece após instalação
- [ ] Verificar se indicador `[sudo]` aparece se necessário
- [ ] Testar com verbosidade: `susa -v setup [comando] install`
- [ ] Testar em modo quiet: `susa -q setup [comando] install`

## 🚫 Anti-patterns (EVITAR)

### ❌ Não reimplementar funções da biblioteca

```bash
# ❌ ERRADO - Não crie essas funções em utils/common.sh
show_software_info() {
    if check_installation; then
        log_info "$SOFTWARE_NAME está instalado"
    fi
}

display_help() {
    log_output "Comandos disponíveis:"
    log_output "  install"
}

# ✅ CORRETO - Use as funções da biblioteca
# show_software_info e display_help já existem nas libs internas
# Apenas chame-as no main.sh:
main() {
    case "$1" in
        --info)
            show_software_info  # Da biblioteca installations.sh
            exit 0
            ;;
    esac
    display_help  # Da biblioteca display.sh
}
```

### ❌ Não usar echo direto

```bash
# ❌ ERRADO - Não respeita --quiet e verbosidade
echo "Instalando software..."
echo "DEBUG: version=$version"

# ✅ CORRETO - Use funções de log
log_info "Instalando software..."
log_debug "version=$version"  # Só aparece com -v
```

### ❌ Não mapear flags globais em comandos

```bash
# ❌ ERRADO - Flags globais já são processadas pelo core
main() {
    case "$1" in
        -v|--verbose) export DEBUG=1; shift ;;
        -q|--quiet) export SILENT=1; shift ;;
    esac
}

# ✅ CORRETO - Flags já estão processadas
main() {
    # Apenas use as funções de log normalmente
    log_debug "Isso só aparece com -v"
}
```

### ❌ Não ler lock file diretamente

```bash
# ❌ ERRADO - Não use jq direto
jq '.installations[] | select(.name == "software")' "$lock_file"

# ✅ CORRETO - Use funções de cache/installations
cache_load
is_installed_cached "software"
get_installed_version_cached "software"
```

### ❌ Não retornar versão vazia/null

```bash
# ❌ ERRADO - Retorna vazio ou null
get_current_version() {
    if check_installation; then
        $BIN_NAME --version | head -1
    fi
}

# ✅ CORRETO - Sempre retorna algo ou "desconhecida"
get_current_version() {
    if check_installation; then
        $BIN_NAME --version 2>/dev/null | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}
```

### ❌ Não esquecer de atualizar o lock

```bash
# ❌ ERRADO - Não registra no lock após instalação
if [ $install_result -eq 0 ]; then
    log_success "Instalado com sucesso!"
fi

# ✅ CORRETO - Sempre registre no lock
if [ $install_result -eq 0 ] && check_installation; then
    local installed_version=$(get_current_version)
    register_or_update_software_in_lock "[nome-software]" "$installed_version"
    log_success "Instalado com sucesso!"
fi
```

### ❌ Não esquecer a flag [ "${SUSA_SHOW_HELP:-}" != "1" ]

```bash
# ❌ ERRADO - main() executa sempre, mesmo no --help
main() {
    # lógica aqui
}
main "$@"

# ✅ CORRETO - Não executa main durante --help
main() {
    # lógica aqui
}
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
```

**Por que isso importa:**

- Sem essa verificação, `main()` executa até quando usuário pede `--help`
- Pode causar erros se lógica espera argumentos obrigatórios
- Pode executar operações destrutivas inadvertidamente
- O sistema define `SUSA_SHOW_HELP=1` antes de processar o help
- **OBRIGATÓRIO em todos os entrypoints** (categoria principal e subcomandos)

### ❌ Não esquecer a flag --info na categoria principal

```bash
# ❌ ERRADO - Categoria principal sem --info
main() {
    display_help  # Só mostra help, sem opção de consulta
}

# ✅ CORRETO - Sempre implementar --info
main() {
    case "$1" in
        --info)
            show_software_info  # Função da lib installations.sh
            exit 0
            ;;
    esac
    display_help
}
```

**Por que isso importa:**

- `--info` é a interface padrão para consultar estado de instalações
- Permite verificar versão instalada vs disponível
- Essencial para automação e scripts
- Usuários esperam essa funcionalidade em todos os comandos de setup
- **OBRIGATÓRIO apenas na categoria principal** (não nos subcomandos)

### ❌ Não duplicar constantes

```bash
# ❌ ERRADO - Definir constantes em múltiplos arquivos
# Em install/main.sh:
SOFTWARE_NAME="Bruno"
HOMEBREW_PACKAGE="bruno"

# Em update/main.sh:
SOFTWARE_NAME="Bruno"
HOMEBREW_PACKAGE="bruno"

# ✅ CORRETO - Definir uma vez em utils/common.sh
# Em utils/common.sh:
SOFTWARE_NAME="Bruno"
HOMEBREW_PACKAGE="bruno"

# Em install/main.sh e update/main.sh:
source "$UTILS_DIR/common.sh"  # Importa constantes
```

### ❌ Não usar caminhos relativos para libraries

```bash
# ❌ ERRADO - Caminho relativo pode falhar
source "../../../core/lib/os.sh"

# ✅ CORRETO - Use $LIB_DIR (variável de ambiente)
source "$LIB_DIR/os.sh"
```

## 🎯 Padrões Específicos por Tipo

### Desktop Applications (Flatpak/Homebrew)

**Exemplos:** Bruno, Flameshot, DBeaver, VS Code (quando via Flatpak)

**Características:**

- macOS: Homebrew Cask
- Linux: Flatpak
- **sudo:** ❌ Não necessário (Homebrew e Flatpak são gerenciados por usuário)
- Funções: `*_install()`, `*_update()`, `*_uninstall()`, `*_is_installed()`, `*_get_*_version()`

**Template command.json (install/update/uninstall):**

```json
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"]  // Desktop apps geralmente disponíveis para ambos
  // sudo: false ou omitir - Flatpak e Homebrew não requerem sudo
}
```

**Caso especial - Software apenas para um SO:**

```json
// Software apenas para macOS (ex: Alfred, iTerm2)
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["mac"]
}

// Software apenas para Linux via Flatpak
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["linux"]
}
```

**Template utils/common.sh:**

```bash
# Constants
SOFTWARE_NAME="Nome do App"
HOMEBREW_PACKAGE="app-name"        # Cask name
FLATPAK_APP_ID="com.vendor.App"   # Flatpak ID

# Usar homebrew_* e flatpak_* funções
```

**Template install/main.sh:**

```bash
install_macos() {
    if ! homebrew_is_installed "$HOMEBREW_PACKAGE"; then
        homebrew_install "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
    else
        log_warning "$SOFTWARE_NAME já está instalado via Homebrew"
    fi
}

install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$SOFTWARE_NAME"
}
```

### CLI Tools (GitHub Releases)

**Exemplos:** LazyPG (Linux), uv, poetry

**Características:**

- macOS: Homebrew Formula ou Tap
- Linux: Download direto do GitHub Releases
- **sudo:** ⚠️ Depende do diretório de instalação:
  - ❌ Não necessário se instalar em `~/.local/bin` (diretório do usuário)
  - ✅ Necessário se instalar em `/usr/local/bin` (diretório do sistema)
- Detecção automática de arquitetura
- Instalação em `~/.local/bin` (preferido) ou `/usr/local/bin`

**Template command.json (quando instalar em ~/.local/bin):**

```json
{
  "name": "Install",
  "description": "Instala o [Tool]",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"]  // CLI tools geralmente disponíveis para ambos
  // sudo: false ou omitir - instalação em diretório do usuário
}
```

**Template command.json (quando instalar em /usr/local/bin):**

```json
{
  "name": "Install",
  "description": "Instala o [Tool]",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"],
  "sudo": true  // Necessário para escrever em /usr/local/bin
}
```

**Caso especial - Tool apenas para um SO:**

```json
// Ferramenta apenas para Linux (ex: algumas ferramentas específicas)
{
  "name": "Install",
  "description": "Instala o [Tool]",
  "entrypoint": "main.sh",
  "os": ["linux"]
}

// Ferramenta apenas para macOS (ex: algumas ferramentas específicas)
{
  "name": "Install",
  "description": "Instala o [Tool]",
  "entrypoint": "main.sh",
  "os": ["mac"]
}
```

**Template utils/common.sh:**

```bash
# Source github library
source "$LIB_DIR/github.sh"
source "$LIB_DIR/homebrew.sh"

# Constants
readonly SOFTWARE_NAME="tool-name"
readonly GITHUB_REPO="owner/repo"
readonly HOMEBREW_FORMULA="formula-name"  # Pode incluir tap
readonly BIN_NAME="tool"

check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_FORMULA"
    else
        command -v "$BIN_NAME" &> /dev/null
    fi
}

get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$HOMEBREW_FORMULA"
        else
            # Pode usar get_installed_version do susa.lock
            # ou executar o binário com --version
            $BIN_NAME --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
        fi
    fi
}

get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$HOMEBREW_FORMULA"
    else
        github_get_latest_version "$GITHUB_REPO"
    fi
}
```

**Template install/main.sh para Linux (GitHub):**

```bash
install_linux() {
    log_info "Obtendo $SOFTWARE_NAME via GitHub Releases..."

    # Detect architecture
    local os_arch=$(github_detect_os_arch "standard")
    local arch="${os_arch#*:}"

    # Map to release naming (ex: amd64, arm64)
    local release_arch=""
    case "$arch" in
        x64) release_arch="amd64" ;;
        arm64) release_arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Get latest version
    local latest_version=$(github_get_latest_version "$GITHUB_REPO" "true")
    if [ -z "$latest_version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: v$latest_version"

    # Build download URL based on release pattern
    local filename="${SOFTWARE_NAME}_${latest_version}_linux_${release_arch}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${latest_version}/${filename}"

    local temp_dir=$(mktemp -d)
    local archive_path="$temp_dir/$filename"

    # Download
    if ! github_download_release "$download_url" "$archive_path" "$SOFTWARE_NAME"; then
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract and install
    tar -xzf "$archive_path" -C "$temp_dir"

    # Install to user bin
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    if [ -f "$temp_dir/$BIN_NAME" ]; then
        mv "$temp_dir/$BIN_NAME" "$install_dir/"
        chmod +x "$install_dir/$BIN_NAME"
    fi

    rm -rf "$temp_dir"

    # Verify installation
    if command -v "$BIN_NAME" &> /dev/null; then
        export INSTALLED_VERSION="$latest_version"
        return 0
    else
        log_error "$install_dir não está no PATH"
        return 1
    fi
}
```

### System Packages (apt/dnf/pacman)

**Exemplos:** PostgreSQL Client, MySQL Client, Redis

**Características:**

- macOS: Homebrew Formula
- Linux: Gerenciador de pacotes nativo (apt, dnf, pacman)
- **sudo:** ✅ **Obrigatório** para apt/dnf/pacman (modificam sistema)
- **sudo:** ❌ Não necessário para Homebrew (macOS)
- Detecção de distribuição necessária

**Template command.json (system packages disponíveis para ambos):**

```json
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["linux", "mac"],
  "sudo": true  // OBRIGATÓRIO para apt/dnf/pacman no Linux
                // Homebrew no macOS não requer sudo, mas marcamos pela plataforma Linux
}
```

**Template command.json (system package apenas Linux):**

```json
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["linux"],
  "sudo": true  // OBRIGATÓRIO para apt/dnf/pacman
}
```

**Template command.json (system package apenas macOS):**

```json
{
  "name": "Install",
  "description": "Instala o [Software]",
  "entrypoint": "main.sh",
  "os": ["mac"]
  // sudo: false ou omitir - Homebrew não requer sudo
}
```

**Template utils/common.sh:**
```bash
# Source homebrew library
source "$LIB_DIR/homebrew.sh"

# Constants
SOFTWARE_NAME="Software Name"
PKG_DEBIAN="package-name"          # Para Debian/Ubuntu
PKG_REDHAT="package-name"          # Para Fedora/RHEL
PKG_ARCH="package-name"            # Para Arch/Manjaro
PKG_HOMEBREW="formula-name"        # Para macOS
BIN_NAME="command"                 # Comando principal

check_installation() {
    command -v "$BIN_NAME" &> /dev/null
}

get_current_version() {
    if check_installation; then
        # Extrair versão do comando
        $BIN_NAME --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'
    fi
}

get_latest_version() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            homebrew_get_latest_version_formula "$PKG_HOMEBREW"
            ;;
        linux)
            local distro=$(get_distro_id)
            case "$distro" in
                ubuntu|debian|pop|linuxmint)
                    apt-cache policy "$PKG_DEBIAN" | grep Candidate | awk '{print $2}'
                    ;;
                fedora|rhel|centos|rocky|almalinux)
                    dnf info "$PKG_REDHAT" | grep Version | awk '{print $2}'
                    ;;
                arch|manjaro)
                    pacman -Si "$PKG_ARCH" | grep Version | awk '{print $3}'
                    ;;
            esac
            ;;
    esac
}
```

**Template install/main.sh com suporte a múltiplas distros:**

```bash
# Install on Debian/Ubuntu
install_debian() {
    log_info "Instalando via apt..."
    sudo apt update
    sudo apt install -y "$PKG_DEBIAN"
}

# Install on Fedora/RHEL
install_redhat() {
    log_info "Instalando via dnf/yum..."
    local pkg_manager=$(get_redhat_pkg_manager)
    sudo $pkg_manager install -y "$PKG_REDHAT"
}

# Install on Arch/Manjaro
install_arch() {
    log_info "Instalando via pacman..."
    sudo pacman -S --noconfirm "$PKG_ARCH"
}

# Install on macOS
install_macos() {
    log_info "Instalando via Homebrew..."
    homebrew_install "$PKG_HOMEBREW" "$SOFTWARE_NAME"
}

# Main function
main() {
    if check_installation; then
        log_info "$SOFTWARE_NAME $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do $SOFTWARE_NAME..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_macos
            install_result=$?
            ;;
        linux)
            local distro=$(get_distro_id)
            case "$distro" in
                ubuntu|debian|pop|linuxmint)
                    install_debian
                    install_result=$?
                    ;;
                fedora|rhel|centos|rocky|almalinux)
                    install_redhat
                    install_result=$?
                    ;;
                arch|manjaro)
                    install_arch
                    install_result=$?
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $install_result -eq 0 ] && check_installation; then
        local installed_version=$(get_current_version)
        register_or_update_software_in_lock "[nome-software]" "$installed_version"
        log_success "$SOFTWARE_NAME $installed_version instalado com sucesso!"
    fi

    return $install_result
}
```

### Casos Especiais

#### VS Code (Múltiplos métodos de instalação)

- macOS: Homebrew Cask
- Linux: Flatpak, Snap, ou repositório oficial (.deb/.rpm)
- Requer detecção de método de instalação para backup/config

**Características especiais:**

- Função `check_installation_alternative()` para detectar instalações manuais
- Função `get_vscode_config_paths()` para lidar com diferentes locais de config
- Comando `backup` para exportar configurações e extensões

#### Softwares com subdiretório utils/ customizado

Alguns comandos (como VS Code, PostgreSQL) tem arquivos adicionais em `utils/`:

- `install.sh` - Funções específicas de instalação por plataforma
- `backup.sh` - Lógica de backup (se comando tiver subcomando backup)

**Exemplo de estrutura:**

```text
commands/setup/vscode/
├── category.json
├── main.sh
├── install/
│   └── main.sh
├── update/
│   └── main.sh
├── backup/
│   └── main.sh
└── utils/
    ├── common.sh       # Funções compartilhadas
    ├── install.sh      # Lógica de instalação específica
    └── backup.sh       # Lógica de backup
```

## � Resolução de Problemas

### Comando não aparece na listagem

**Problema:** Após criar comando, ele não aparece em `susa setup`

**Solução:**
```bash
# Regenerar o lock file
susa self lock

# Verificar se foi adicionado
susa setup
```

**Verificações adicionais:**
- [ ] `category.json` existe e tem estrutura válida?
- [ ] `command.json` existe em cada subcomando?
- [ ] Não há erros de sintaxe JSON? (use `jq . category.json`)
- [ ] Campo `os` está correto para o sistema atual?

### make lint falha

**Problema:** `make lint` reporta erros do shellcheck

**Como interpretar erros:**

```bash
# Executar lint com detalhes
make lint

# Exemplo de erro comum:
# SC2086: Quote to prevent word splitting
# Solução: Adicionar aspas em variáveis: "$var" ao invés de $var

# SC2155: Declare and assign separately
# Solução: Separar declare e atribuição:
local version
version=$(get_version)
```

**Erros comuns e soluções:**

| Erro | Causa | Solução |
|------|-------|----------|
| SC2086 | Variável sem aspas | Use `"$var"` |
| SC2155 | Declare + assign juntos | Separe em duas linhas |
| SC2046 | Command substitution sem aspas | Use `"$(command)"` |
| SC2034 | Variável não usada | Remova ou use `readonly` |
| SC2154 | Variável não definida | Declare antes de usar |

**Dica:** Use `shellcheck [arquivo]` para ver explicação detalhada de cada erro.

### Versão aparece como 'desconhecida'

**Problema:** `susa setup [comando] --info` mostra versão "desconhecida"

**Causas possíveis:**

1. **`get_current_version()` retorna vazio**
   ```bash
   # ❌ Ruim
   get_current_version() {
       $BIN_NAME --version | grep -oE '[0-9.]+'
   }

   # ✅ Bom
   get_current_version() {
       if check_installation; then
           $BIN_NAME --version 2>/dev/null | grep -oE '[0-9.]+' || echo "desconhecida"
       else
           echo "desconhecida"
       fi
   }
   ```

2. **Comando não está no PATH**
   ```bash
   # Verificar se comando está acessível
   which [comando]
   echo $PATH
   ```

3. **Regex não captura formato da versão**
   ```bash
   # Testar regex manualmente
   [comando] --version
   [comando] --version | grep -oE '[0-9.]+'
   ```

### Software instalado mas check_installation() retorna falso

**Problema:** Software foi instalado mas SUSA não detecta

**Verificações:**

```bash
# 1. Verificar se binário existe
which [comando]
command -v [comando]

# 2. Verificar método de instalação
# Homebrew
brew list [package]

# Flatpak
flatpak list | grep [app-id]

# Snap
snap list | grep [package]

# 3. Verificar se check_installation() está correto
# Deve usar o mesmo método que a instalação
```

**Solução:** Alinhar `check_installation()` com método usado no `install`:

```bash
# Se instalou via Homebrew
check_installation() {
    homebrew_is_installed "$HOMEBREW_PACKAGE"
}

# Se instalou via Flatpak
check_installation() {
    flatpak_is_installed "$FLATPAK_APP_ID"
}

# Se instalou binário direto
check_installation() {
    command -v "$BIN_NAME" &> /dev/null
}
```

### Erro de permissão ao instalar

**Problema:** "Permission denied" durante instalação

**Causa:** Tentando escrever em diretório do sistema sem sudo

**Solução:**

1. **Marcar `sudo: true` no command.json**
   ```json
   {
     "name": "Install",
     "sudo": true
   }
   ```

2. **Usar diretório do usuário ao invés de sistema**
   ```bash
   # ❌ Requer sudo
   mv binary /usr/local/bin/

   # ✅ Não requer sudo
   mkdir -p ~/.local/bin
   mv binary ~/.local/bin/
   ```

3. **Usar biblioteca sudo.sh para prompt amigável**
   ```bash
   source "$LIB_DIR/sudo.sh"
   run_with_sudo "mv binary /usr/local/bin/"
   ```

### Argumentos não são processados

**Problema:** Flags como `--force` não funcionam

**Causa:** Esquecer de processar argumentos em `main()`

**Solução:**

```bash
main() {
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                force=true
                shift
                ;;
            *)
                log_error "Opção inválida: $1"
                return 1
                ;;
        esac
    done

    # Use as flags
    if [ "$force" = "true" ]; then
        # Lógica de força
    fi
}
```

### Help não exibe show_complement_help()

**Problema:** Conteúdo de `show_complement_help()` não aparece

**Verificações:**

1. **Função está definida antes de `main()`?**
2. **Arquivo não tem `show_help()` customizado?** (que sobrescreve o padrão)
3. **Executando com `--help`?** (e não sem argumentos)

**Debug:**

```bash
# Testar se função existe
type show_complement_help

# Verificar se há show_help() customizado
grep -n "show_help()" main.sh
```

---

## �📖 Referências e Exemplos

### Exemplos Reais de Comandos

#### Desktop Applications (Flatpak/Homebrew)

- **Bruno** - `commands/setup/bruno/`
  - Cliente de API open-source
  - Padrão simples: macOS (Homebrew Cask) + Linux (Flatpak)
  - ✅ **Melhor exemplo para copiar estrutura básica**

- **Flameshot** - `commands/setup/flameshot/`
  - Ferramenta de screenshot
  - Similar ao Bruno, estrutura limpa

- **DBeaver** - `commands/setup/dbeaver/`
  - Cliente de banco de dados
  - Inclui subcomando `backup` adicional

#### CLI Tools (GitHub Releases + Homebrew)

- **LazyPG** - `commands/setup/lazypg/`
  - TUI para PostgreSQL
  - macOS: Homebrew Tap
  - Linux: GitHub Releases com detecção de arquitetura
  - ✅ **Melhor exemplo para CLI tools**

#### System Packages (apt/dnf/pacman + Homebrew)

- **PostgreSQL Client** - `commands/setup/postgres/`
  - Cliente PostgreSQL
  - Suporta múltiplas distribuições Linux
  - Detecção de versão customizada por gerenciador de pacotes
  - ✅ **Melhor exemplo para system packages**

#### Casos Especiais

- **VS Code** - `commands/setup/vscode/`
  - Múltiplos métodos de instalação (Flatpak, Snap, repositório oficial)
  - Subcomando `backup` para exportar configurações
  - Detecção de método de instalação para paths de config
  - Arquivos extras em `utils/`: `install.sh`, `backup.sh`

### Qual estrutura usar?

| Se o software é... | Use como referência | Características |
|--------------------|---------------------|-----------------|
| Desktop app GUI | **Bruno** | Flatpak + Homebrew Cask |
| CLI tool simples | **LazyPG** | GitHub Releases + Homebrew |
| System package | **PostgreSQL** | apt/dnf/pacman + Homebrew |
| Com múltiplos métodos | **VS Code** | Detecta método e adapta |
| Com backup/config | **DBeaver** ou **VS Code** | Subcomando extra |

### Documentação Completa

Para detalhes sobre bibliotecas, contexto, cache, etc:

- **Copilot Instructions:** `.github/copilot-instructions.md`
- **Bibliotecas:** `core/lib/`
- **Comando de exemplo completo:** `commands/setup/bruno/`
