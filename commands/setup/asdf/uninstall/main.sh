#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

SKIP_CONFIRM=false

# Check if ASDF is already configured in shell
is_asdf_configured() {
    local shell_config="$1"
    grep -q "ASDF_DATA_DIR" "$shell_config" 2> /dev/null
}

show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação"
    log_output "  -h, --help        Mostra esta mensagem"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup asdf uninstall        # Desinstala com confirmação"
    log_output "  susa setup asdf uninstall -y     # Desinstala sem confirmação"
}

main() {
    local asdf_dir="$ASDF_INSTALL_DIR"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h | --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    local shell_config=$(detect_shell_config)

    # Check if installed
    if [ ! -d "$asdf_dir" ]; then
        log_warning "ASDF não está instalado"
        return 0
    fi

    local current_version="unknown"
    if command -v asdf &> /dev/null; then
        current_version=$(asdf --version 2> /dev/null | awk '{print $1}' || echo "unknown")
    fi

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o ASDF $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Desinstalando ASDF..."

    # Ask about removing installed tools (Node, Python, Ruby, etc)
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as linguagens gerenciadas pelo ASDF (Node, Python, Ruby, etc)? (s/N)${NC}"
        read -r tools_response

        if [[ "$tools_response" =~ ^[sSyY]$ ]]; then
            rm -rf "$asdf_dir"
            log_debug "ASDF e linguagens removidos: $asdf_dir"
            log_success "ASDF e linguagens gerenciadas removidos"
        else
            log_info "Linguagens mantidas em $asdf_dir"
            log_warning "ASDF desinstalado mas linguagens mantidas (não funcionarão sem ASDF)"
        fi
    else
        # Auto-remove when --yes is used
        rm -rf "$asdf_dir"
        log_debug "ASDF e linguagens removidos: $asdf_dir"
        log_info "ASDF e linguagens gerenciadas removidos automaticamente"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_asdf_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        # Create backup
        cp "$shell_config" "$backup_file"

        # Remove ASDF lines
        sed -i.tmp '/# ASDF Version Manager/d' "$shell_config"
        sed -i.tmp '/ASDF_DATA_DIR/d' "$shell_config"
        sed -i.tmp '/asdf\.sh/d' "$shell_config"
        sed -i.tmp '/asdf\.bash/d' "$shell_config"
        rm -f "${shell_config}.tmp"
    fi

    log_success "ASDF desinstalado com sucesso!"
    remove_software_in_lock "asdf"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
