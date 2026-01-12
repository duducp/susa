#!/bin/bash

# ============================================================
# Plugin Registry Management
# ============================================================
# Funções para gerenciar o arquivo registry.yaml de plugins

# Obtém o diretório da lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Registry Helper Functions ---

# Adiciona um plugin ao registry
registry_add_plugin() {
    local registry_file="$1"
    local plugin_name="$2"
    local source_url="$3"
    local version="${4:-1.0.0}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Cria arquivo se não existir
    if [ ! -f "$registry_file" ]; then
        cat > "$registry_file" << EOF
# Plugin Registry
version: "1.0.0"

plugins: []
EOF
    fi
    
    # Verifica se plugin já existe
    if grep -q "name: \"$plugin_name\"" "$registry_file" 2>/dev/null; then
        return 1
    fi
    
    # Cria entrada temporária
    local temp_entry="  - name: \"$plugin_name\"
    source: \"$source_url\"
    version: \"$version\"
    installed_at: \"$timestamp\""
    
    # Se o array está vazio, substitui []
    if grep -q "plugins: \[\]" "$registry_file"; then
        sed -i.bak "s/plugins: \[\]/plugins:\n$temp_entry/" "$registry_file"
        rm -f "${registry_file}.bak"
    else
        # Adiciona ao final do array
        echo "$temp_entry" >> "$registry_file"
    fi
}

# Remove um plugin do registry
registry_remove_plugin() {
    local registry_file="$1"
    local plugin_name="$2"
    
    if [ ! -f "$registry_file" ]; then
        return 1
    fi
    
    # Remove o bloco do plugin (4 linhas agora)
    awk -v plugin="$plugin_name" '
    BEGIN { skip=0 }
    /- name:/ && $0 ~ "\""plugin"\"" { skip=4; next }
    skip > 0 { skip--; next }
    { print }
    ' "$registry_file" > "${registry_file}.tmp"
    
    mv "${registry_file}.tmp" "$registry_file"
}

# Lista todos os plugins do registry
registry_list_plugins() {
    local registry_file="$1"
    
    if [ ! -f "$registry_file" ]; then
        return 0
    fi
    
    awk '
    /- name:/ {
        gsub(/.*name: "|".*/, "")
        name=$0
        getline; gsub(/.*source: "|".*/, ""); source=$0
        getline; gsub(/.*version: "|".*/, ""); version=$0
        getline; gsub(/.*installed_at: "|".*/, ""); installed=$0
        print name"|"source"|"version"|"installed
    }
    ' "$registry_file"
}

# Obtém informação de um plugin específico
registry_get_plugin_info() {
    local registry_file="$1"
    local plugin_name="$2"
    local field="$3"  # source, version, installed_at
    
    if [ ! -f "$registry_file" ]; then
        return 1
    fi
    
    awk -v plugin="$plugin_name" -v fld="$field" '
    BEGIN { found=0 }
    /- name:/ && $0 ~ "\""plugin"\"" { found=1; next }
    found && $0 ~ fld":" {
        gsub(/.*'"$field"': "|".*/, "")
        gsub(/.*'"$field"': /, "")
        print
        exit
    }
    ' "$registry_file"
}
