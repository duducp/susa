#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  PostgreSQL Client é o conjunto de ferramentas de linha de comando"
    log_output "  para interagir com servidores PostgreSQL. Inclui psql (cliente"
    log_output "  interativo), pg_dump, pg_restore e outros utilitários."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do PostgreSQL Client"
    log_output "  --uninstall       Desinstala o PostgreSQL Client do sistema"
    log_output "  -u, --upgrade     Atualiza o PostgreSQL Client para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup postgres              # Instala o PostgreSQL Client"
    log_output "  susa setup postgres --upgrade    # Atualiza o PostgreSQL Client"
    log_output "  susa setup postgres --uninstall  # Desinstala o PostgreSQL Client"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor PostgreSQL:"
    log_output "    psql -h hostname -U username -d database"
    log_output ""
    log_output "${LIGHT_GREEN}Utilitários incluídos:${NC}"
    log_output "  psql         Cliente interativo"
    log_output "  pg_dump      Backup de banco de dados"
    log_output "  pg_restore   Restauração de backup"
    log_output "  createdb     Criar banco de dados"
    log_output "  dropdb       Remover banco de dados"
}

# Get latest version from PostgreSQL official repository
get_latest_version() {
    local version

    # Try to get from PostgreSQL official version endpoint
    version=$(curl -s https://www.postgresql.org/versions.json 2> /dev/null | grep -oP '"latestMinor":\s*\K[0-9]+' | head -1)

    if [ -z "$version" ]; then
        log_debug "Não foi possível obter a versão mais recente"
        echo "16" # Fallback to current stable version
        return 0
    fi

    echo "$version"
}

# Get installed PostgreSQL client version
get_current_version() {
    if check_installation; then
        psql --version 2> /dev/null | grep -oP '\d+(\.\d+)?' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if PostgreSQL client is installed
check_installation() {
    command -v psql &> /dev/null
}

# Show additional PostgreSQL-specific information
# Called by show_software_info()
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Show available utilities
    local utils=("pg_dump" "pg_restore" "createdb" "dropdb" "pg_isready")
    local util_lines=""
    for util in "${utils[@]}"; do
        if command -v "$util" &> /dev/null; then
            util_lines+="    • $util\n"
        fi
    done
    if [ -n "$util_lines" ]; then
        log_output "  ${CYAN}Utilitários:${NC}\n$util_lines"
    fi
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Install PostgreSQL client on macOS
install_postgres_macos() {
    log_info "Instalando PostgreSQL Client via Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale primeiro com:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Get latest major version
    local major_version=$(get_latest_version)

    # Install or upgrade postgresql client
    if brew list libpq &> /dev/null 2>&1; then
        log_info "Atualizando PostgreSQL Client via Homebrew..."
        brew upgrade libpq || true
    else
        log_info "Instalando libpq (PostgreSQL Client) via Homebrew..."
        brew install libpq
    fi

    # Link binaries to PATH (Homebrew doesn't link libpq by default)
    if ! command -v psql &> /dev/null; then
        log_info "Configurando binários no PATH..."
        brew link --force libpq || {
            log_warning "Não foi possível criar links automaticamente"
            log_output "Adicione manualmente ao seu PATH:"
            log_output "  export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\""
        }
    fi

    return 0
}

# Install PostgreSQL client on Debian/Ubuntu
install_postgres_debian() {
    log_info "Instalando PostgreSQL Client no Debian/Ubuntu..."

    # Update package list
    log_debug "Atualizando lista de pacotes..."
    sudo apt-get update -qq || {
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    }

    # Install PostgreSQL client
    log_info "Instalando postgresql-client..."
    sudo apt-get install -y postgresql-client || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    return 0
}

# Install PostgreSQL client on RedHat/CentOS/Fedora
install_postgres_redhat() {
    log_info "Instalando PostgreSQL Client no RedHat/CentOS/Fedora..."

    local pkg_manager="dnf"

    # Check if dnf is available, otherwise use yum
    if ! command -v dnf &> /dev/null; then
        pkg_manager="yum"
    fi

    # Install PostgreSQL client
    log_info "Instalando postgresql via $pkg_manager..."
    sudo $pkg_manager install -y postgresql || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    return 0
}

# Install PostgreSQL client on Arch Linux
install_postgres_arch() {
    log_info "Instalando PostgreSQL Client no Arch Linux..."

    # Install PostgreSQL client
    log_info "Instalando postgresql-libs via pacman..."
    sudo pacman -S --noconfirm postgresql-libs || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    return 0
}

# Main installation function
install_postgres() {
    if check_installation; then
        log_info "PostgreSQL Client $(get_current_version) já está instalado."
        log_info "Use 'susa setup postgres --upgrade' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do PostgreSQL Client..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_postgres_macos
            install_result=$?
            ;;
        linux)
            local distro=$(detect_linux_distro)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    install_postgres_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    install_postgres_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    install_postgres_arch
                    install_result=$?
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    log_output "Instale manualmente usando o gerenciador de pacotes da sua distribuição"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "PostgreSQL Client $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "postgres" "$installed_version"

            echo ""
            log_output "Teste a instalação com:"
            log_output "  ${LIGHT_CYAN}psql --version${NC}"
            log_output ""
            log_output "Para conectar a um servidor PostgreSQL:"
            log_output "  ${LIGHT_CYAN}psql -h hostname -U username -d database${NC}"
        else
            log_error "PostgreSQL Client foi instalado mas não está disponível no PATH"

            # Provide additional help for macOS
            if [ "$os_name" = "darwin" ]; then
                log_output ""
                log_output "No macOS, você pode precisar adicionar ao PATH:"
                log_output "  export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\""
                log_output ""
                log_output "Adicione esta linha ao seu ~/.zshrc ou ~/.bashrc"
            fi
            return 1
        fi
    else
        return $install_result
    fi
}

# Update PostgreSQL client
update_postgres() {
    if ! check_installation; then
        log_error "PostgreSQL Client não está instalado. Use 'susa setup postgres' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Atualizando PostgreSQL Client (versão atual: $current_version)..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local update_result=1

    case "$os_name" in
        darwin)
            log_info "Atualizando via Homebrew..."
            brew upgrade libpq || {
                log_info "PostgreSQL Client já está na versão mais recente"
            }
            update_result=0
            ;;
        linux)
            local distro=$(detect_linux_distro)

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_info "Atualizando via apt..."
                    sudo apt-get update -qq
                    sudo apt-get install --only-upgrade -y postgresql-client || {
                        log_info "PostgreSQL Client já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager="dnf"
                    if ! command -v dnf &> /dev/null; then
                        pkg_manager="yum"
                    fi

                    log_info "Atualizando via $pkg_manager..."
                    sudo $pkg_manager upgrade -y postgresql || {
                        log_info "PostgreSQL Client já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                arch | manjaro)
                    log_info "Atualizando via pacman..."
                    sudo pacman -Syu --noconfirm postgresql-libs || {
                        log_info "PostgreSQL Client já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $update_result -eq 0 ]; then
        if check_installation; then
            local new_version=$(get_current_version)
            register_or_update_software_in_lock "postgres" "$new_version"

            if [ "$new_version" != "$current_version" ]; then
                log_success "PostgreSQL Client atualizado de $current_version para $new_version!"
            else
                log_info "PostgreSQL Client já está na versão mais recente ($current_version)"
            fi
        else
            log_error "Falha na atualização do PostgreSQL Client"
            return 1
        fi
    else
        return $update_result
    fi
}

# Uninstall PostgreSQL client
uninstall_postgres() {
    if ! check_installation; then
        log_info "PostgreSQL Client não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    log_output ""
    log_output "${YELLOW}Deseja realmente desinstalar o PostgreSQL Client $current_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    log_info "Desinstalando PostgreSQL Client..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local uninstall_result=1

    case "$os_name" in
        darwin)
            log_info "Desinstalando via Homebrew..."
            brew uninstall libpq || {
                log_error "Falha ao desinstalar via Homebrew"
                return 1
            }
            uninstall_result=0
            ;;
        linux)
            local distro=$(detect_linux_distro)

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_info "Desinstalando via apt..."
                    sudo apt-get remove -y postgresql-client || {
                        log_error "Falha ao desinstalar PostgreSQL Client"
                        return 1
                    }
                    sudo apt-get autoremove -y
                    uninstall_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager="dnf"
                    if ! command -v dnf &> /dev/null; then
                        pkg_manager="yum"
                    fi

                    log_info "Desinstalando via $pkg_manager..."
                    sudo $pkg_manager remove -y postgresql || {
                        log_error "Falha ao desinstalar PostgreSQL Client"
                        return 1
                    }
                    uninstall_result=0
                    ;;
                arch | manjaro)
                    log_info "Desinstalando via pacman..."
                    sudo pacman -R --noconfirm postgresql-libs || {
                        log_error "Falha ao desinstalar PostgreSQL Client"
                        return 1
                    }
                    uninstall_result=0
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $uninstall_result -eq 0 ]; then
        if ! check_installation; then
            remove_software_in_lock "postgres"
            log_success "PostgreSQL Client desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar PostgreSQL Client completamente"
            return 1
        fi
    else
        return $uninstall_result
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
                show_software_info
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
            --uninstall)
                action="uninstall"
                shift
                ;;
            -u | --upgrade)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action
    case "$action" in
        install)
            install_postgres
            ;;
        update)
            update_postgres
            ;;
        uninstall)
            uninstall_postgres
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
