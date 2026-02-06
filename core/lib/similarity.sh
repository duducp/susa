#!/usr/bin/env zsh

# ============================================================
# String Similarity Functions
# ============================================================
# Functions for calculating string similarity and finding similar matches

# Calculate Levenshtein distance between two strings
# Args: string1 string2
# Returns: distance (0 = identical)
levenshtein_distance() {
    local s1="$1"
    local s2="$2"
    local len1=${#s1}
    local len2=${#s2}

    # Handle empty strings
    [ $len1 -eq 0 ] && echo "$len2" && return
    [ $len2 -eq 0 ] && echo "$len1" && return

    # Use associative array for matrix
    local -A matrix

    # Initialize first row and column
    for ((i = 0; i <= len1; i++)); do
        matrix["$i,0"]=$i
    done

    for ((j = 0; j <= len2; j++)); do
        matrix["0,$j"]=$j
    done

    # Fill matrix
    for ((i = 1; i <= len1; i++)); do
        for ((j = 1; j <= len2; j++)); do
            local cost=1
            if [ "${s1:$((i - 1)):1}" = "${s2:$((j - 1)):1}" ]; then
                cost=0
            fi

            local deletion=$((matrix["$((i - 1)),$j"] + 1))
            local insertion=$((matrix["$i,$((j - 1))"] + 1))
            local substitution=$((matrix["$((i - 1)),$((j - 1))"] + cost))

            # Get minimum
            local min=$deletion
            [ $insertion -lt $min ] && min=$insertion
            [ $substitution -lt $min ] && min=$substitution

            matrix["$i,$j"]=$min
        done
    done

    echo "${matrix["$len1,$len2"]}"
}

# Calculate similarity score (0-100, higher is more similar)
# Args: string1 string2
# Returns: similarity percentage
calculate_similarity() {
    local s1="$1"
    local s2="$2"
    local len1=${#s1}
    local len2=${#s2}

    # Handle empty strings
    if [ $len1 -eq 0 ] && [ $len2 -eq 0 ]; then
        echo "100"
        return
    fi

    if [ $len1 -eq 0 ] || [ $len2 -eq 0 ]; then
        echo "0"
        return
    fi

    local distance=$(levenshtein_distance "$s1" "$s2")
    local max_len=$len1
    [ $len2 -gt $max_len ] && max_len=$len2

    local similarity=$((100 - (distance * 100 / max_len)))
    echo "$similarity"
}

# Find most similar string from a list
# Args: target_string candidate1 candidate2 ... candidateN
# Returns: most similar candidate (or empty if none are similar enough)
find_most_similar() {
    local target="$1"
    shift
    local candidates=("$@")

    # Lowered threshold for better typo detection
    local min_threshold=20
    local best_match=""
    local best_score=0

    for candidate in "${candidates[@]}"; do
        # Skip empty candidates
        [ -z "$candidate" ] && continue

        local score=$(calculate_similarity "$target" "$candidate")

        # Bonus for prefix match (first 3 characters)
        local target_prefix="${target:0:3}"
        local cand_prefix="${candidate:0:3}"
        if [[ "$target_prefix" == "$cand_prefix" ]]; then
            score=$((score + 30))
            [ $score -gt 100 ] && score=100
        fi

        # Bonus for containing similar characters
        local target_first="${target:0:1}"
        local cand_first="${candidate:0:1}"
        if [[ "$target_first" == "$cand_first" ]]; then
            score=$((score + 10))
            [ $score -gt 100 ] && score=100
        fi

        if [ $score -gt $best_score ] && [ $score -ge $min_threshold ]; then
            best_score=$score
            best_match="$candidate"
        fi
    done

    echo "$best_match"
}

# Find similar commands in a category
# Args: category misspelled_command
# Returns: most similar command name (or empty)
find_similar_command() {
    local category="$1"
    local misspelled="$2"

    # Get current OS if available, otherwise skip OS filtering
    local current_os=""
    if declare -f get_simple_os &> /dev/null; then
        current_os=$(get_simple_os)
    fi

    # Get all commands for the category
    local commands=""
    if [ -n "$current_os" ]; then
        commands=$(get_category_commands "$category" "$current_os" 2> /dev/null || echo "")
    else
        # Fallback: get all commands without OS filtering
        commands=$(cache_query ".commands[] | select(.category == \"$category\") | .name" 2> /dev/null || echo "")
    fi

    # Convert to array
    local -a cmd_array
    while IFS= read -r cmd; do
        [ -n "$cmd" ] && cmd_array+=("$cmd")
    done <<< "$commands"

    # Find most similar
    if [ ${#cmd_array[@]} -gt 0 ]; then
        find_most_similar "$misspelled" "${cmd_array[@]}"
    fi
}

# Find similar category
# Args: misspelled_category
# Returns: most similar category name (or empty)
find_similar_category() {
    local misspelled="$1"

    # Get all categories (top-level only, no /)
    local categories=$(get_all_categories "$GLOBAL_CONFIG_FILE" 2> /dev/null | grep -v "/" || echo "")

    # Convert to array
    local -a cat_array
    while IFS= read -r cat; do
        [ -n "$cat" ] && cat_array+=("$cat")
    done <<< "$categories"

    # Find most similar
    if [ ${#cat_array[@]} -gt 0 ]; then
        find_most_similar "$misspelled" "${cat_array[@]}"
    fi
}

# Find similar subcategory within a category
# Args: category misspelled_subcategory
# Returns: most similar subcategory name (or empty)
find_similar_subcategory() {
    local category="$1"
    local misspelled="$2"

    # Get all subcategories for the category
    local subcats=$(get_category_subcategories "$category" 2> /dev/null || echo "")

    # Convert to array
    local -a subcat_array
    while IFS= read -r subcat; do
        [ -n "$subcat" ] && subcat_array+=("$subcat")
    done <<< "$subcats"

    # Find most similar
    if [ ${#subcat_array[@]} -gt 0 ]; then
        find_most_similar "$misspelled" "${subcat_array[@]}"
    fi
}

# Show suggestion message for similar match
# Args: type (category/command/subcategory) misspelled similar
show_similarity_suggestion() {
    local type="$1"
    local misspelled="$2"
    local similar="$3"

    if [ -n "$similar" ]; then
        case "$type" in
            category)
                log_output "${GRAY}Você quis dizer ${BOLD}$similar${GRAY}?${NC}"
                ;;
            command)
                log_output "${GRAY}Você quis dizer ${BOLD}$similar${GRAY}?${NC}"
                ;;
            subcategory)
                log_output "${GRAY}Você quis dizer ${BOLD}$similar${GRAY}?${NC}"
                ;;
        esac
    fi
}
