#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/github.sh"
source "$LIB_DIR/gum.sh"

TEMP_DIR=$(mktemp -d)
TEMP_VERSION_FILE="/tmp/susa_update_check_$$_${RANDOM}"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação e atualiza automaticamente"
    log_output "  -f, --force       Força atualização mesmo se já estiver na versão mais recente"
    log_output ""
    log_output "${LIGHT_GREEN}Como funciona:${NC}"
    log_output "  • Compara a versão atual com a versão mais recente no GitHub"
    log_output "  • Preserva plugins instalados e configurações personalizadas"
    log_output "  • Baixa a nova versão em diretório temporário"
    log_output "  • Atualiza os arquivos mantendo o registry de plugins"
    log_output "  • Remove arquivos temporários automaticamente"
    log_output ""
    log_output "${LIGHT_GREEN}Variáveis de ambiente:${NC}"
    log_output "  CLI_CLI_REPO_URL      URL do repositório (padrão: github.com/duducp/susa)"
    log_output "  CLI_CLI_REPO_BRANCH   Branch a usar (padrão: main)"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self update              # Verifica e atualiza se houver nova versão"
    log_output "  susa self update --force      # Força reinstalação da versão atual"
    log_output "  susa -v self update           # Atualiza com logs de debug"
    log_output "  susa -vv self update          # Debug detalhado"
    log_output "  susa self update --help       # Exibe esta ajuda"
}

# Cleanup function to remove temp directory on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi

    # Remove temp files safely (zsh requires NULL_GLOB to avoid errors on no matches)
    rm -f "$TEMP_VERSION_FILE" 2> /dev/null || true

    # Remove pattern-based temp files only if they exist
    setopt LOCAL_OPTIONS NULL_GLOB
    for file in /tmp/susa_update_$$_*; do
        [ -e "$file" ] && rm -f "$file"
    done
}
trap cleanup EXIT # Execute cleanup on script exit

# Function to get the current version
get_current_version() {
    get_config_field "$GLOBAL_CONFIG_FILE" "version"
}

# Function to get the latest version from the repository
get_latest_version() {
    log_trace "Chamando get_latest_version()"

    # Extract repo from URL (remove https:// and .git)
    local repo="${CLI_REPO_URL#https://github.com/}"
    repo="${repo%.git}"

    log_debug "Obtendo última versão de $repo..."
    log_debug2 "Repositório: $repo, Branch: $CLI_REPO_BRANCH"

    # Use GitHub library function with fallback
    github_get_latest_version_with_fallback "$repo" "$CLI_REPO_BRANCH" "core/cli.json" "version"
}

