#!/bin/bash

# --- Shell Config Helper Function ---

detect_shell_config() {
    # Detecta qual arquivo de configuração do shell usar
    # Verifica o shell do usuário via $SHELL
    local user_shell=$(basename "$SHELL")
    
    if [[ "$user_shell" == "zsh" ]] && [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [[ "$user_shell" == "bash" ]] && [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.profile"
    fi
}
