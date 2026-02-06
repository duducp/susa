#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ===============================================================================
# Susa CLI Remote Installer
# ===============================================================================
#
# OBJETIVO:
#   Instalador remoto do Susa CLI - ferramenta de linha de comando para
#   gerenciamento de desenvolvimento e instalação de softwares.
#
# O QUE ELE FAZ:
#   1. Detecta o sistema operacional (macOS, Debian, Fedora, etc)
#   2. Verifica e instala dependências obrigatórias:
#      - homebrew (macOS - gerenciador de pacotes, instalado automaticamente)
#      - git (controle de versão)
#      - zsh (shell requerido)
#      - jq (processamento de JSON)
#      - gum (interface interativa)
#      - pip3 (gerenciador de pacotes Python)
#   3. Clona o repositório do GitHub
#   4. Copia arquivos para ~/.local/susa
#   5. Cria symlink em ~/.local/bin/susa
#   6. Configura PATH em shells disponíveis (bash, zsh)
#   7. Oferece instalação de autocompletar (tab completion)
#
# USO:
# Instalação remota (recomendado)
#   curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/install.sh | bash
# ou
#   curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/install.sh | zsh
#
# Alternativa com wget
#   wget -qO- https://raw.githubusercontent.com/duducp/susa/main/install.sh | bash
# ou
#   wget -qO- https://raw.githubusercontent.com/duducp/susa/main/install.sh | zsh
#
# Instalação local
#   bash install.sh
# ou
#   zsh install.sh
#
#   ℹ️  NOTA: Script funciona com bash ou zsh. ZSH será instalado automaticamente se ausente.
#
# COMPATIBILIDADE:
#   - Linux: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch (pacman)
#   - macOS: Homebrew instalado automaticamente se ausente
#
# REQUISITOS:
#   - ZSH (instalado automaticamente se ausente)
#   - curl ou wget
#   - Conexão com internet
#   - Permissões sudo (para instalação de dependências)
#
# ESTRUTURA PÓS-INSTALAÇÃO:
#   ~/.local/susa/          # Código completo do CLI
#   ~/.local/bin/susa       # Symlink executável
#   ~/.zshrc ou ~/.bashrc   # PATH configurado
#
# NOTAS:
#   - Funciona tanto via pipe (curl | zsh) quanto execução direta
#   - Detecta modo interativo e adapta comportamento
#   - Cria backups de configurações de shell
#   - Suporta reinstalação (substitui instalação anterior)
#
# ===============================================================================

# Settings
REPO_URL="${CLI_REPO_URL:-https://github.com/duducp/susa.git}"
REPO_BRANCH="${CLI_REPO_BRANCH:-main}"
CLI_NAME="susa"
INSTALL_DIR="$HOME/.local/susa"
BIN_DIR="$HOME/.local/bin"
TEMP_DIR=$(mktemp -d)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Detect operating system
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu | debian)
                echo "debian"
                ;;
            fedora | rhel | centos | rocky | almalinux)
                echo "fedora"
                ;;
            *)
                echo "linux"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Verify command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Wait for apt lock to be released (Debian/Ubuntu systems)
wait_for_apt_lock() {
    local max_wait=300 # Maximum wait time in seconds (5 minutes)
    local elapsed=0

    while sudo fuser /var/lib/dpkg/lock-frontend > /dev/null 2>&1 ||
        sudo fuser /var/lib/apt/lists/lock > /dev/null 2>&1; do
        if [ $elapsed -ge $max_wait ]; then
            log_error "Timeout esperando liberação do apt lock"
            return 1
        fi

        if [ $elapsed -eq 0 ]; then
            log_warning "Aguardando liberação do sistema de pacotes..."
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    return 0
}

# ============================================================
# Check and Install Dependencies
# ============================================================

# Ensure jq is installed. If not, try installing.
ensure_jq_installed() {
    if command -v jq &> /dev/null; then
        return 0
    fi

    log_warning "jq não encontrado. Tentando instalar..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y jq > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y jq > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq > /dev/null 2>&1
    elif command -v brew &> /dev/null; then
        brew install jq > /dev/null 2>&1
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm jq > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do jq"
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "Falha ao instalar o jq. Instale manualmente."
        return 1
    fi

    log_success "✓ jq instalado com sucesso"
    return 0
}

