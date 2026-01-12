#!/bin/bash

# ============================================================
# Plugin Helper Functions
# ============================================================
# Funções compartilhadas para gerenciamento de plugins

# Obtém o diretório da lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Plugin Helper Functions ---

# Verifica se git está instalado
ensure_git_installed() {
    if ! command -v git &>/dev/null; then
        log_error "Git não encontrado. Instale git primeiro."
        return 1
    fi
    return 0
}

# Detecta versão de um plugin no diretório
detect_plugin_version() {
    local plugin_dir="$1"
    local version="1.0.0"
    
    if [ -f "$plugin_dir/version.txt" ]; then
        version=$(cat "$plugin_dir/version.txt" | tr -d '\n')
    elif [ -f "$plugin_dir/VERSION" ]; then
        version=$(cat "$plugin_dir/VERSION" | tr -d '\n')
    fi
    
    echo "$version"
}

# Conta comandos de um plugin
count_plugin_commands() {
    local plugin_dir="$1"
    find "$plugin_dir" -name "config.yaml" -type f | wc -l
}

# Clona plugin de um repositório Git
clone_plugin() {
    local url="$1"
    local dest_dir="$2"
    
    if git clone "$url" "$dest_dir" 2>&1; then
        # Remove .git para economizar espaço
        rm -rf "$dest_dir/.git"
        return 0
    else
        return 1
    fi
}

# Converte user/repo para URL completa do GitHub
normalize_git_url() {
    local url="$1"
    
    # Se for formato user/repo, converte para URL completa
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo "https://github.com/${url}.git"
    else
        echo "$url"
    fi
}

# Extrai nome do plugin da URL
extract_plugin_name() {
    local url="$1"
    basename "$url" .git
}
