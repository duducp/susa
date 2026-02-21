#!/usr/bin/env zsh

# Generate completion script for Bash
generate_bash_completion() {
    cat << 'BASH_COMPLETION_EOF'
# Susa CLI - Bash Completion
# Gerado automaticamente por: susa self completion bash

_susa_completion() {
    local cur prev words cword
    _init_completion || return

    local susa_dir="$(dirname "$(dirname "$(readlink -f "$(command -v susa)")")")"  # Volta 2 níveis

    # Função para detectar o OS atual (linux ou mac)
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

    # Função para verificar se comando é compatível com o OS atual
    _susa_is_compatible() {
        local category="$1"
        local command="$2"
        local current_os="$(_susa_get_os)"
        local config_file=""

        # Tentar encontrar command.json do comando (commands ou plugins)
        if [ -f "$susa_dir/commands/$category/$command/command.json" ]; then
            config_file="$susa_dir/commands/$category/$command/command.json"
        elif [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -f "${plugin_dir}${category}/${command}/command.json" ]; then
                    config_file="${plugin_dir}${category}/${command}/command.json"
                    break
                fi
            done
        fi

        # Se não encontrou config, assume compatível
        [ -z "$config_file" ] && return 0

        # Verifica se tem restrição de OS (usa comandos com fallback)
        local grep_cmd sed_cmd tr_cmd
        for grep_cmd in grep /usr/bin/grep /bin/grep; do command -v "$grep_cmd" >/dev/null 2>&1 && break; done
        for sed_cmd in sed /usr/bin/sed /bin/sed; do command -v "$sed_cmd" >/dev/null 2>&1 && break; done
        for tr_cmd in tr /usr/bin/tr /bin/tr; do command -v "$tr_cmd" >/dev/null 2>&1 && break; done

        # Se não tiver as ferramentas necessárias, assume compatível
        if ! command -v "$grep_cmd" >/dev/null 2>&1; then return 0; fi

        # Tenta formato multi-linha (os:\n  - mac\n  - linux)
        local os_list=$("$grep_cmd" -A5 '^os:' "$config_file" 2>/dev/null | "$grep_cmd" -E '^  - ' 2>/dev/null | "$sed_cmd" 's/^  - //' 2>/dev/null | "$tr_cmd" -d '"' 2>/dev/null)

        # Se não encontrou em formato multi-linha, tenta formato inline (os: ["mac", "linux"])
        if [ -z "$os_list" ]; then
            os_list=$("$grep_cmd" '^os:' "$config_file" 2>/dev/null | "$sed_cmd" 's/^os: *//' 2>/dev/null | "$sed_cmd" 's/\[//g; s/\]//g; s/,/ /g' 2>/dev/null | "$tr_cmd" -d '"' 2>/dev/null)
        fi

        # Se não tem restrição de OS, é compatível
        [ -z "$os_list" ] && return 0

        # Verifica se o OS atual está na lista
        echo "$os_list" | "$grep_cmd" -qw "$current_os" 2>/dev/null
    }

    # Função para listar categorias (commands + plugins)
    _susa_get_categories() {
        local categories=""

        # Lista de commands/
        if [ -d "$susa_dir/commands" ]; then
            categories="$(ls -1 "$susa_dir/commands" 2>/dev/null)"
        fi

        # Lista de plugins/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/plugin.json" ]; then
                    # Determina o diretório de comandos do plugin (via "directory" no plugin.json)
                    local plugin_commands_dir="$plugin_dir"
                    if command -v jq >/dev/null 2>&1; then
                        local configured_dir=$(jq -r '.directory // ""' "$plugin_dir/plugin.json" 2>/dev/null)
                        if [ -n "$configured_dir" ] && [ -d "$plugin_dir/$configured_dir" ]; then
                            plugin_commands_dir="$plugin_dir/$configured_dir"
                        fi
                    fi
                    # Lista apenas diretórios que contêm category.json
                    for cat_dir in "$plugin_commands_dir"/*/ ; do
                        if [ -d "$cat_dir" ] && [ -f "$cat_dir/category.json" ]; then
                            categories="$categories $(basename "$cat_dir")"
                        fi
                    done
                fi
            done
        fi

        echo "$categories" | tr ' ' '\n' | sort -u
    }

    # Função para listar comandos de uma categoria (commands + plugins)
    _susa_get_commands() {
        local category="$1"
        local commands=""
        local all_commands=""

        # Lista de commands/categoria/
        if [ -d "$susa_dir/commands/$category" ]; then
            all_commands="$(ls -1 "$susa_dir/commands/$category" 2>/dev/null | grep -v "category.json" | grep -v "command.json")"
        fi

        # Lista de plugins/*/categoria/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir/$category" ]; then
                    local plugin_cmds="$(ls -1 "$plugin_dir/$category" 2>/dev/null | grep -v "category.json" | grep -v "command.json")"
                    all_commands="$all_commands $plugin_cmds"
                fi
            done
        fi

        # Filtra comandos compatíveis com o OS atual
        for cmd in $all_commands; do
            if _susa_is_compatible "$category" "$cmd"; then
                commands="$commands $cmd"
            fi
        done

        echo "$commands" | tr ' ' '\n' | sort -u
    }

    # Função para listar subcomandos (commands + plugins)
    _susa_get_subcommands() {
        local path="$1"
        local subcommands=""

        # Lista de commands/path/
        if [ -d "$susa_dir/commands/$path" ]; then
            subcommands="$(ls -1 "$susa_dir/commands/$path" 2>/dev/null | grep -v "category.json" | grep -v "command.json")"
        fi

        # Lista de plugins/*/path/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir/$path" ]; then
                    local plugin_subs="$(ls -1 "$plugin_dir/$path" 2>/dev/null | grep -v "category.json" | grep -v "command.json")"
                    subcommands="$subcommands $plugin_subs"
                fi
            done
        fi

        echo "$subcommands" | tr ' ' '\n' | sort -u
    }

    # Primeiro nível: categorias
    if [ $cword -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$(_susa_get_categories)" -- "$cur") )
        return 0
    fi

    # Segundo nível: comandos da categoria
    if [ $cword -eq 2 ]; then
        local category="${words[1]}"
        COMPREPLY=( $(compgen -W "$(_susa_get_commands "$category")" -- "$cur") )
        return 0
    fi

    # Terceiro nível e além: subcomandos
    if [ $cword -ge 3 ]; then
        local path="${words[1]}"
        for ((i=2; i<cword; i++)); do
            path="$path/${words[i]}"
        done
        COMPREPLY=( $(compgen -W "$(_susa_get_subcommands "$path")" -- "$cur") )
        return 0
    fi
}

complete -F _susa_completion susa
BASH_COMPLETION_EOF
}
