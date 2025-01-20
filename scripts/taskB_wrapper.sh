#!/bin/bash

export DIRENV_LOG_FORMAT=''
# Ensure direnv environment is loaded
eval "$(direnv export bash)" || { echo "Error: Failed to load direnv environment."; exit 1; }

# Argument: Selected target
TARGET=$1

# Temporary file for communication
TEMP_FILE="./scripts/temp_status.txt"

# Ensure Task A has run
if [[ ! -f "$TEMP_FILE" ]]; then
    echo "Error: Task A must run before Task B."
    exit 1
fi

# Read the recipe and flag
source "$TEMP_FILE"

# Check if Task B should run
if [[ "$shouldRunTaskB" == "true" ]]; then
    if [[ -n "$TARGET" ]]; then
        direnv exec . just build "$TARGET"
    else
        echo "Error: No target selected."
        exit 1
    fi
fi
