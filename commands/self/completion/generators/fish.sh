#!/usr/bin/env zsh

# Generate completion script for Fish
generate_fish_completion() {
    cat << 'FISH_COMPLETION_EOF'
# Susa CLI - Fish Completion
# Gerado automaticamente por: susa self completion fish

# Função para obter o diretório do susa
function __susa_get_dir
    set -l susa_path (command -v susa)
    if test -n "$susa_path"
        dirname (dirname (readlink -f $susa_path))  # Volta 2 níveis (core/susa -> core -> raiz)
    end
end

# Função para detectar o OS atual
function __susa_get_os
    set -l uname_cmd ""
    for cmd in uname /usr/bin/uname /bin/uname
        if command -v $cmd >/dev/null 2>&1
            set uname_cmd $cmd
            break
        end
    end

    if test -n "$uname_cmd"
        if test ($uname_cmd 2>/dev/null) = "Darwin"
            echo "mac"
        else
            echo "linux"
        end
    else
        echo "linux"  # fallback
    end
end

# Função para verificar compatibilidade de comando
function __susa_is_compatible
    set -l category $argv[1]
    set -l command $argv[2]
    set -l susa_dir (__susa_get_dir)
    set -l current_os (__susa_get_os)
    set -l config_file ""

    # Procura command.json
    if test -f "$susa_dir/commands/$category/$command/command.json"
        set config_file "$susa_dir/commands/$category/$command/command.json"
    else if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -f "$plugin_dir$category/$command/command.json"
                set config_file "$plugin_dir$category/$command/command.json"
                break
            end
        end
    end

    # Se não encontrou config, assume compatível
    test -z "$config_file"; and return 0

    # Encontra comandos com fallback
    set -l grep_cmd ""
    set -l sed_cmd ""
    set -l tr_cmd ""
    for cmd in grep /usr/bin/grep /bin/grep
        if command -v $cmd >/dev/null 2>&1
            set grep_cmd $cmd
            break
        end
    end
    for cmd in sed /usr/bin/sed /bin/sed
        if command -v $cmd >/dev/null 2>&1
            set sed_cmd $cmd
            break
        end
    end
    for cmd in tr /usr/bin/tr /bin/tr
        if command -v $cmd >/dev/null 2>&1
            set tr_cmd $cmd
            break
        end
    end

    # Se não tiver ferramentas, assume compatível
    test -z "$grep_cmd"; and return 0

    # Tenta formato multi-linha (os:\n  - mac\n  - linux)
    set -l os_list ($grep_cmd -A5 '^os:' "$config_file" 2>/dev/null | $grep_cmd -E '^  - ' 2>/dev/null | $sed_cmd 's/^  - //' 2>/dev/null | $tr_cmd -d '"' 2>/dev/null)

    # Se não encontrou em formato multi-linha, tenta formato inline (os: ["mac", "linux"])
    if test -z "$os_list"
        set os_list ($grep_cmd '^os:' "$config_file" 2>/dev/null | $sed_cmd 's/^os: *//' 2>/dev/null | $sed_cmd 's/\[//g; s/\]//g; s/,/ /g' 2>/dev/null | $tr_cmd -d '"' 2>/dev/null)
    end

    # Se não tem restrição, é compatível
    test -z "$os_list"; and return 0

    # Verifica se o OS atual está na lista
    echo "$os_list" | $grep_cmd -qw "$current_os" 2>/dev/null
end

# Função para listar categorias
function __susa_categories
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l categories

    # Lista de commands/
    if test -d "$susa_dir/commands"
        for dir in $susa_dir/commands/*/
            test -d $dir; and set -a categories (basename $dir)
        end
    end

    # Lista de plugins/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d $plugin_dir; and test -f "$plugin_dir/plugin.json"
                # Determina o diretório de comandos do plugin (via "directory" no plugin.json)
                set -l plugin_commands_dir $plugin_dir
                if command -v jq >/dev/null 2>&1
                    set -l configured_dir (jq -r '.directory // ""' "$plugin_dir/plugin.json" 2>/dev/null)
                    if test -n "$configured_dir"; and test -d "$plugin_dir/$configured_dir"
                        set plugin_commands_dir "$plugin_dir/$configured_dir"
                    end
                end
                # Lista apenas diretórios que contêm category.json
                for cat_dir in $plugin_commands_dir*/
                    if test -d $cat_dir; and test -f "$cat_dir/category.json"
                        set -a categories (basename $cat_dir)
                    end
                end
            end
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $categories | sort -u
end

# Função para listar comandos de uma categoria
function __susa_commands
    set -l category $argv[1]
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l all_commands
    set -l commands

    # Lista de commands/categoria/
    if test -d "$susa_dir/commands/$category"
        for item in $susa_dir/commands/$category/*/
            set -l cmd (basename $item)
            if test -d $item; and test "$cmd" != "category.json"; and test "$cmd" != "command.json"
                set -a all_commands $cmd
            end
        end
    end

    # Lista de plugins/*/categoria/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d "$plugin_dir/$category"
                for item in $plugin_dir/$category/*/
                    set -l cmd (basename $item)
                    if test -d $item; and test "$cmd" != "category.json"; and test "$cmd" != "command.json"
                        set -a all_commands $cmd
                    end
                end
            end
        end
    end

    # Filtra comandos compatíveis com o OS atual
    for cmd in $all_commands
        if __susa_is_compatible "$category" "$cmd"
            set -a commands $cmd
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $commands | sort -u
end

# Função para listar subcomandos
function __susa_subcommands
    set -l path $argv[1]
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l subcommands

    # Lista de commands/path/
    if test -d "$susa_dir/commands/$path"
        for item in $susa_dir/commands/$path/*/
            set -l sub (basename $item)
            if test -d $item; and test "$sub" != "category.json"; and test "$sub" != "command.json"
                set -a subcommands $sub
            end
        end
    end

    # Lista de plugins/*/path/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d "$plugin_dir/$path"
                for item in $plugin_dir/$path/*/
                    set -l sub (basename $item)
                    if test -d $item; and test "$sub" != "category.json"; and test "$sub" != "command.json"
                        set -a subcommands $sub
                    end
                end
            end
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $subcommands | sort -u
end

# Condições para quando completar
function __susa_needs_category
    not __fish_seen_subcommand_from (__susa_categories)
end

function __susa_needs_command
    __fish_seen_subcommand_from (__susa_categories); and not __fish_seen_subcommand_from (__susa_commands (commandline -opc)[2])
end

# Completions principais
complete -c susa -f

# Opções globais
complete -c susa -s h -l help -d "Mostra ajuda"
complete -c susa -s V -l version -d "Mostra versão"

# Nível 1: Categorias
complete -c susa -n __susa_needs_category -a "(__susa_categories)" -d "Categoria"

# Nível 2: Comandos da categoria
complete -c susa -n __susa_needs_command -a "(__susa_commands (commandline -opc)[2])" -d "Comando"

# Nível 3+: Subcomandos (para subcategorias)
complete -c susa -n "test (count (commandline -opc)) -ge 3" -a "(__susa_subcommands (string join / (commandline -opc)[2..-1]))" -d "Subcomando"
FISH_COMPLETION_EOF
}
