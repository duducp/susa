#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

main() {
    local cache_dir
    if [[ "$(uname)" == "Darwin" ]]; then
        cache_dir="${TMPDIR:-$HOME/Library/Caches}/susa"
    else
        cache_dir="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
    fi

    # Check storage type and location info
    local is_tmpfs=false
    local storage_info=""

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: Files are on disk but heavily cached by OS
        storage_info="em disco (cache do sistema)"
    elif [[ "$(uname)" == "Linux" ]]; then
        # Linux: Check if it's tmpfs (RAM)
        local fs_type=$(df -T "$cache_dir" 2> /dev/null | tail -1 | awk '{print $2}')
        if [ "$fs_type" = "tmpfs" ]; then
            is_tmpfs=true
            storage_info="em RAM (tmpfs)"
        else
            storage_info="em disco"
        fi
    else
        storage_info="em disco"
    fi

    # Check if cache directory exists
    if [ ! -d "$cache_dir" ]; then
        log_warning "Nenhum cache encontrado"
        log_output ""
        log_output "O diretório de cache será criado automaticamente quando você"
        log_output "executar comandos que utilizam cache."
        exit 0
    fi

    # Build table data in background with spinner
    local temp_data=$(mktemp)
    local found=0
    local total_size=0

    # Start spinner
    gum_spin_start "Listando caches disponíveis..."

    (
        # Build table data for gum
        local table_data="Nome,Tamanho,Chaves,Modificado,Localização"$'\n'
        local scan_found=0
        local scan_total=0

        # Build table data
        for cache_file in "$cache_dir"/*.cache; do
            [ -f "$cache_file" ] || continue

            local name=$(basename "$cache_file" .cache)

            # Get file size in bytes (cross-platform)
            if [[ "$(uname)" == "Darwin" ]]; then
                local size_bytes=$(stat -f %z "$cache_file" 2> /dev/null || echo "0")
            else
                local size_bytes=$(stat -c %s "$cache_file" 2> /dev/null || echo "0")
            fi

            # Format size
            local size_human=""
            if ((size_bytes < 1024)); then
                size_human="${size_bytes}B"
            elif ((size_bytes < 1048576)); then
                size_human="$((size_bytes / 1024))KB"
            else
                size_human="$((size_bytes / 1048576))MB"
            fi

            # Get total key count (recursive - all keys including nested)
            local key_count=$(jq '[paths(scalars)] | length' "$cache_file" 2> /dev/null || echo "0")

            # Get modification date
            if [[ "$(uname)" == "Darwin" ]]; then
                local cache_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2> /dev/null || echo "N/A")
            else
                local cache_date=$(stat -c "%y" "$cache_file" 2> /dev/null | cut -d'.' -f1 || echo "N/A")
            fi

            # Add row to table data
            table_data+="${name},${size_human},${key_count},${cache_date},${cache_file}"$'\n'

            scan_found=$((scan_found + 1))
            scan_total=$((scan_total + size_bytes))
        done

        # Write results to temp file
        echo "$table_data" > "$temp_data"
        echo "$scan_found" >> "$temp_data"
        echo "$scan_total" >> "$temp_data"
        echo "$is_tmpfs" >> "$temp_data"
        echo "$storage_info" >> "$temp_data"
    ) &
    local scan_pid=$!

    # Wait for scan to finish
    wait $scan_pid

    # Minimum display time for spinner visibility
    sleep 0.5

    # Stop spinner
    gum_spin_stop

    # Read results from temp file
    local line_count=$(wc -l < "$temp_data")
    local table_data=$(head -n -4 "$temp_data")
    found=$(tail -n 4 "$temp_data" | head -n 1)
    total_size=$(tail -n 3 "$temp_data" | head -n 1)
    is_tmpfs=$(tail -n 2 "$temp_data" | head -n 1)
    storage_info=$(tail -n 1 "$temp_data")

    rm -f "$temp_data"

    if [ $found -eq 0 ]; then
        log_warning "Nenhum cache encontrado"
        exit 0
    fi

    log_output "${BOLD}Caches Disponíveis:${NC}"
    echo ""

    # Render table with gum
    echo "$table_data" | gum_table_csv

    # Show summary
    echo ""

    local total_human
    if ((total_size < 1024)); then
        total_human="${total_size}B"
    elif ((total_size < 1048576)); then
        total_human="$((total_size / 1024))KB"
    else
        total_human="$((total_size / 1048576))MB"
    fi

    # Display storage information
    if [ "$is_tmpfs" = true ]; then
        log_output "${BOLD}Total:${NC} $found cache(s) • ${GREEN}$total_human $storage_info${NC}"
        log_output "${GRAY}Cache armazenado em memória para máxima performance${NC}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        log_output "${BOLD}Total:${NC} $found cache(s) • ${YELLOW}$total_human $storage_info${NC}"
        log_output "${GRAY}macOS mantém arquivos acessados recentemente em memória automaticamente${NC}"
    else
        log_output "${BOLD}Total:${NC} $found cache(s) • $total_human $storage_info"
        log_output "${GRAY}Para melhor performance, use tmpfs montado em /tmp${NC}"
    fi
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
