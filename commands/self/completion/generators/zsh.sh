#!/usr/bin/env zsh

# Generate completion script for Zsh
generate_zsh_completion() {
    cat << 'ZSH_COMPLETION_EOF'
#compdef susa
# Susa CLI - Zsh Completion
# Gerado automaticamente por: susa self completion zsh

_susa() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local susa_dir="$(dirname "$(dirname "$(readlink -f "$(command -v susa)")")")"  # Volta 2 níveis

    # Função para detectar o OS atual
    _susa_get_os() {
        local uname_cmd
        for uname_cmd in uname /usr/bin/uname /bin/uname; do
            if command -v "$uname_cmd" >/dev/null 2>&1; then
                if [[ "$("$uname_cmd" 2>/dev/null)" == "Darwin" ]]; then
                    echo "mac"
                else
                    echo "linux"
                fi
                return 0
            fi
        done
        echo "linux"  # fallback
    }

    # Função para verificar compatibilidade de comando
    _susa_is_compatible() {
        local category="$1"
        local command="$2"
        local current_os="$(_susa_get_os)"
        local config_file=""

        # Procura command.json
        if [ -f "$susa_dir/commands/$category/$command/command.json" ]; then
            config_file="$susa_dir/commands/$category/$command/command.json"
        elif [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/; do
                if [ -f "${plugin_dir}${category}/${command}/command.json" ]; then
                    config_file="${plugin_dir}${category}/${command}/command.json"
                    break
                fi
            done
        fi

        [ -z "$config_file" ] && return 0

        # Usa comandos com fallback para caminhos absolutos
        local grep_cmd sed_cmd tr_cmd
        for grep_cmd in grep /usr/bin/grep /bin/grep; do command -v "$grep_cmd" >/dev/null 2>&1 && break; done
        for sed_cmd in sed /usr/bin/sed /bin/sed; do command -v "$sed_cmd" >/dev/null 2>&1 && break; done
        for tr_cmd in tr /usr/bin/tr /bin/tr; do command -v "$tr_cmd" >/dev/null 2>&1 && break; done

        # Se não tiver as ferramentas, assume compatível
        if ! command -v "$grep_cmd" >/dev/null 2>&1; then return 0; fi

        # Tenta formato multi-linha (os:\n  - mac\n  - linux)
        local os_list=$("$grep_cmd" -A5 '^os:' "$config_file" 2>/dev/null | "$grep_cmd" -E '^  - ' 2>/dev/null | "$sed_cmd" 's/^  - //' 2>/dev/null | "$tr_cmd" -d '"' 2>/dev/null)

        # Se não encontrou em formato multi-linha, tenta formato inline (os: ["mac", "linux"])
        if [ -z "$os_list" ]; then
            os_list=$("$grep_cmd" '^os:' "$config_file" 2>/dev/null | "$sed_cmd" 's/^os: *//' 2>/dev/null | "$sed_cmd" 's/\[//g; s/\]//g; s/,/ /g' 2>/dev/null | "$tr_cmd" -d '"' 2>/dev/null)
        fi

        [ -z "$os_list" ] && return 0

        echo "$os_list" | "$grep_cmd" -qw "$current_os" 2>/dev/null
    }

    # Função para listar itens de um diretório
    _susa_list_items() {
        local path="$1"
        local items=()
        local all_items=()
        local category="${path%%/*}"
        local is_command_level=false
        local is_category_level=false

        # Detecta se está no nível de comandos (categoria/comando)
        [[ "$path" =~ ^[^/]+$ ]] && is_command_level=true

        # Detecta se está no nível de categorias (path vazio)
        [[ -z "$path" ]] && is_category_level=true

        # Lista de commands/path/
        if [ -d "$susa_dir/commands/$path" ]; then
            for item in "$susa_dir/commands/$path"/*/; do
                if [ -d "$item" ]; then
                    local name="${item:t}"
                    [ "$name" != "category.json" ] && [ "$name" != "command.json" ] && all_items+=("$name")
                fi
            done
        fi

        # Lista de plugins/*/path/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/; do
                # Se estiver listando categorias, precisa ler o plugin.json e aplicar o "directory"
                if [ "$is_category_level" = true ] && [ -f "$plugin_dir/plugin.json" ]; then
                    local plugin_commands_dir="$plugin_dir"
                    if command -v jq >/dev/null 2>&1; then
                        local configured_dir=$(jq -r '.directory // ""' "$plugin_dir/plugin.json" 2>/dev/null)
                        if [ -n "$configured_dir" ] && [ -d "$plugin_dir/$configured_dir" ]; then
                            plugin_commands_dir="$plugin_dir/$configured_dir"
                        fi
                    fi
                    # Lista apenas diretórios que contêm category.json
                    for item in "$plugin_commands_dir"/*/; do
                        if [ -d "$item" ] && [ -f "$item/category.json" ]; then
                            local name="${item:t}"
                            all_items+=("$name")
                        fi
                    done
                elif [ -d "$plugin_dir/$path" ]; then
                    for item in "$plugin_dir/$path"/*/; do
                        if [ -d "$item" ]; then
                            local name="${item:t}"
                            [ "$name" != "category.json" ] && [ "$name" != "command.json" ] && all_items+=("$name")
                        fi
                    done
                fi
            done
        fi

        # Filtra por compatibilidade se estiver listando comandos
        if [ "$is_command_level" = true ]; then
            for item in "${all_items[@]}"; do
                if _susa_is_compatible "$category" "$item"; then
                    items+=("$item")
                fi
            done
        else
            items=("${all_items[@]}")
        fi

        # Remove duplicatas
        items=(${(u)items})
        echo "${items[@]}"
    }

    # Função recursiva para completion
    _susa_complete() {
        local -a completions
        local path=""

        # Valida se CURRENT existe e é um número
        [[ -z "$CURRENT" || ! "$CURRENT" =~ ^[0-9]+$ ]] && CURRENT=${#words[@]}

        # Protege contra arrays vazios ou inválidos
        [[ ${#words[@]} -lt 2 ]] && return 0

        # Constrói o path baseado nos argumentos já fornecidos
        local max_index=$((CURRENT - 1))
        for ((i=2; i<=max_index; i++)); do
            if [[ -n "${words[$i]:-}" ]]; then
                if [ -z "$path" ]; then
                    path="$words[$i]"
                else
                    path="$path/$words[$i]"
                fi
            fi
        done

        # Lista os itens do diretório atual
        local items=($(_susa_list_items "$path"))

        if [ ${#items[@]} -gt 0 ]; then
            completions=("${items[@]}")
            _describe -t commands 'command' completions
        fi
    }

    _susa_complete
}

_susa "$@"
ZSH_COMPLETION_EOF
}
