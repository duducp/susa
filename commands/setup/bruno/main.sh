#!/bin/bash

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"

# Constants
APP_NAME="Bruno"
REPO="usebruno/bruno"
BIN_NAME="bruno"
HOMEBREW_CASK="bruno"
FLATPAK_APP_ID="com.usebruno.Bruno"
SKIP_CONFIRM=false

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $APP_NAME é um cliente de API open-source rápido e amigável para Git."
    log_output "  Alternativa ao Postman/Insomnia, armazena coleções diretamente"
    log_output "  em uma pasta no seu sistema de arquivos. Usa linguagem de"
    log_output "  marcação própria (Bru) para salvar informações sobre requisições API."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do $APP_NAME"
    log_output "  --uninstall       Desinstala o $APP_NAME do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o $APP_NAME para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup bruno              # Instala o $APP_NAME"
    log_output "  susa setup bruno --upgrade    # Atualiza o $APP_NAME"
    log_output "  susa setup bruno --uninstall  # Desinstala o $APP_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Inicie o $APP_NAME pelo menu de aplicações ou execute:"
    log_output "    flatpak run $FLATPAK_APP_ID    (Linux)"
    log_output "    open -a Bruno                  (macOS)"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Offline-first - sem sincronização em nuvem"
    log_output "  • Armazena coleções em pastas no sistema de arquivos"
    log_output "  • Versionamento com Git"
    log_output "  • Linguagem de marcação própria (Bru)"
    log_output "  • Suporte a REST, GraphQL e gRPC"
    log_output "  • Variáveis de ambiente"
    log_output "  • Scripts e testes"
    log_output "  • Colaboração via Git"
    log_output ""
    log_output "${LIGHT_GREEN}Diferencial:${NC}"
    log_output "  Ao contrário do Postman, Bruno armazena suas coleções diretamente"
    log_output "  no sistema de arquivos, permitindo usar Git para controle de versão"
    log_output "  e colaboração sem depender de sincronização em nuvem."
}

# Get latest version
get_latest_version() {
    case "$OS_TYPE" in
        macos)
            # Get from GitHub releases for macOS
            github_get_latest_version "$REPO"
            ;;
        *)
            # Get from Flathub for Linux
            flatpak_get_latest_version "$FLATPAK_APP_ID"
            ;;
    esac
}

# Get installed version
get_current_version() {
    if check_installation; then
        case "$OS_TYPE" in
            macos)
                if brew list --cask "$HOMEBREW_CASK" &> /dev/null; then
                    brew list --cask "$HOMEBREW_CASK" --versions | awk '{print $2}'
                else
                    echo "desconhecida"
                fi
                ;;
            *)
                # Get version from Flatpak
                flatpak_get_installed_version "$FLATPAK_APP_ID"
                ;;
        esac
    else
        echo "desconhecida"
    fi
}

# Check if Bruno is installed
check_installation() {
    case "$OS_TYPE" in
        macos)
            brew list --cask "$HOMEBREW_CASK" &> /dev/null
            ;;
        *)
            flatpak_is_installed "$FLATPAK_APP_ID"
            ;;
    esac
}

# Install on macOS
install_macos() {
    log_info "Instalando $APP_NAME no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install Bruno
    log_debug "Executando: brew install --cask $HOMEBREW_CASK"
    log_info "Instalando $APP_NAME via Homebrew..."
    brew install --cask "$HOMEBREW_CASK"

    return 0
}

# Install on Linux using Flatpak
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$APP_NAME"
}

# Main installation function
install_bruno() {
    if check_installation; then
        log_info "$APP_NAME $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do $APP_NAME..."

    # Install based on OS
    case "$OS_TYPE" in
        macos)
            install_macos
            ;;
        debian | fedora)
            install_linux
            ;;
        *)
            if is_arch; then
                install_linux
            else
                log_error "Sistema operacional não suportado: $OS_TYPE"
                return 1
            fi
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "$APP_NAME $installed_version instalado com sucesso!"
        else
            log_error "$APP_NAME foi instalado mas não está disponível"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Bruno
update_bruno() {
    # Check if installed
    if ! check_installation; then
        log_error "$APP_NAME não está instalado. Use 'susa setup bruno' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)

    # Get latest version
    local latest_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    # Remove 'v' prefix if present
    latest_version="${latest_version#v}"

    if [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando $APP_NAME..."

    # Update based on OS
    case "$OS_TYPE" in
        macos)
            # Use Homebrew upgrade
            log_info "Atualizando via Homebrew..."
            brew upgrade --cask "$HOMEBREW_CASK" || {
                log_info "$APP_NAME já está na versão mais recente"
            }
            ;;
        *)
            # Use flatpak update
            if ! flatpak_update "$FLATPAK_APP_ID" "$APP_NAME"; then
                return 1
            fi
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

        log_success "$APP_NAME atualizado com sucesso para versão $new_version!"
    else
        log_error "Falha na atualização do $APP_NAME"
        return 1
    fi
}

# Internal uninstall (without prompts)
remove_bruno_internal() {
    case "$OS_TYPE" in
        macos)
            brew uninstall --cask "$HOMEBREW_CASK" > /dev/null 2>&1 || true
            ;;
        *)
            flatpak_uninstall "$FLATPAK_APP_ID" "$APP_NAME" > /dev/null 2>&1 || true
            ;;
    esac
}

# Uninstall Bruno
uninstall_bruno() {
    if ! check_installation; then
        log_info "$APP_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o $APP_NAME $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Removendo $APP_NAME..."

    remove_bruno_internal

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "$APP_NAME desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar $APP_NAME completamente"
        return 1
    fi
}

# Main function
main() {
    local action="install"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "$BIN_NAME"
                exit 0
                ;;
            --uninstall)
                action="uninstall"
                shift
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -u | --upgrade)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Execute action
    case "$action" in
        install)
            install_bruno
            ;;
        uninstall)
            uninstall_bruno
            ;;
        update)
            update_bruno
            ;;
        *)
            log_error "Ação inválida: $action"
            exit 1
            ;;
    esac
}

main "$@"
