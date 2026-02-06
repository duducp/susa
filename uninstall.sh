#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =================
# CLI Uninstaller
# =================

CLI_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/core/cli.json"
CLI_NAME="susa"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Detects the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
else
    OS_TYPE="Linux"
fi

INSTALL_DIR="$HOME/.local/bin"
INSTALL_BASE="$HOME/.local/susa"

echo ""
echo -e "${BOLD}${RED}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${RED}║                                        ║${NC}"
echo -e "${BOLD}${RED}║     🗑️  Susa CLI Uninstaller 🗑️        ║${NC}"
echo -e "${BOLD}${RED}║                                        ║${NC}"
echo -e "${BOLD}${RED}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DIM}  Removendo Susa CLI do sistema...${NC}"
echo ""

# List installed plugins if CLI is available
if [ -x "$CLI_SOURCE_DIR/core/susa" ]; then
    echo -e "${BOLD}${YELLOW}⚠️  Itens que serão removidos:${NC}"
    echo ""
    echo -e "${DIM}  • Arquivos core do Susa CLI${NC}"
    echo -e "${DIM}  • Executável (~/.local/bin/susa)${NC}"
    echo -e "${DIM}  • Autocompletar (shell completions)${NC}"

    # Check for plugins
    plugin_output=$("$CLI_SOURCE_DIR/core/susa" self plugin list 2> /dev/null || echo "")
    if [ -n "$plugin_output" ] && ! echo "$plugin_output" | grep -q "Nenhum plugin instalado"; then
        echo -e "${DIM}  • Plugins instalados:${NC}"
        echo ""
        echo "$plugin_output" | sed 's/^/    /'
        echo ""
    else
        echo -e "${DIM}  • Nenhum plugin instalado${NC}"
        echo ""
    fi
else
    echo -e "${BOLD}${YELLOW}⚠️  Itens que serão removidos:${NC}"
    echo ""
    echo -e "${DIM}  • Todos os arquivos em ~/.local/susa${NC}"
    echo -e "${DIM}  • Executável ~/.local/bin/susa${NC}"
    echo -e "${DIM}  • Configurações de autocompletar${NC}"
    echo ""
fi

# Confirmation prompt
echo -e "${BOLD}${RED}Deseja realmente desinstalar o Susa CLI?${NC}"
echo -n "Digite 'sim' para confirmar: "

# Read from terminal, handling both direct execution and pipe mode
response=""
if [ -t 0 ]; then
    read -r response || true
else
    read -r response < /dev/tty 2> /dev/null || true
fi
echo ""

response="${response:-}" # Set default empty if unset

if [ "$response" != "sim" ] && [ "$response" != "Sim" ] && [ "$response" != "SIM" ]; then
    echo -e "${YELLOW}⚠️  Desinstalação cancelada${NC}"
    echo ""
    exit 0
fi

echo -e "${CYAN}Prosseguindo com a desinstalação...${NC}"
echo ""

# Remove completion using existing command
if [ -x "$CLI_SOURCE_DIR/core/susa" ]; then
    echo -e "${CYAN}→ Removendo autocompletar...${NC}"
    if "$CLI_SOURCE_DIR/core/susa" self completion --uninstall 2>&1 | grep -q "removido com sucesso"; then
        echo -e "  ${GREEN}✓${NC} Autocompletar removido"
    fi
fi

# Remove the symbolic link
if [ -L "$INSTALL_DIR/$CLI_NAME" ]; then
    echo -e "${CYAN}→ Removendo executável...${NC}"
    rm "$INSTALL_DIR/$CLI_NAME"
    echo -e "  ${GREEN}✓${NC} Executável removido de ${BOLD}$INSTALL_DIR/$CLI_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  Executável não encontrado em${NC} ${BOLD}$INSTALL_DIR${NC}"
fi

# Remove installation directory
if [ -d "$INSTALL_BASE" ]; then
    echo -e "${CYAN}→ Removendo arquivos de instalação...${NC}"
    rm -rf "$INSTALL_BASE"
    echo -e "  ${GREEN}✓${NC} Arquivos removidos de ${BOLD}$INSTALL_BASE${NC}"
else
    echo -e "${YELLOW}⚠️  Diretório de instalação não encontrado em${NC} ${BOLD}$INSTALL_BASE${NC}"
fi

echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  ✓ Susa CLI desinstalado com sucesso!${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${DIM}💡 Todos os arquivos foram removidos${NC}"
echo ""
echo -e "${YELLOW}🔄 Reinicie o terminal para aplicar todas as mudanças${NC}"
echo ""
