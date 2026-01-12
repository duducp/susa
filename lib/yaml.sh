#!/bin/bash

# ============================================================
# YAML Parser para Shell Script usando yq
# ============================================================
# Parser para ler configurações YAML (centralizadas e descentralizadas)

# Obtém o diretório da lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source registry lib
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/dependencies.sh"

# Garante que yq está instalado
ensure_yq_installed || {
    echo "Erro: yq é necessário para o Susa CLI funcionar" >&2
    exit 1
}

# --- Funções para Config Global (cli.yaml) ---

# Função para obter campos globais do YAML (name, description, version)
get_yaml_global_field() {
    local yaml_file="$1"
    local field="$2"  # name, description, version, commands_dir, plugins_dir
    
    if [ ! -f "$yaml_file" ]; then
        return 1
    fi
    
    yq eval ".$field" "$yaml_file" 2>/dev/null
}

# Função para ler categorias do YAML
parse_yaml_categories() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        return 1
    fi
    
    # Extrai nomes das categorias usando yq
    yq eval '.categories | keys | .[]' "$yaml_file" 2>/dev/null
}

# Descobre categorias/subcategorias automaticamente da estrutura de diretórios
# Retorna apenas categorias de nível 1 (diretórios diretos em commands/ e plugins/)
discover_categories() {
    local cli_dir="${CLI_DIR:-$(dirname "$YAML_CONFIG")}"
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    local categories=""
    
    # Busca em commands/ (apenas primeiro nível)
    if [ -d "$commands_dir" ]; then
        for cat_dir in "$commands_dir"/*; do
            [ ! -d "$cat_dir" ] && continue
            local cat_name=$(basename "$cat_dir")
            categories="${categories}${cat_name}"$'\n'
        done
    fi
    
    # Busca em plugins/ (apenas primeiro nível de cada plugin)
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignora arquivos especiais
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            # Adiciona as categorias de primeiro nível deste plugin
            for cat_dir in "$plugin_dir"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")
                categories="${categories}${cat_name}"$'\n'
            done
        done
    fi
    
    # Remove duplicatas e linhas vazias
    echo "$categories" | grep -v '^$' | sort -u
}

# Obtém todas as categorias (YAML + descobertas)
get_all_categories() {
    local yaml_file="$1"
    local categories=""
    
    # Primeiro, tenta do YAML (opcional)
    if [ -f "$yaml_file" ]; then
        categories=$(parse_yaml_categories "$yaml_file" 2>/dev/null || true)
    fi
    
    # Depois, descobre do filesystem
    local discovered=$(discover_categories)
    
    # Combina e remove duplicatas
    echo -e "${categories}\n${discovered}" | grep -v '^$' | sort -u
}

# Função para obter informações de uma categoria ou subcategoria
get_category_info() {
    local yaml_file="$1"
    local category="$2"
    local field="$3"  # name ou description
    
    local cli_dir="${CLI_DIR:-$(dirname "$yaml_file")}"
    
    # Tenta ler do config.yaml da categoria/subcategoria em commands/
    local category_config="$cli_dir/commands/$category/config.yaml"
    if [ -f "$category_config" ]; then
        local value=$(yq eval ".$field" "$category_config" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Busca em plugins/ se não encontrou em commands/
    if [ -d "$cli_dir/plugins" ]; then
        for plugin_dir in "$cli_dir/plugins"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignora arquivos especiais
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            category_config="$plugin_dir/$category/config.yaml"
            if [ -f "$category_config" ]; then
                local value=$(yq eval ".$field" "$category_config" 2>/dev/null)
                if [ -n "$value" ] && [ "$value" != "null" ]; then
                    echo "$value"
                    return 0
                fi
            fi
        done
    fi
}

# --- Funções para Discovery de Comandos e Subcategorias (baseado em script executável) ---

# Verifica se um diretório é um comando (tem script executável)
is_command_dir() {
    local item_dir="$1"
    
    # Verifica se tem config.yaml
    [ ! -f "$item_dir/config.yaml" ] && return 1
    
    # Lê o campo script do config.yaml usando yq
    local script_name=$(yq eval '.script' "$item_dir/config.yaml" 2>/dev/null)
    
    # Se tem campo script e o arquivo existe, é um comando
    if [ -n "$script_name" ] && [ "$script_name" != "null" ] && [ -f "$item_dir/$script_name" ]; then
        return 0
    fi
    
    return 1
}

# Descobre comandos e subcategorias em um caminho (categoria pode ser aninhada)
# Retorna: comandos (diretórios com script) e subcategorias (diretórios sem script)
discover_items_in_category() {
    local base_dir="$1"
    local category_path="$2"  # Pode ser "install", "install/python", etc.
    local type="${3:-all}"     # "commands", "subcategories", ou "all"
    
    local full_path="$base_dir/$category_path"
    
    if [ ! -d "$full_path" ]; then
        return 0
    fi
    
    # Lista diretórios no nível atual
    for item_dir in "$full_path"/*; do
        [ ! -d "$item_dir" ] && continue
        
        local item_name=$(basename "$item_dir")
        
        # Verifica se é um comando (tem script executável)
        if is_command_dir "$item_dir"; then
            if [ "$type" = "commands" ] || [ "$type" = "all" ]; then
                echo "command:$item_name"
            fi
        else
            # Se não é comando, é uma subcategoria
            if [ "$type" = "subcategories" ] || [ "$type" = "all" ]; then
                echo "subcategory:$item_name"
            fi
        fi
    done
}

# Obtém comandos de uma categoria (pode ser aninhada como "install/python")
get_category_commands() {
    local cli_dir="${CLI_DIR:-$(dirname "$YAML_CONFIG")}"
    local category="$1"
    
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    # Busca em commands/
    if [ -d "$commands_dir" ]; then
        discover_items_in_category "$commands_dir" "$category" "commands" | sed 's/^command://'
    fi
    
    # Busca em plugins/
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignora arquivos especiais
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            discover_items_in_category "$plugin_dir" "$category" "commands" | sed 's/^command://'
        done
    fi
}

# Obtém subcategorias de uma categoria
get_category_subcategories() {
    local cli_dir="${CLI_DIR:-$(dirname "$YAML_CONFIG")}"
    local category="$1"
    
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    local subcategories=""
    
    # Busca em commands/
    if [ -d "$commands_dir" ]; then
        subcategories=$(discover_items_in_category "$commands_dir" "$category" "subcategories" | sed 's/^subcategory://')
    fi
    
    # Busca em plugins/
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignora arquivos especiais
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            local plugin_subcats=$(discover_items_in_category "$plugin_dir" "$category" "subcategories" | sed 's/^subcategory://')
            [ -n "$plugin_subcats" ] && subcategories="${subcategories}"$'\n'"${plugin_subcats}"
        done
    fi
    
    # Remove duplicatas e linhas vazias
    echo "$subcategories" | grep -v '^$' | sort -u
}

# ============================================================
# LEGACY - Mantido para compatibilidade
# ============================================================

# Descobre comandos em um diretório lendo campo 'id' dos config.yaml
discover_commands_in_dir() {
    local base_dir="$1"
    local category="$2"
    
    if [ ! -d "$base_dir" ]; then
        return 0
    fi
    
    # Função legada - não usada mais
    return 1
}

# --- Funções para ler Config de Comando Individual ---

# Lê um campo da config de um comando
get_command_config_field() {
    local config_file="$1"
    local field="$2"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    local value=$(yq eval ".$field" "$config_file" 2>/dev/null)
    
    # Se for array ou lista, converte para formato compatível
    if echo "$value" | grep -q '^\['; then
        echo "$value" | sed 's/\[//g' | sed 's/\]//g' | sed 's/, /,/g'
    elif [ "$value" != "null" ]; then
        echo "$value"
    fi
}

# Encontra o arquivo de config de um comando baseado no caminho de diretórios
find_command_config() {
    local category="$1"       # Pode ser "install" ou "install/python"
    local command_id="$2"
    local cli_dir="${CLI_DIR:-$(dirname "$YAML_CONFIG")}"
    
    # Busca em commands/
    local config_path="$cli_dir/commands/$category/$command_id/config.yaml"
    if [ -f "$config_path" ]; then
        echo "$config_path"
        return 0
    fi
    
    # Busca em plugins/
    if [ -d "$cli_dir/plugins" ]; then
        for plugin_dir in "$cli_dir/plugins"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignora arquivos especiais
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            config_path="$plugin_dir/$category/$command_id/config.yaml"
            if [ -f "$config_path" ]; then
                echo "$config_path"
                return 0
            fi
        done
    fi
    
    return 1
}

# Obtém informação de um comando específico
get_command_info() {
    local yaml_file="$1"  # Mantido para compatibilidade, mas não usado
    local category="$2"
    local command_id="$3"
    local field="$4"  # name, description, script, sudo, os, group
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    get_command_config_field "$config_file" "$field"
}

# Função para verificar se comando é compatível com o SO atual
is_command_compatible() {
    local yaml_file="$1"  # Mantido para compatibilidade
    local category="$2"
    local command_id="$3"
    local current_os="$4"  # linux ou mac
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    local supported_os=$(get_command_config_field "$config_file" "os")
    
    # Se não tem restrição de OS, é compatível
    if [ -z "$supported_os" ]; then
        return 0
    fi
    
    # Verifica se o OS atual está na lista
    if echo "$supported_os" | grep -qw "$current_os"; then
        return 0
    fi
    
    return 1
}

# Função para verificar se comando requer sudo
requires_sudo() {
    local yaml_file="$1"  # Mantido para compatibilidade
    local category="$2"
    local command_id="$3"
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    local needs_sudo=$(get_command_config_field "$config_file" "sudo")
    
    if [ "$needs_sudo" = "true" ]; then
        return 0
    fi
    
    return 1
}

# Função para obter o grupo de um comando
get_command_group() {
    local yaml_file="$1"  # Mantido para compatibilidade
    local category="$2"
    local command_id="$3"
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 0
    fi
    
    get_command_config_field "$config_file" "group"
}

# Função para obter lista única de grupos em uma categoria
get_category_groups() {
    local yaml_file="$1"  # Mantido para compatibilidade
    local category="$2"
    local current_os="$3"
    
    local commands=$(get_category_commands "$category")
    local groups=""
    
    for cmd in $commands; do
        # Pula comandos incompatíveis
        if ! is_command_compatible "$yaml_file" "$category" "$cmd" "$current_os"; then
            continue
        fi
        
        local group=$(get_command_group "$yaml_file" "$category" "$cmd")
        
        if [ -n "$group" ]; then
            # Adiciona grupo se ainda não estiver na lista
            if ! echo "$groups" | grep -qw "$group"; then
                groups="${groups}${group}"$'\n'
            fi
        fi
    done
    
    echo "$groups" | grep -v '^$'
}