# Ensure gum is installed. If not, try installing.
ensure_gum_installed() {
    if command -v gum &> /dev/null; then
        return 0
    fi

    log_warning "gum não encontrado. Tentando instalar..."

    if command -v apt-get &> /dev/null; then
        # For Debian/Ubuntu, use the official installation method
        sudo mkdir -p /etc/apt/keyrings > /dev/null 2>&1
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg > /dev/null 2>&1
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null 2>&1
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y gum > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo > /dev/null 2>&1
        sudo dnf install -y gum > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo > /dev/null 2>&1
        sudo yum install -y gum > /dev/null 2>&1
    elif command -v brew &> /dev/null; then
        brew install gum > /dev/null 2>&1
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm gum > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do gum"
        log_info "Visite: https://github.com/charmbracelet/gum#installation"
        return 1
    fi

    if ! command -v gum &> /dev/null; then
        log_error "Falha ao instalar o gum. Instale manualmente."
        log_info "Visite: https://github.com/charmbracelet/gum#installation"
        return 1
    fi

    log_success "✓ gum instalado com sucesso"
    return 0
}

# Ensure zsh is installed. If not, try installing.
ensure_zsh_installed() {
    if command -v zsh &> /dev/null; then
        return 0
    fi

    log_warning "zsh não encontrado. Tentando instalar..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y zsh > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y zsh > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y zsh > /dev/null 2>&1
    elif command -v brew &> /dev/null; then
        brew install zsh > /dev/null 2>&1
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do zsh"
        return 1
    fi

    if ! command -v zsh &> /dev/null; then
        log_error "Falha ao instalar o zsh. Instale manualmente."
        return 1
    fi

    log_success "✓ zsh instalado com sucesso"
    return 0
}

# Ensure pip3 is installed. If not, try installing.
ensure_pip3_installed() {
    if command -v pip3 &> /dev/null; then
        return 0
    fi

    log_warning "pip3 não encontrado. Tentando instalar python3-pip..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y python3-pip > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do pip3"
        return 1
    fi

    if ! command -v pip3 &> /dev/null; then
        log_error "Falha ao instalar o pip3. Instale manualmente."
        return 1
    fi

    log_success "✓ pip3 instalado com sucesso"
    return 0
}

# Ensure git is installed. If not, try installing.
ensure_git_installed() {
    if command -v git &> /dev/null; then
        return 0
    fi

    log_warning "git não encontrado. Tentando instalar..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y git > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y git > /dev/null 2>&1
    elif command -v brew &> /dev/null; then
        brew install git > /dev/null 2>&1
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm git > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do git"
        return 1
    fi

    if ! command -v git &> /dev/null; then
        log_error "Falha ao instalar o git. Instale manualmente."
        return 1
    fi

    log_success "✓ git instalado com sucesso"
    return 0
}

# Ensure Homebrew is installed on macOS. If not, try installing.
ensure_homebrew_installed() {
    # Only for macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        return 0
    fi

    if command -v brew &> /dev/null; then
        return 0
    fi

    log_warning "Homebrew não encontrado. Tentando instalar..."

    # Install Homebrew using official script
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        log_success "✓ homebrew instalado com sucesso"
        return 0
    else
        log_error "Falha ao instalar o Homebrew."
        log_info "Instale manualmente: https://brew.sh"
        return 1
    fi
}

