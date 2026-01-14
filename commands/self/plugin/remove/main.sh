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
    show_usage "<plugin-name>"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Remove um plugin instalado do Susa CLI, incluindo"
    echo "  todos os seus comandos e registro no sistema."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -v, --verbose     Modo verbose (debug)"
    echo "  -q, --quiet       Modo silencioso (mínimo de output)"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin remove backup-tools    # Remove o plugin backup-tools"
    echo "  susa self plugin remove --help          # Exibe esta ajuda"
    echo ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"

    log_debug "=== Iniciando remoção de plugin ==="
    log_debug "Plugin: $PLUGIN_NAME"
    log_debug "Diretório de plugins: $PLUGINS_DIR"

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

    # Confirm removal
    echo -e "${YELLOW}Atenção:${NC} Você está prestes a remover o plugin '$PLUGIN_NAME'"
    echo ""

    # List commands that will be removed
    log_debug "Contando comandos que serão removidos"
    local cmd_count=$(find "$PLUGINS_DIR/$PLUGIN_NAME" -name "config.yaml" -type f | wc -l)
    echo -e "Comandos que serão removidos: ${GRAY}$cmd_count${NC}"
    log_debug "Total de comandos: $cmd_count"
    echo ""

    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Operação cancelada"
        log_debug "Usuário cancelou a remoção"
        exit 0
    fi
    log_debug "Usuário confirmou a remoção"

    # Remove o plugin
    log_info "Removendo plugin '$PLUGIN_NAME'..."
    log_debug "Removendo diretório: $PLUGINS_DIR/$PLUGIN_NAME"

    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    if rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"; then
        log_debug "Diretório removido com sucesso"

        # Remove from registry too
        log_debug "Removendo do registry"
        if [ -f "$REGISTRY_FILE" ]; then
            log_debug "Registry file: $REGISTRY_FILE"
            registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
            log_debug "Plugin removido do registry.yaml"
        else
            log_debug "Registry file não existe"
        fi

        log_success "Plugin '$PLUGIN_NAME' removido com sucesso!"

        # Update lock file if it exists
        log_debug "Atualizando lock file"
        update_lock_file
        log_debug "=== Remoção concluída ==="
    else
        log_error "Falha ao remover o plugin"
        log_debug "Erro ao executar rm -rf"
        exit 1
    fi
}

# Parse arguments first, before running main
require_arguments "$@"

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
        *)
            # Argument is the name of the plugin
            PLUGIN_ARG="$1"
            shift
            break
            ;;
    esac
done

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name>"

# Execute main function
main "$PLUGIN_ARG"
