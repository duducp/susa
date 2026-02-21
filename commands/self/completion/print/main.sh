#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/shell.sh"

# Source completion generators
source "$(dirname "$0")/../generators/bash.sh"
source "$(dirname "$0")/../generators/zsh.sh"
source "$(dirname "$0")/../generators/fish.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Imprime o script de autocompletar sem instalá-lo."
    log_output "  Útil para inspecionar ou copiar manualmente."
    log_output ""
    log_output "${LIGHT_GREEN}Shells suportados:${NC}"
    log_output "  bash              Imprime completion para Bash"
    log_output "  zsh               Imprime completion para Zsh"
    log_output "  fish              Imprime completion para Fish"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self completion print bash         # Imprime script bash"
    log_output "  susa self completion print zsh          # Imprime script zsh"
    log_output "  susa self completion print fish         # Imprime script fish"
}

# Main function
main() {
    local shell_type=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            bash | zsh | fish)
                shell_type="$1"
                shift
                ;;
            *)
                log_error "Argumento inválido: $1"
                log_output ""
                log_output "Use: ${LIGHT_CYAN}susa self completion print [bash|zsh|fish]${NC}"
                return 1
                ;;
        esac
    done

    # Se não especificou shell, mostra o help
    if [ -z "$shell_type" ]; then
        export SUSA_SHOW_HELP=1
        display_help
        return 0
    fi

    # Execute print
    case "$shell_type" in
        bash)
            generate_bash_completion
            ;;
        zsh)
            generate_zsh_completion
            ;;
        fish)
            generate_fish_completion
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            return 1
            ;;
    esac
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
