#!/usr/bin/env zsh
# Docker Common Utilities
# Shared functions used across install, update and uninstall

# Constants
DOCKER_NAME="Docker"
DOCKER_REPO="moby/moby"
DOCKER_BIN_NAME="docker"
DOCKER_DOWNLOAD_BASE_URL="https://download.docker.com"

# Get latest version
get_latest_version() {
    # Get latest version from GitHub releases (format: docker-v29.1.4)
    local version_tag
    version_tag=$(github_get_latest_version "$DOCKER_REPO")

    if [ $? -eq 0 ] && [ -n "$version_tag" ]; then
        # Remove "docker-v" prefix to get just the version number
        local version="${version_tag#docker-v}"
        echo "$version"
        return 0
    fi

    log_error "Não foi possível obter a versão mais recente do $DOCKER_NAME"
    log_error "Verifique sua conexão com a internet e tente novamente"
    return 1
}

# Get installed Docker version
get_current_version() {
    if check_installation; then
        $DOCKER_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
    else
        echo ""
    fi
}

# Check if Docker is installed
check_installation() {
    command -v docker &> /dev/null
}
