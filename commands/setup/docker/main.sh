#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Show additional Docker-specific information
show_additional_info() {
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        log_output "  ${CYAN}Daemon:${NC} ${GREEN}Executando${NC}"
    else
        log_output "  ${CYAN}Daemon:${NC} ${RED}Parado${NC}"
    fi

    # Show Docker Compose version if available
    if check_installation; then
        local compose_version=$(docker compose version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$compose_version" ]; then
            log_output "  ${CYAN}Docker Compose:${NC} $compose_version"
        fi
    fi
}

# Optional - Additional information in help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $DOCKER_NAME é a plataforma líder em containers para desenvolvimento,"
    log_output "  empacotamento e execução de aplicações. Esta instalação inclui"
    log_output "  apenas o $DOCKER_NAME CLI e Engine, sem o Docker Desktop."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup docker install              # Instala o $DOCKER_NAME"
    log_output "  susa setup docker update               # Atualiza o $DOCKER_NAME"
    log_output "  susa setup docker uninstall            # Desinstala o $DOCKER_NAME"
    log_output "  susa setup docker --info               # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, faça logout e login novamente para que"
    log_output "  as permissões do grupo docker sejam aplicadas, ou execute:"
    log_output "    newgrp docker"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "docker" "$DOCKER_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup docker --help${NC} para ver opções"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
