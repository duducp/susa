#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  LazyPG é uma interface de terminal (TUI) simples e intuitiva para"
    log_output "  gerenciar bancos de dados PostgreSQL. Oferece navegação fácil entre"
    log_output "  schemas, tabelas, e execução de queries com visualização interativa."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazypg install            # Instala LazyPG"
    log_output "  susa setup lazypg install -v         # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Configure variáveis de ambiente (opcional):"
    log_output "    ${LIGHT_GRAY}export PGHOST=localhost${NC}"
    log_output "    ${LIGHT_GRAY}export PGUSER=postgres${NC}"
    log_output "    ${LIGHT_GRAY}export PGDATABASE=mydb${NC}"
    log_output ""
    log_output "  Execute: ${LIGHT_CYAN}lazypg${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Variáveis de ambiente:${NC}"
    log_output "  PGHOST        Hostname do PostgreSQL"
    log_output "  PGPORT        Porta (padrão: 5432)"
    log_output "  PGUSER        Usuário"
    log_output "  PGDATABASE    Banco de dados"
    log_output "  PGPASSWORD    Senha"
}

# Install lazypg on macOS using Homebrew
install_lazypg_macos() {
    log_info "Instalando LazyPG via Homebrew..."

    # Check if Homebrew is available
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Por favor, instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install lazypg using homebrew_install
    if homebrew_install "$LAZYPG_HOMEBREW_FORMULA" "LazyPG"; then
        # Export version for main install function
        export INSTALLED_LAZYPG_VERSION=$(get_current_version)
        return 0
    else
        log_error "Falha ao instalar LazyPG via Homebrew"
        return 1
    fi
}

# Main function
main() {
    if check_installation; then
        log_info "LazyPG $(get_current_version) já está instalado."
        log_info "Use 'susa setup lazypg update' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do LazyPG..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_lazypg_macos
            install_result=$?
            ;;
        linux)
            install_or_update_lazypg_linux
            install_result=$?
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            # Use exported version from install function, or fallback to detection
            local installed_version="${INSTALLED_LAZYPG_VERSION:-$(get_current_version)}"
            log_success "LazyPG $installed_version instalado com sucesso!"
            log_debug "Registrando LazyPG no lock file..."
            register_or_update_software_in_lock "$LAZYPG_NAME" "$installed_version"
            log_debug "LazyPG registrado com sucesso"

            echo ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}lazypg${NC}"
        else
            log_error "LazyPG foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        log_error "Falha na instalação do LazyPG"
        return 1
    fi
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
