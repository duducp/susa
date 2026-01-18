#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"

# Constants
APP_NAME="Podman Desktop"
REPO="podman-desktop/podman-desktop"
BIN_NAME="podman-desktop"
FLATPAK_APP_ID="io.podman_desktop.PodmanDesktop"
APP_MACOS="/Applications/Podman Desktop.app"
SKIP_CONFIRM=false

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $APP_NAME é uma interface gráfica para gerenciar containers,"
    log_output "  imagens e pods Podman. Oferece uma experiência visual amigável"
    log_output "  para trabalhar com containers sem necessidade de linha de comando."
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
    log_output "  susa setup podman-desktop              # Instala o $APP_NAME"
    log_output "  susa setup podman-desktop --upgrade    # Atualiza o $APP_NAME"
    log_output "  susa setup podman-desktop --uninstall  # Desinstala o $APP_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Inicie o $APP_NAME pelo menu de aplicações ou execute:"
    log_output "    flatpak run $FLATPAK_APP_ID    (Linux)"
    log_output "    open '/Applications/Podman Desktop.app'    (macOS)"
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
                if [ -d "$APP_MACOS" ]; then
                    # Try to get version from Info.plist
                    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_MACOS/Contents/Info.plist" 2> /dev/null || echo "desconhecida")
                    echo "$version"
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

get_installation() {
    case "$OS_TYPE" in
        macos)
            echo "$APP_MACOS"
            ;;
        *)
            echo "Flatpak: $FLATPAK_APP_ID"
            ;;
    esac
}

# Check if Podman Desktop is installed
check_installation() {
    case "$OS_TYPE" in
        macos)
            [ -d "$APP_MACOS" ]
            ;;
        *)
            flatpak_is_installed "$FLATPAK_APP_ID"
            ;;
    esac
}

# Install on macOS
install_macos() {
    local version="$1"
    log_info "Instalando $APP_NAME $version no macOS..."

    local url="https://github.com/$REPO/releases/download/v${version}/podman-desktop-${version}-universal.dmg"
    local dmg_file="/tmp/podman-desktop-${version}.dmg"
    local volume="/Volumes/Podman Desktop"

    # Download DMG
    log_debug "Baixando de: $url"
    if ! curl -fSL "$url" -o "$dmg_file"; then
        log_error "Falha ao baixar o $APP_NAME"
        return 1
    fi

    # Mount DMG
    log_debug "Montando imagem do disco..."
    if ! hdiutil attach "$dmg_file" -nobrowse -quiet; then
        log_error "Falha ao montar a imagem do disco"
        rm -f "$dmg_file"
        return 1
    fi

    # Copy application
    log_debug "Copiando aplicação..."
    if [ -d "$volume/Podman Desktop.app" ]; then
        # Remove old version if exists
        [ -d "$APP_MACOS" ] && sudo rm -rf "$APP_MACOS"

        sudo cp -R "$volume/Podman Desktop.app" "$APP_MACOS"
    else
        log_error "Aplicação não encontrada no volume montado"
        hdiutil detach "$volume" -quiet 2> /dev/null || true
        rm -f "$dmg_file"
        return 1
    fi

    # Unmount DMG
    log_debug "Desmontando imagem do disco..."
    hdiutil detach "$volume" -quiet 2> /dev/null || log_debug "Volume já estava desmontado"

    # Clean up
    rm -f "$dmg_file"

    return 0
}

# Install on Linux using Flatpak
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$APP_NAME"
}

# Main installation function
install_podman_desktop() {
    if check_installation; then
        log_info "$APP_NAME $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do $APP_NAME..."

    # Install based on OS
    case "$OS_TYPE" in
        macos)
            # Get latest version for macOS
            local version=$(get_latest_version)
            if [ $? -ne 0 ] || [ -z "$version" ]; then
                log_error "Não foi possível obter a versão mais recente"
                return 1
            fi
            # Remove 'v' prefix if present
            version="${version#v}"
            install_macos "$version"
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

# Update Podman Desktop
update_podman_desktop() {
    # Check if installed
    if ! check_installation; then
        log_error "$APP_NAME não está instalado. Use 'susa setup podman-desktop' para instalar."
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
            # Uninstall old version (without confirmation)
            SKIP_CONFIRM=true
            remove_podman_desktop_internal
            # Install new version
            install_macos "$latest_version"
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
remove_podman_desktop_internal() {
    case "$OS_TYPE" in
        macos)
            if [ -d "$APP_MACOS" ]; then
                sudo rm -rf "$APP_MACOS"
            fi
            ;;
        *)
            flatpak_uninstall "$FLATPAK_APP_ID" "$APP_NAME" > /dev/null 2>&1 || true
            ;;
    esac
}

# Uninstall Podman Desktop
uninstall_podman_desktop() {
    # Check if installed
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

    remove_podman_desktop_internal

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
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --verbose)
                log_debug "Modo verbose ativado"
                export DEBUG=true
                shift
                ;;
            -q | --quiet)
                export SILENT=true
                shift
                ;;
            --info)
                show_software_info "$BIN_NAME"
                exit 0
                ;;
            --get-current-version)
                get_current_version
                exit 0
                ;;
            --get-latest-version)
                get_latest_version
                exit 0
                ;;
            --check-installation)
                check_installation
                exit $?
                ;;
            --get-installation)
                get_installation
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
            install_podman_desktop
            ;;
        uninstall)
            uninstall_podman_desktop
            ;;
        update)
            update_podman_desktop
            ;;
        *)
            log_error "Ação inválida: $action"
            exit 1
            ;;
    esac
}

main "$@"
