#!/bin/bash

export DIRENV_LOG_FORMAT=''

# Ensure direnv environment is loaded
eval "$(direnv export bash)" || { echo "Error: Failed to load direnv environment."; exit 1; }

# Argument: Selected recipe
RECIPE=$1

# Temporary file for communication
TEMP_FILE="./scripts/temp_status.txt"

# Write the recipe and decision for Task B
echo "recipe=$RECIPE" > "$TEMP_FILE"
if [[ "$RECIPE" == "build" ]]; then
    echo "shouldRunTaskB=true" >> "$TEMP_FILE"
else
    echo "shouldRunTaskB=false" >> "$TEMP_FILE"
    # Execute non-build recipe directly
    direnv exec . just "$RECIPE"
    exit 1
fi
