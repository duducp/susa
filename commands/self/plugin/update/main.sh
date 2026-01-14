#!/bin/bash
set -euo pipefail


# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<plugin-name> [opções]"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Baixa novamente o plugin da origem registrada e"
    echo "  substitui a instalação atual pela versão mais recente."
    echo "  Suporta GitHub, GitLab e Bitbucket."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -v, --verbose     Modo verbose (debug)"
    echo "  -q, --quiet       Modo silencioso (mínimo de output)"
    echo "  --ssh         Força uso de SSH (recomendado para repos privados)"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin update backup-tools           # Atualiza o plugin"
    echo "  susa self plugin update private-plugin --ssh   # Força SSH"
    echo "  susa self plugin update --help                 # Exibe esta ajuda"
    echo ""
    echo -e "${GRAY}Nota: O provedor Git é detectado automaticamente da URL registrada.${NC}"
    echo ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    local USE_SSH="${2:-false}"
    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    log_debug "=== Iniciando atualização de plugin ==="
    log_debug "Plugin: $PLUGIN_NAME"
    log_debug "Use SSH: $USE_SSH"
    log_debug "Registry file: $REGISTRY_FILE"

    # Check if the plugin exists
    log_debug "Verificando se plugin existe"
    if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        log_error "Plugin '$PLUGIN_NAME' não encontrado"
        log_debug "Diretório não existe: $PLUGINS_DIR/$PLUGIN_NAME"
        echo ""
        echo -e "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
        exit 1
    fi
    log_debug "Plugin encontrado em: $PLUGINS_DIR/$PLUGIN_NAME"

    # Check if registry exists
    log_debug "Verificando se registry existe"
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "Registry não encontrado. Não é possível determinar a origem do plugin."
        log_debug "Registry file não existe: $REGISTRY_FILE"
        echo ""
        echo -e "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin add${NC}"
        exit 1
    fi
    log_debug "Registry encontrado"

    # Gets the registry source URL
    log_debug "Obtendo URL de origem do registry"
    local SOURCE_URL=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source")
    log_debug "Source URL: $SOURCE_URL"

    if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = "local" ]; then
        log_error "Plugin '$PLUGIN_NAME' não tem origem registrada ou é local"
        log_debug "Source URL é vazia ou local"
        echo ""
        echo -e "Apenas plugins instalados via Git podem ser atualizados"
        exit 1
    fi

    # Check if git is installed
    log_debug "Verificando se Git está instalado"
    ensure_git_installed || exit 1

    # Detect provider from source URL
    log_debug "Detectando provider da URL de origem"
    local provider=$(detect_git_provider "$SOURCE_URL")
    log_debug "Provider detectado: $provider"

    # Normalize URL (apply SSH if forced or auto-detected)
    log_debug "Normalizando URL"
    SOURCE_URL=$(normalize_git_url "$SOURCE_URL" "$USE_SSH" "$provider")
    log_debug "URL normalizada: $SOURCE_URL"

    log_debug "Validando acesso ao repositório"
    if ! validate_repo_access "$SOURCE_URL"; then
        log_error "Não foi possível acessar o repositório"
        log_debug "Falha na validação de acesso"
        echo ""
        echo -e "${LIGHT_YELLOW}Possíveis causas:${NC}"
        echo -e "  • Repositório foi removido ou renomeado"
        echo -e "  • Você perdeu acesso ao repositório privado"
        echo -e "  • Credenciais Git não estão mais válidas"
        echo ""
        echo -e "${LIGHT_YELLOW}Soluções:${NC}"
        echo -e "  • Verifique se o repositório ainda existe"
        echo -e "  • Use --ssh se for repositório privado"
        echo -e "  • Reconfigure suas credenciais Git"
        exit 1
    fi
    log_debug "Acesso ao repositório validado"

    log_info "Atualizando plugin: $PLUGIN_NAME"
    echo -e "  ${GRAY}Origem: $SOURCE_URL${NC}"
    echo ""

    # Confirm update
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Operação cancelada"
        log_debug "Usuário cancelou a atualização"
        exit 0
    fi
    log_debug "Usuário confirmou a atualização"

    # Create backup of current plugin
    local BACKUP_DIR="${PLUGINS_DIR}/.backup_${PLUGIN_NAME}_$(date +%s)"
    log_debug "Diretório de backup: $BACKUP_DIR"

    log_info "Criando backup..."
    log_debug "Movendo $PLUGINS_DIR/$PLUGIN_NAME para $BACKUP_DIR"
    mv "$PLUGINS_DIR/$PLUGIN_NAME" "$BACKUP_DIR"
    log_debug "Backup criado"

    # Clones the latest version
    log_info "Baixando versão mais recente de $SOURCE_URL..."
    log_debug "Clonando para: $PLUGINS_DIR/$PLUGIN_NAME"
    if clone_plugin "$SOURCE_URL" "$PLUGINS_DIR/$PLUGIN_NAME"; then
        log_debug "Clone concluído com sucesso"

        # Detect new version
        log_debug "Detectando versão do plugin"
        local NEW_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Nova versão: $NEW_VERSION"

        # Count commands and get categories
        log_debug "Contando comandos"
        local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Total de comandos: $cmd_count"

        log_debug "Obtendo categorias"
        local categories=$(get_plugin_categories "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Categorias: $categories"

        # Update registry (remove and add again with metadata)
        log_debug "Atualizando registry"
        registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$SOURCE_URL" "$NEW_VERSION" "false" "$cmd_count" "$categories"
        log_debug "Registry atualizado"

        # Remove backup
        log_debug "Removendo backup"
        rm -rf "$BACKUP_DIR"
        log_debug "Backup removido"

        echo ""
        log_success "Plugin '$PLUGIN_NAME' atualizado com sucesso!"
        echo -e "  ${GRAY}Nova versão: $NEW_VERSION${NC}"
        echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
        if [ -n "$categories" ]; then
            echo -e "  ${GRAY}Categorias: $categories${NC}"
        fi

        # Update lock file if it exists
        log_debug "Atualizando lock file"
        update_lock_file
        log_debug "=== Atualização concluída ==="
    else
        log_error "Falha ao baixar atualização"
        log_debug "Clone falhou"

        # Restore backup
        log_info "Restaurando versão anterior..."
        log_debug "Restaurando de: $BACKUP_DIR"
        mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"
        log_debug "Versão anterior restaurada"

        exit 1
    fi
}

# Parse arguments first, before running main
require_arguments "$@"

USE_SSH="false"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            export DEBUG=1
            log_debug "Modo verbose ativado"
            shift
            ;;
        -q|--quiet)
            export SILENT=1
            shift
            ;;
        --ssh)
            USE_SSH="true"
            shift
            ;;
        *)
            # Argument is the name of the plugin
            PLUGIN_ARG="$1"
            shift
            ;;
    esac
done

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name> [opções]"

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH"
