#!/usr/bin/env zsh

# JSON utility functions using jq
# These functions provide a consistent interface for working with JSON in shell scripts

# Get a field from a JSON config file (used by get_config_field)
# Usage: json_get_config_field <file> <field>
# Example: json_get_config_field "cli.json" "version"
json_get_config_field() {
    local file="$1"
    local field="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -r ".$field // empty" "$file" 2> /dev/null
}

# Get a value from a JSON file using a jq query
# Usage: json_get_value <file> <jq_query>
# Example: json_get_value "file.json" ".version"
json_get_value() {
    local file="$1"
    local query="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -r "$query" "$file" 2> /dev/null
}

# Get a value from a JSON string using a jq query
# Usage: json_get_value_from_string <json_string> <jq_query>
# Example: json_get_value_from_string "$json" ".name"
json_get_value_from_string() {
    local json_string="$1"
    local query="$2"

    echo "$json_string" | jq -r "$query" 2> /dev/null
}

# Get an array from a JSON file
# Usage: json_get_array <file> <jq_query>
# Example: json_get_array "file.json" ".items[]"
json_get_array() {
    local file="$1"
    local query="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -r "$query" "$file" 2> /dev/null
}

# Filter array elements from a JSON file
# Usage: json_filter_array <file> <array_path> <filter>
# Example: json_filter_array "file.json" ".plugins" "select(.name == \"test\")"
json_filter_array() {
    local file="$1"
    local array_path="$2"
    local filter="$3"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -r "${array_path}[] | ${filter}" "$file" 2> /dev/null
}

# Get a field from a filtered array element
# Usage: json_get_field_from_array <file> <array_path> <filter> <field>
# Example: json_get_field_from_array "file.json" ".plugins" "select(.name == \"test\")" ".version"
json_get_field_from_array() {
    local file="$1"
    local array_path="$2"
    local filter="$3"
    local field="$4"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -r "${array_path}[] | ${filter} | ${field}" "$file" 2> /dev/null | head -1
}

# Check if a file contains valid JSON
# Usage: json_is_valid <file>
# Returns: 0 if valid, 1 if invalid
json_is_valid() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq empty "$file" 2> /dev/null
    return $?
}

# Create a JSON object with specified fields
# Usage: json_create_object key1 value1 key2 value2 ...
# Example: json_create_object "name" "test" "version" "1.0.0"
json_create_object() {
    local json="{}"

    while [ $# -gt 0 ]; do
        local key="$1"
        local value="$2"
        shift 2

        # Try to detect if value is a number, boolean or needs quotes
        if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [ "$value" = "true" ] || [ "$value" = "false" ] || [ "$value" = "null" ]; then
            json=$(jq --arg k "$key" --argjson v "$value" '. + {($k): $v}' <<< "$json")
        else
            json=$(jq --arg k "$key" --arg v "$value" '. + {($k): $v}' <<< "$json")
        fi
    done

    echo "$json"
}

# Create a JSON array from values
# Usage: json_create_array value1 value2 value3 ...
# Example: json_create_array "item1" "item2" "item3"
json_create_array() {
    local json="[]"

    for value in "$@"; do
        json=$(jq --arg v "$value" '. + [$v]' <<< "$json")
    done

    echo "$json"
}

# Add an object to a JSON array in a file
# Usage: json_add_to_array <file> <array_path> <object_json>
# Example: json_add_to_array "file.json" ".plugins" '{"name":"test","version":"1.0"}'
json_add_to_array() {
    local file="$1"
    local array_path="$2"
    local object_json="$3"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)
    jq "${array_path} += [${object_json}]" "$file" > "$temp_file" && mv "$temp_file" "$file"
}

# Update a value in a JSON file
# Usage: json_update_value <file> <jq_path> <new_value>
# Example: json_update_value "file.json" ".version" "2.0.0"
json_update_value() {
    local file="$1"
    local path="$2"
    local value="$3"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)
    jq --arg v "$value" "${path} = \$v" "$file" > "$temp_file" && mv "$temp_file" "$file"
}

# Remove an element from a JSON array
# Usage: json_remove_from_array <file> <array_path> <filter>
# Example: json_remove_from_array "file.json" ".plugins" "select(.name == \"test\")"
json_remove_from_array() {
    local file="$1"
    local array_path="$2"
    local filter="$3"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)
    jq "${array_path} |= map(select(${filter} | not))" "$file" > "$temp_file" && mv "$temp_file" "$file"
}

# Get the length of an array in a JSON file
# Usage: json_array_length <file> <array_path>
# Example: json_array_length "file.json" ".plugins"
json_array_length() {
    local file="$1"
    local array_path="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq "${array_path} | length" "$file" 2> /dev/null
}

# Pretty print a JSON file
# Usage: json_pretty_print <file>
json_pretty_print() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq '.' "$file"
}

# Compact print a JSON file (minified)
# Usage: json_compact_print <file>
json_compact_print() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq -c '.' "$file"
}

# Merge two JSON objects
# Usage: json_merge <json1> <json2>
# Example: json_merge '{"a":1}' '{"b":2}'
json_merge() {
    local json1="$1"
    local json2="$2"

    jq --argjson obj "$json2" '. + $obj' <<< "$json1"
}
