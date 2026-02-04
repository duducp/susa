#!/bin/bash
# Google Cloud SDK Common Utilities
# Shared functions used across install, update and uninstall

# Constants
GCLOUD_NAME="Google Cloud SDK"
GCLOUD_BIN_NAME="gcloud"
GCLOUD_SDK_BASE_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads"

# Get latest version from Google Cloud SDK
get_latest_version() {
    local version=$(curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json | grep -oP '"version": "\K[^"]+' | head -1)

    if [ -z "$version" ]; then
        log_debug "Não foi possível obter a versão mais recente"
        echo ""
        return 1
    fi

    echo "$version"
}

# Get installed gcloud version
get_current_version() {
    if check_installation; then
        $GCLOUD_BIN_NAME version --format="value(.)" 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
    else
        echo ""
    fi
}

# Check if gcloud is installed
check_installation() {
    command -v $GCLOUD_BIN_NAME &> /dev/null
}
