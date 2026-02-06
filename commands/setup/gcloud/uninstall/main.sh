#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

SKIP_CONFIRM=false

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
    log_output "  susa setup gcloud uninstall        # Desinstala com confirmação"
    log_output "  susa setup gcloud uninstall -y     # Desinstala sem confirmação"
}

main() {
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

    # Check if gcloud is installed
    if ! check_installation; then
        log_info "Google Cloud SDK não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o Google Cloud SDK $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Desinstalando Google Cloud SDK..."

    # Detect OS
    if is_mac; then
        # Check if installed via Homebrew
        if homebrew_is_installed_formula "google-cloud-sdk"; then
            log_info "Desinstalando via Homebrew..."
            homebrew_uninstall_formula "google-cloud-sdk" "Google Cloud SDK" || {
                log_error "Falha ao desinstalar via Homebrew"
                return 1
            }
        else
            # Remove tarball installation
            local install_dir="$HOME/.local/share/google-cloud-sdk"
            if [ -d "$install_dir" ]; then
                rm -rf "$install_dir"
                log_debug "Removido diretório $install_dir"
            fi
        fi
    else
        # Remove tarball installation
        local install_dir="$HOME/.local/share/google-cloud-sdk"
        if [ -d "$install_dir" ]; then
            rm -rf "$install_dir"
            log_debug "Removido diretório $install_dir"
        fi
    fi

    # Remove from shell configuration
    local shell_config=$(detect_shell_config)
    if [ -f "$shell_config" ]; then
        # Remove Google Cloud SDK PATH lines
        sed -i.bak '/# Google Cloud SDK/d' "$shell_config" 2> /dev/null ||
            sed -i '' '/# Google Cloud SDK/d' "$shell_config" 2> /dev/null

        sed -i.bak '/google-cloud-sdk\/bin/d' "$shell_config" 2> /dev/null ||
            sed -i '' '/google-cloud-sdk\/bin/d' "$shell_config" 2> /dev/null

        rm -f "${shell_config}.bak"
        log_debug "Removido PATH do $shell_config"
    fi

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "gcloud"

        log_success "Google Cloud SDK desinstalado com sucesso!"
        log_output ""
        log_output "Reinicie o terminal para aplicar as mudanças no PATH"
    else
        log_error "Falha ao desinstalar Google Cloud SDK completamente"
        log_output "Você pode precisar remover manualmente:"
        log_output "  - Diretório: $HOME/.local/share/google-cloud-sdk"
        log_output "  - Entradas no PATH em: $shell_config"
        return 1
    fi

    # Ask about removing configurations and credentials
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as configurações e credenciais? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            log_debug "Removendo configurações do gcloud..."
            rm -rf "$HOME/.config/gcloud" 2> /dev/null || true
            log_debug "Configurações removidas: ~/.config/gcloud"
            rm -rf "$HOME/.gsutil" 2> /dev/null || true
            log_debug "Configurações removidas: ~/.gsutil"
            log_success "Configurações removidas"
        else
            log_info "Configurações mantidas em ~/.config/gcloud"
        fi
    else
        # Auto-remove when --yes is used
        log_debug "Removendo configurações do gcloud automaticamente..."
        rm -rf "$HOME/.config/gcloud" 2> /dev/null || true
        log_debug "Configurações removidas: ~/.config/gcloud"
        rm -rf "$HOME/.gsutil" 2> /dev/null || true
        log_debug "Configurações removidas: ~/.gsutil"
        log_info "Configurações removidas automaticamente"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
