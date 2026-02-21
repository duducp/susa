#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/shell.sh"
source "$LIB_DIR/internal/completion.sh"

# Source completion generators
source "$(dirname "$0")/../generators/bash.sh"
source "$(dirname "$0")/../generators/zsh.sh"
source "$(dirname "$0")/../generators/fish.sh"

# Source installers
source "$(dirname "$0")/../installers.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Instala scripts de autocompletar (tab completion) para seu shell."
    log_output "  O autocompletar sugere categorias, comandos e subcategorias automaticamente."
    log_output ""
    log_output "${LIGHT_GREEN}Shells suportados:${NC}"
    log_output "  bash              Instala completion para Bash"
    log_output "  zsh               Instala completion para Zsh"
    log_output "  fish              Instala completion para Fish"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self completion install            # Instala em todos os shells disponíveis"
    log_output "  susa self completion install bash       # Instala apenas no bash"
    log_output "  susa self completion install zsh        # Instala apenas no zsh"
    log_output "  susa self completion install fish       # Instala apenas no fish"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, abra um novo terminal ou execute:"
    log_output "    ${LIGHT_CYAN}exec \$SHELL${NC}"
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
                log_output "Use: ${LIGHT_CYAN}susa self completion install [bash|zsh|fish]${NC}"
                return 1
                ;;
        esac
    done

    # Execute installation
    gum_spin_start "Instalando autocompletar..."

    # Se não especificou shell, instala em todos disponíveis
    if [ -z "$shell_type" ]; then
        local shells_to_install=()
        local installed_count=0
        local already_installed_count=0
        local active_in_session=()
        local needs_reload=()

        # Detecta shells disponíveis silenciosamente
        if command -v bash > /dev/null 2>&1; then
            shells_to_install+=("bash")
        fi

        if command -v zsh > /dev/null 2>&1; then
            shells_to_install+=("zsh")
        fi

        if command -v fish > /dev/null 2>&1; then
            shells_to_install+=("fish")
        fi

        if [ ${#shells_to_install[@]} -eq 0 ]; then
            gum_spin_stop
            log_error "Nenhum shell suportado encontrado no sistema"
            return 1
        fi

        # Instala completion para cada shell encontrado
        gum_spin_update "Instalando completion para $(printf '%s, ' "${shells_to_install[@]}" | sed 's/, $//')..."

        for shell in "${shells_to_install[@]}"; do
            local result=0

            # Captura código de retorno sem falhar com set -e
            case "$shell" in
                bash) install_bash_completion > /dev/null 2>&1 || result=$? ;;
                zsh) install_zsh_completion > /dev/null 2>&1 || result=$? ;;
                fish) install_fish_completion > /dev/null 2>&1 || result=$? ;;
            esac

            # Processa resultado
            case $result in
                0)
                    # Instalado com sucesso
                    installed_count=$((installed_count + 1))
                    needs_reload+=("$shell")
                    ;;
                2)
                    # Já estava instalado
                    already_installed_count=$((already_installed_count + 1))
                    ;;
                *)
                    # Erro
                    gum_spin_stop
                    log_debug "Erro ao instalar autocompletar para $shell"
                    ;;
            esac
        done

        sleep 0.5 # Pequena pausa para suavizar a transição
        gum_spin_stop

        # Exibe resumo
        log_output "${BOLD}${LIGHT_GREEN}✅ Instalação concluída!${NC}"
        log_output ""
        log_output "${BOLD}📦 Resumo da instalação:${NC}"

        # Shells instalados
        if [ $installed_count -gt 0 ]; then
            log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}$installed_count${NC} shell(s) configurado(s) com sucesso"
        fi

        # Shells já instalados
        if [ $already_installed_count -gt 0 ]; then
            log_output "  ${LIGHT_BLUE}ℹ${NC}  ${BOLD}$already_installed_count${NC} shell(s) já tinha(m) autocompletar instalado"
        fi

        # Instruções de ativação
        if [ ${#needs_reload[@]} -gt 0 ]; then
            log_output ""
            log_output "${BOLD}🔄 Para ativar:${NC}"
            log_output "   Abra um novo terminal ou execute ${LIGHT_CYAN}exec \$SHELL${NC}"
        fi

        return 0
    fi

    # Se especificou um shell, instala apenas nele
    case "$shell_type" in
        bash | zsh | fish)
            local result=0

            gum_spin_start "Instalando autocompletar para $shell_type..."

            case "$shell_type" in
                bash)
                    install_bash_completion > /dev/null 2>&1 || result=$?
                    ;;
                zsh)
                    install_zsh_completion > /dev/null 2>&1 || result=$?
                    ;;
                fish)
                    install_fish_completion > /dev/null 2>&1 || result=$?
                    ;;
            esac

            sleep 0.5 # Pequena pausa para suavizar a transição
            gum_spin_stop

            case $result in
                0)
                    log_success "Autocompletar instalado com sucesso!"
                    log_output ""
                    log_output "${BOLD}🔄 Para ativar:${NC}"
                    log_output "  • Abra um novo terminal ou execute: ${LIGHT_CYAN}exec $shell_type${NC}"
                    log_output ""
                    return 0
                    ;;
                2)
                    log_warning "Autocompletar já está instalado"
                    log_output "${LIGHT_YELLOW}Para reinstalar:${NC} ${LIGHT_CYAN}susa self completion uninstall $shell_type${NC}"
                    return 1
                    ;;
                *)
                    log_error "Erro ao instalar autocompletar"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            log_output "${LIGHT_YELLOW}Shells suportados:${NC} bash, zsh, fish"
            return 1
            ;;
    esac
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
