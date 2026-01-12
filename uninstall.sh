#!/bin/bash

# ============================================================
# Desinstalador do Susa CLI
# ============================================================

CLI_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/cli.yaml"

# Carrega a biblioteca YAML
source "$CLI_SOURCE_DIR/lib/yaml.sh"

# Lê o nome do CLI do arquivo de configuração
CLI_NAME=$(get_yaml_global_field "$CONFIG_FILE" "command")
if [ -z "$CLI_NAME" ]; then
    CLI_NAME="susa"
fi

# Detecta o sistema operacional
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
else
    OS_TYPE="Linux"
fi

INSTALL_DIR="$HOME/.local/bin"

echo ""
echo "Desinstalador do Susa CLI"
echo "Sistema: $OS_TYPE"
echo ""

# Remove o symlink
if [ -L "$INSTALL_DIR/$CLI_NAME" ]; then
    echo "→ Removendo link simbólico..."
    rm "$INSTALL_DIR/$CLI_NAME"
    echo "✓ Susa CLI desinstalado com sucesso!"
else
    echo "⚠  Susa CLI não está instalado em $INSTALL_DIR"
fi

echo ""
