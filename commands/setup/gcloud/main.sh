#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional gcloud-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Show configured account
    local account=$($GCLOUD_BIN_NAME config get-value account 2> /dev/null || echo "não configurado")
    log_output "  ${CYAN}Conta:${NC} $account"

    # Show configured project
    local project=$($GCLOUD_BIN_NAME config get-value project 2> /dev/null || echo "não configurado")
    log_output "  ${CYAN}Projeto:${NC} $project"

    # Show configured region (try region first, then zone)
    local region=$($GCLOUD_BIN_NAME config get-value compute/region 2> /dev/null)
    if [ -z "$region" ]; then
        local zone=$($GCLOUD_BIN_NAME config get-value compute/zone 2> /dev/null)
        if [ -n "$zone" ]; then
            region="$zone (zona)"
        else
            region="não configurado"
        fi
    fi
    log_output "  ${CYAN}Região:${NC} $region"

    # Show available components
    log_output "  ${CYAN}Componentes:${NC} $($GCLOUD_BIN_NAME components list --filter="state.name=Installed" --format="value(id)" 2> /dev/null | wc -l | xargs) instalados"
}

# Optional - Additional information in help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $GCLOUD_NAME ($GCLOUD_BIN_NAME) é um conjunto de ferramentas de linha"
    log_output "  de comando para gerenciar recursos e aplicações hospedadas no"
    log_output "  Google Cloud Platform. Inclui $GCLOUD_BIN_NAME, gsutil e bq."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gcloud install              # Instala o $GCLOUD_NAME"
    log_output "  susa setup gcloud update               # Atualiza o gcloud"
    log_output "  susa setup gcloud uninstall            # Desinstala o gcloud"
    log_output "  susa setup gcloud --info               # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output ""
    log_output "  Autentique-se com:"
    log_output "    gcloud init"
    log_output "    gcloud auth login"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  gcloud --version               # Verifica a instalação"
    log_output "  gcloud projects list           # Lista projetos GCP"
    log_output "  gcloud config set project <ID> # Define o projeto GCP ativo"
    log_output "  gcloud components install kubectl # Instala o kubectl via gcloud"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "gcloud" "$GCLOUD_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup gcloud --help${NC} para ver opções"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
