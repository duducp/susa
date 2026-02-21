#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/shell.sh"
source "$LIB_DIR/internal/completion.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Remove scripts de autocompletar do shell especificado."
    log_output ""
    log_output "${LIGHT_GREEN}Shells suportados:${NC}"
    log_output "  bash              Remove completion do Bash"
    log_output "  zsh               Remove completion do Zsh"
    log_output "  fish              Remove completion do Fish"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self completion uninstall          # Remove de todos os shells"
    log_output "  susa self completion uninstall bash     # Remove apenas do bash"
    log_output "  susa self completion uninstall zsh      # Remove apenas do zsh"
    log_output "  susa self completion uninstall fish     # Remove apenas do fish"
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
                log_output "Use: ${LIGHT_CYAN}susa self completion uninstall [bash|zsh|fish]${NC}"
                return 1
                ;;
        esac
    done

    # Execute uninstallation
    gum_spin_start "Removendo autocompletar..."

    # Se não especificou shell, remove de todos instalados
    if [ -z "$shell_type" ]; then
        local removed_count=0
        local shells_to_remove=()

        # Detecta shells com autocompletar instalado
        if is_completion_installed "bash"; then
            shells_to_remove+=("bash")
        fi

        if is_completion_installed "zsh"; then
            shells_to_remove+=("zsh")
        fi

        if is_completion_installed "fish"; then
            shells_to_remove+=("fish")
        fi

        if [ ${#shells_to_remove[@]} -eq 0 ]; then
            gum_spin_stop
            log_warning "Nenhum autocompletar instalado encontrado"
            return 0
        fi

        # Formata lista de shells encontrados em uma linha
        local shells_list=$(printf '%s, ' "${shells_to_remove[@]}" | sed 's/, $//')
        gum_spin_update "Removendo autocompletar dos shells $shells_list..."

        # Remove autocompletar de cada shell encontrado
        for shell in "${shells_to_remove[@]}"; do
            local completion_file=$(get_completion_file_path "$shell")

            if rm "$completion_file" 2> /dev/null; then
                removed_count=$((removed_count + 1))
            fi
        done

        sleep 0.5 # Pequena pausa para suavizar a transição
        gum_spin_stop

        if [ $removed_count -gt 0 ]; then
            # Limpa cache do zsh se foi removido
            if [[ " ${shells_to_remove[*]} " =~ " zsh " ]]; then
                setopt LOCAL_OPTIONS NULL_GLOB
                rm -f ~/.zcompdump* 2> /dev/null
            fi

            log_output "${BOLD}${LIGHT_GREEN}✅ Autocompletar removido com sucesso!${NC}"
            log_output ""
            log_output "${BOLD}🔄 Próximos passos:${NC}"
            log_output "  • Abra um novo terminal para aplicar as mudanças"
            log_output "  • Ou execute ${LIGHT_CYAN}exec \$SHELL${NC} no terminal atual"
        else
            log_error "Nenhum autocompletar foi removido"
            return 1
        fi

        return 0
    fi

    # Se especificou um shell, remove apenas dele
    case "$shell_type" in
        bash | zsh | fish)
            if ! is_completion_installed "$shell_type"; then
                log_warning "Autocompletar para $shell_type não está instalado"
                return 0
            fi

            local completion_file=$(get_completion_file_path "$shell_type")
            log_info "Removendo autocompletar do $shell_type..."

            if rm "$completion_file" 2> /dev/null; then
                # Limpa cache do zsh se necessário
                if [ "$shell_type" = "zsh" ]; then
                    setopt LOCAL_OPTIONS NULL_GLOB
                    rm -f ~/.zcompdump* 2> /dev/null
                fi

                log_success "Autocompletar do $shell_type removido com sucesso!"
                log_output ""
                log_output "${LIGHT_YELLOW}Nota:${NC} Reinicie o terminal para aplicar as mudanças"
                return 0
            else
                log_error "Erro ao remover completion do $shell_type"
                return 1
            fi
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            return 1
            ;;
    esac
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
