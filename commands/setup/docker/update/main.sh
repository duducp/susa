#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

main() {
    # Check if Docker is installed
    if ! check_installation; then
        log_error "Docker não está instalado. Use 'susa setup docker install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)

    # Get latest version
    local docker_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$docker_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$docker_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando Docker..."

    # Detect OS and update
    if is_mac; then
        if ! homebrew_is_available; then
            log_error "Homebrew não está instalado"
            return 1
        fi

        homebrew_update_formula "docker" "Docker" || {
            log_error "Falha ao atualizar Docker"
            return 1
        }

        # Update docker-compose if installed
        if homebrew_is_installed_formula "docker-compose"; then
            homebrew_update_formula "docker-compose" "docker-compose" || log_debug "docker-compose já está atualizado"
        fi
    else
        # Detect Linux distribution
        local distro=$(get_distro_id)
        log_debug "Distribuição detectada: $distro"

        case "$distro" in
            ubuntu | debian | pop | linuxmint)
                sudo apt-get update > /dev/null 2>&1
                sudo apt-get install --only-upgrade -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin > /dev/null 2>&1
                ;;
            fedora | rhel | centos | rocky | almalinux)
                sudo dnf upgrade -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin > /dev/null 2>&1
                ;;
            arch | manjaro)
                sudo pacman -Syu --noconfirm docker docker-compose > /dev/null 2>&1
                ;;
            *)
                log_error "Distribuição não suportada: $distro"
                return 1
                ;;
        esac
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "docker" "$new_version"

        log_success "Docker atualizado com sucesso para versão $new_version!"
    else
        log_error "Falha na atualização do Docker"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