# Function to compare versions
version_greater_than() {
    local version1=$1
    local version2=$2

    # Remove prefix 'v' if exists
    version1=${version1#v}
    version2=${version2#v}

    # Uses sort -V for version comparison
    local higher=$(echo -e "$version1\n$version2" | sort -V | tail -n1)

    [[ "$version2" == "$higher" && "$version1" != "$version2" ]]
}

# Main update function
perform_update() {
    log_trace "Chamando perform_update()"
    log_debug "Preparando atualização do repositório"
    log_debug2 "Clonando de: $CLI_REPO_URL (branch: $CLI_REPO_BRANCH)"

    # Clones the repository
    cd "$TEMP_DIR"
    log_trace "Mudando para diretório temporário: $TEMP_DIR"
    log_output "⬇  Baixando atualização..."

    # Captura a saída de erro do git clone, mas oculta do usuário
    local error_output
    log_trace "Executando: git clone --depth 1 --branch $CLI_REPO_BRANCH $CLI_REPO_URL"
    error_output=$(git clone --depth 1 --branch "$CLI_REPO_BRANCH" "$CLI_REPO_URL" susa-update 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao baixar atualização do repositório"
        log_debug "Erro ao clonar repositório"
        log_debug2 "Detalhes do erro: $error_output"
        log_output "Verifique sua conexão com a internet e tente novamente"
        return 1
    fi

    cd susa-update
    log_trace "Mudando para diretório do clone: susa-update"

    # Check if cli.json exists
    if [ ! -f "core/cli.json" ]; then
        log_error "Arquivo de configuração não encontrado na versão baixada"
        log_debug2 "Esperado: core/cli.json"
        return 1
    fi
    log_debug "Validação do repositório clonado concluída"

    # Preserve critical files before updating
    log_debug "Preservando configurações de plugins..."
    local backup_registry=""
    if [ -f "$CLI_DIR/plugins/registry.json" ]; then
        backup_registry="$TEMP_DIR/registry.json.backup"
        log_trace "Criando backup: $backup_registry"
        cp "$CLI_DIR/plugins/registry.json" "$backup_registry"
        log_debug "Registry de plugins preservado"
    else
        log_debug "Nenhum plugin instalado, pulando backup"
    fi

    # Copy new files (except .git)
    log_output "⚙  Instalando arquivos..."
    log_trace "Removendo diretório .git"
    rm -rf .git
    log_trace "Copiando arquivos para: $CLI_DIR"
    cp -rf ./* "$CLI_DIR/"

    # Restores plugin registry if there was a backup
    if [ -n "$backup_registry" ] && [ -f "$backup_registry" ]; then
        log_trace "Restaurando registry de: $backup_registry"
        cp "$backup_registry" "$CLI_DIR/plugins/registry.json"
        log_debug "Registry de plugins restaurado"
    fi

    # Update lock file after successful update
    log_debug "Atualizando arquivo de cache..."
    log_trace "Executando: susa self lock"
    if "$CORE_DIR/susa" self lock > /dev/null 2>&1; then
        log_debug "Cache atualizado com sucesso"
    else
        log_warning "Não foi possível atualizar o cache. Execute 'susa self lock' manualmente."
        log_debug2 "Comando falhou: susa self lock"
    fi

    log_trace "perform_update() concluída com sucesso"
    return 0
}

# Main function
main() {
    # Parse arguments
    auto_confirm=false
    force_update=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                auto_confirm=true
                log_debug "Modo auto-confirmação ativado"
                shift
                ;;
            -f | --force)
                force_update=true
                log_debug "Modo forçar atualização ativado"
                shift
                ;;
            *)
                log_error "Argumento inválido: $1"
                log_output ""
                show_help
                exit 1
                ;;
        esac
    done

    log_trace "Chamando main() com auto_confirm=$auto_confirm, force_update=$force_update"
    log_output "🔍 Verificando atualizações..."

    # Get current version
    log_debug "Obtendo versão atual do CLI"
    CURRENT_VERSION=$(get_current_version)
    log_debug "Versão atual: $CURRENT_VERSION"

    # Get latest version
    log_debug "Consultando versão mais recente no repositório"
    LATEST_VERSION_RESULT=$(get_latest_version)

    if [[ -z "$LATEST_VERSION_RESULT" ]]; then
        log_warning "Não foi possível verificar a versão mais recente"
        log_output "Será feito download da branch '$CLI_REPO_BRANCH' sem comparação de versões"
        log_output ""

        # Ask if you want to continue without version check
        if [ "$auto_confirm" = false ]; then
            log_output ""
            if ! gum_confirm "Deseja continuar com a atualização?" "no"; then
                log_info "Atualização cancelada pelo usuário"
                exit 0
            fi
        fi

        # Run update without version comparison
        if perform_update; then
            log_success "✓ Atualizado com sucesso!"
        else
            log_error "Falha na atualização"
            exit 1
        fi
        exit 0
    fi

    # Parse result (version|method)
    IFS='|' read -r LATEST_VERSION METHOD <<< "$LATEST_VERSION_RESULT"
    log_output "   Versão atual: ${CYAN}$CURRENT_VERSION${NC}"
    log_output "   Disponível:   ${GREEN}$LATEST_VERSION${NC}"
    log_debug2 "Método de detecção: $METHOD"

    # Compare versions
    log_debug "Comparando versões: atual=$CURRENT_VERSION, disponível=$LATEST_VERSION"
    if version_greater_than "$CURRENT_VERSION" "$LATEST_VERSION" || [ "$force_update" = true ]; then
        log_output ""
        if [ "$force_update" = true ] && [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            log_output "🔄 Forçando reinstalação da versão $CURRENT_VERSION"
        else
            log_output "🎉 Nova versão disponível!"
        fi

        # Ask if you want to update
        if [ "$auto_confirm" = false ]; then
            if ! gum_confirm "Deseja atualizar agora?" "no"; then
                log_info "Atualização cancelada pelo usuário"
                exit 0
            fi
        fi

        log_output ""

        # Run update
        if perform_update; then
            log_success "✓ Atualizado para $LATEST_VERSION"
        else
            log_error "Falha na atualização"
            exit 1
        fi
    else
        log_success "✓ Já está na versão mais recente"
    fi
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