check_and_install_dependencies() {
    local failed=()

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  📦 Verificando Dependências${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Install Homebrew first on macOS (required for other dependencies)
    if [[ "$(uname)" == "Darwin" ]]; then
        if ! ensure_homebrew_installed; then
            failed+=("homebrew")
        fi
    fi

    # Try to install each dependency using dedicated functions
    if ! ensure_git_installed; then
        failed+=("git")
    fi

    if ! ensure_zsh_installed; then
        failed+=("zsh")
    fi

    if ! ensure_jq_installed; then
        failed+=("jq")
    fi

    if ! ensure_gum_installed; then
        failed+=("gum")
    fi

    if ! ensure_pip3_installed; then
        failed+=("pip3")
    fi

    echo ""

    # Report results
    if [ ${#failed[@]} -gt 0 ]; then
        log_error "Falha ao instalar as seguintes dependências: ${failed[*]}"
        echo ""
        echo "Por favor, instale manualmente e execute novamente."
        echo ""
        exit 1
    fi

    log_success "✨ Todas as dependências estão instaladas!"
}

# ============================================================
# Shell Configuration
# ============================================================

configure_shell() {
    local shell_name="$1"
    local shell_config="$2"

    if [ -f "$shell_config" ]; then
        # Backup existing file
        cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)" 2> /dev/null || true
    fi

    # Check if PATH is already configured
    if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$shell_config" 2> /dev/null ||
        grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$shell_config" 2> /dev/null; then
        echo "  ✓ $shell_name já configurado"
        return 0
    fi

    # Add PATH configuration
    cat >> "$shell_config" << 'EOF'

export PATH="$HOME/.local/bin:$PATH"
EOF
    echo "  ✓ $shell_name configurado"
}

configure_shells() {
    echo -e "${BOLD}→ 🐚 Configurando shells disponíveis...${NC}"
    echo ""

    local shells_configured=0
    local shells_not_found=()

    # Bash configuration
    if command_exists bash; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: Configure both .bashrc and .bash_profile
            configure_shell "Bash (.bashrc)" "$HOME/.bashrc"
            configure_shell "Bash (.bash_profile)" "$HOME/.bash_profile"

            # Ensure .bash_profile sources .bashrc
            if [ -f "$HOME/.bash_profile" ]; then
                if ! grep -q "source.*bashrc" "$HOME/.bash_profile" 2> /dev/null; then
                    cat >> "$HOME/.bash_profile" << 'EOF'

# Source .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF
                fi
            fi
        else
            # Linux: Configure .bashrc
            configure_shell "Bash" "$HOME/.bashrc"
        fi
        shells_configured=$((shells_configured + 1))
    else
        shells_not_found+=("Bash")
    fi

    # Zsh configuration
    if command_exists zsh; then
        configure_shell "Zsh" "$HOME/.zshrc"
        shells_configured=$((shells_configured + 1))
    else
        shells_not_found+=("Zsh")
    fi

    echo ""
    if [ ${#shells_not_found[@]} -gt 0 ]; then
        echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${DIM}  ℹ️  Shells não encontrados${NC}"
        echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        for shell in "${shells_not_found[@]}"; do
            echo "  • $shell não está instalado"
        done
        echo ""
        echo "Se você instalar algum destes shells no futuro,"
        echo "configure manualmente adicionando ao arquivo de configuração:"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# ============================================================
# Shell Completion
# ============================================================

install_completion() {
    echo ""
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}  ⚡ Shell Completion (Autocompletar)${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Check if running in interactive mode
    if [ -t 0 ]; then
        # Interactive mode - ask user
        echo -e "${CYAN}Instalar autocompletar (tab completion)?${NC}"
        echo -e "${DIM}Permite usar TAB para completar comandos.${NC}"
        echo ""
        read -p "Instalar agora? (s/N): " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[SsYy]$ ]]; then
            echo ""
            echo -e "${BOLD}→ Instalando autocompletar...${NC}"
            echo ""
            # Execute completion command
            if "$BIN_DIR/$CLI_NAME" self completion --install; then
                echo ""
                echo "  ✓ Autocompletar instalado com sucesso"
                echo ""
                echo "  Nota: Reinicie o terminal ou execute 'source' no seu shell config"
            fi
        else
            echo ""
            echo "  Você pode instalar depois com:"
            echo "  $CLI_NAME self completion --install"
        fi
    else
        # Non-interactive mode (piped from curl, etc.) - skip completion
        echo -e "${DIM}Modo não-interativo detectado.${NC}"
        echo -e "${DIM}Instalação do autocompletar será pulada.${NC}"
        echo ""
        echo "  Você pode instalar depois com:"
        echo "  $CLI_NAME self completion --install"
    fi
}

# ============================================================
# Banner
# ============================================================

show_banner() {
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                                        ║${NC}"
    echo -e "${BOLD}${CYAN}║       🚀 Susa CLI Installer 🚀         ║${NC}"
    echo -e "${BOLD}${CYAN}║                                        ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}  Instalador inteligente com detecção automática${NC}"
    echo ""
}

# ============================================================
# Main Installation
# ============================================================

main() {
    show_banner

    local os_type=$(detect_os)
    echo -e "${CYAN}🖥️  Sistema detectado:${NC} ${BOLD}$os_type${NC}"

    if [ "$os_type" = "unknown" ]; then
        log_error "Sistema operacional não suportado"
        exit 1
    fi

    # Check dependencies (git, jq, zsh, gum, pip3)
    check_and_install_dependencies

    # Clone repository
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  📥 Baixando Susa CLI${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    cd "$TEMP_DIR"

    if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" cli; then
        log_error "Falha ao clonar repositório: $REPO_URL"
        log_info "Verifique se o repositório existe e está acessível"
        exit 1
    fi

    cd cli

    # Check for existing installation
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Susa CLI já está instalado em: $INSTALL_DIR"
        log_info "A instalação atual será substituída."
        echo ""
        rm -rf "$INSTALL_DIR"
    fi

    # Copy to permanent location (excluding .git)
    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${GREEN}  📦 Instalando Susa CLI${NC}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${CYAN}→ Instalando em${NC} ${BOLD}$INSTALL_DIR${NC}..."
    mkdir -p "$INSTALL_DIR"

    # Copy all files except .git directory
    find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -r {} "$INSTALL_DIR/" \;

    # Create bin directory if it doesn't exist
    if [ ! -d "$BIN_DIR" ]; then
        echo -e "${CYAN}→ Criando diretório de executáveis...${NC}"
        mkdir -p "$BIN_DIR"
        echo -e "  ${GREEN}✓${NC} Diretório criado: ${BOLD}$BIN_DIR${NC}"
    fi

    # Create symlink for the CLI
    echo -e "${CYAN}→ Criando link simbólico...${NC}"
    ln -sf "$INSTALL_DIR/core/$CLI_NAME" "$BIN_DIR/$CLI_NAME"
    echo -e "  ${GREEN}✓${NC} Executável instalado em ${BOLD}$BIN_DIR/$CLI_NAME${NC}"

    # Configure shells
    configure_shells

    # Check if directory is in PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo ""
        echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${YELLOW}  ⚠️  Recarregamento do shell necessário${NC}"
        echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}Para usar o Susa CLI, recarregue seu shell:${NC}"
        echo ""

        # Detect current shell
        current_shell=$(basename "$SHELL")
        case "$current_shell" in
            bash)
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    echo -e "  ${BOLD}${CYAN}source ~/.bash_profile${NC}"
                else
                    echo -e "  ${BOLD}${CYAN}source ~/.bashrc${NC}"
                fi
                ;;
            zsh)
                echo -e "  ${BOLD}${CYAN}source ~/.zshrc${NC}"
                ;;
            *)
                echo -e "  ${BOLD}Reinicie seu terminal${NC}"
                ;;
        esac

        echo ""
        echo -e "${DIM}Ou simplesmente abra um novo terminal.${NC}"
    else
        echo -e "${CYAN}→ Verificando PATH no shell atual...${NC}"
        echo -e "  ${GREEN}✓${NC} Diretório já está no PATH"
    fi

    # Install completion
    install_completion

    echo ""
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${GREEN}  🎉 Susa CLI instalado com sucesso! 🎉  ${NC}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  📚 Comandos Úteis${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${DIM}Uso básico:${NC}"
    echo -e "    ${BOLD}$CLI_NAME${NC} ${CYAN}<categoria> <comando>${NC} ${DIM}[opções]${NC}"
    echo ""
    echo -e "  ${DIM}Exemplos:${NC}"
    echo -e "    ${BOLD}$CLI_NAME setup docker${NC}        ${DIM}# Instalar Docker${NC}"
    echo -e "    ${BOLD}$CLI_NAME self info${NC}           ${DIM}# Info da instalação${NC}"
    echo -e "    ${BOLD}$CLI_NAME self version${NC}        ${DIM}# Versão do CLI${NC}"
    echo ""
    echo -e "  ${DIM}Ajuda completa:${NC}"
    echo -e "    ${BOLD}$CLI_NAME --help${NC}"
    echo ""
    echo -e "${BLUE}📖 Documentação:${NC} ${BOLD}https://duducp.github.io/susa${NC}"
    echo ""
}

# Run installation
main "$@"
