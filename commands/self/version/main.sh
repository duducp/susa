#!/bin/bash

# Parse arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        -n|--number)
            show_number_version
            ;;
        *)
            show_version
            ;;
    esac
else
    # Default: show full version
    show_version
fi
