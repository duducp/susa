#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

main() {
    # Check if gcloud is installed
    if ! check_installation; then
        log_error "Google Cloud SDK não está instalado. Use 'susa setup gcloud install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Atualizando Google Cloud SDK (versão atual: $current_version)..."

    # Detect OS
    if is_mac; then
        # Check if installed via Homebrew
        if homebrew_is_installed_formula "google-cloud-sdk"; then
            log_info "Atualizando via Homebrew..."
            homebrew_update_formula "google-cloud-sdk" "Google Cloud SDK" || {
                log_warning "Homebrew não atualizou. Tentando gcloud components update..."
                gcloud components update --quiet 2> /dev/null || true
            }
        else
            log_info "Atualizando componentes do gcloud..."
            gcloud components update --quiet || {
                log_error "Falha ao atualizar Google Cloud SDK"
                return 1
            }
        fi
    else
        log_info "Atualizando componentes do gcloud..."
        gcloud components update --quiet || {
            log_error "Falha ao atualizar Google Cloud SDK"
            return 1
        }
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "gcloud" "$new_version"

        if [ "$new_version" != "$current_version" ]; then
            log_success "Google Cloud SDK atualizado de $current_version para $new_version!"
        else
            log_info "Google Cloud SDK já está na versão mais recente ($current_version)"
        fi
    else
        log_error "Falha na atualização do Google Cloud SDK"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
