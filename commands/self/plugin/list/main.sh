#!/bin/bash

# Obtém o diretório do CLI
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PLUGINS_DIR="$CLI_DIR/plugins"

# Source libs
source "$CLI_DIR/lib/color.sh"
source "$CLI_DIR/lib/logger.sh"
source "$CLI_DIR/lib/registry.sh"

echo -e "${BOLD}Plugins Instalados${NC}"
echo ""

if [ ! -d "$PLUGINS_DIR" ]; then
    log_warning "Diretório de plugins não encontrado"
    exit 0
fi

REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

# Encontra todos os plugins
plugin_count=0
for plugin_dir in "$PLUGINS_DIR"/*; do
    [ ! -d "$plugin_dir" ] && continue
    [ "$(basename "$plugin_dir")" = "registry.yaml" ] && continue
    [ "$(basename "$plugin_dir")" = "README.md" ] && continue
    
    plugin_name=$(basename "$plugin_dir")
    
    # Conta comandos do plugin
    cmd_count=$(find "$plugin_dir" -name "config.yaml" -type f | wc -l)
    
    # Lista categorias
    categories=$(find "$plugin_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ', ' | sed 's/,$//')
    
    # Obtém informações do registry se existir
    if [ -f "$REGISTRY_FILE" ]; then
        source_url=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "source")
        version=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "version")
        installed_at=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "installed_at")
    else
        source_url="${GRAY}(não registrado)${NC}"
        version="${GRAY}(desconhecida)${NC}"
        installed_at="${GRAY}(desconhecida)${NC}"
    fi
    
    echo -e "${LIGHT_CYAN}📦 $plugin_name${NC}"
    [ -n "$source_url" ] && echo -e "   Origem: ${GRAY}$source_url${NC}"
    [ -n "$version" ] && echo -e "   Versão: ${GRAY}$version${NC}"
    echo -e "   Comandos: ${GRAY}$cmd_count${NC}"
    echo -e "   Categorias: ${GRAY}$categories${NC}"
    [ -n "$installed_at" ] && echo -e "   Instalado: ${GRAY}$installed_at${NC}"
    echo ""
    
    ((plugin_count++))
done

if [ $plugin_count -eq 0 ]; then
    log_info "Nenhum plugin instalado"
    echo ""
    echo -e "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin install <url>${NC}"
else
    echo -e "${GREEN}Total: $plugin_count plugin(s)${NC}"
fi
