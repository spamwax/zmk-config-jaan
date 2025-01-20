#!/bin/bash

# File paths
TASKS_FILE=".vscode/tasks.json"
TEMP_FILE="${TASKS_FILE}.tmp"

# Ensure the tasks.json file exists
if [[ ! -f "$TASKS_FILE" ]]; then
    echo "Error: $TASKS_FILE not found. Ensure you are in the correct directory."
    exit 1
fi

# Validate tasks.json syntax
if ! jq empty "$TASKS_FILE"; then
    echo "Error: $TASKS_FILE contains invalid JSON. Fix the file before proceeding."
    exit 1
fi

# Extract recipes for `recipeSelection`
RECIPES=$(/usr/bin/env just --list | awk '/^[ ]{4}/ {gsub(/^[ ]+/, "", $0); print $1}')
if [[ -z "$RECIPES" ]]; then
    echo "Error: No recipes found. Ensure 'just --list' produces valid output."
    exit 1
fi

# Generate JSON array for `recipeSelection`
OPTIONS_JSON=$(echo "$RECIPES" | jq -R . | jq -s .)
if [[ -z "$OPTIONS_JSON" ]]; then
    echo "Error: Failed to generate JSON options. Check the recipe extraction."
    exit 1
fi

# Debug: Print generated JSON for recipeSelection
echo "Generated JSON for recipeSelection:"
echo "$OPTIONS_JSON"

# Parse `just list` output for `targetSelection` (extracting only the first part of each item)
RAW_LIST=$(/usr/bin/env just list)
TARGETS=$(echo "$RAW_LIST" | awk '
    BEGIN { item = "" }
    {
        if ($1 ~ /,/) {
            if (item != "") {
                print item
                item = ""
            }
            split($0, parts, " ")
            item = parts[1]
        }
    }
    END { if (item != "") print item }
' | jq -R . | jq -s .)

# Prepend "all" to the parsed target list
TARGETS_JSON=$(echo '["all"]' | jq --argjson targets "$TARGETS" '. + $targets')

# Debug: Print generated JSON for targetSelection
echo "Generated JSON for targetSelection:"
echo "$TARGETS_JSON"

# Ensure the inputs array exists and update both options
jq --argjson recipes "$OPTIONS_JSON" --argjson targets "$TARGETS_JSON" '
    if .inputs == null then
        .inputs = [
            {
                "id": "recipeSelection",
                "type": "pickString",
                "description": "Select a recipe to run:",
                "options": $recipes
            },
            {
                "id": "targetSelection",
                "type": "pickString",
                "description": "Select a target to build (only shown for `build`):",
                "options": $targets
            }
        ]
    else
        .inputs |= map(
            if .id == "recipeSelection" then
                .options = $recipes
            elif .id == "targetSelection" then
                .options = $targets
            else
                .
            end
        )
    end
' "$TASKS_FILE" > "$TEMP_FILE"

if [[ $? -ne 0 ]]; then
    echo "Error: jq failed to update $TASKS_FILE. Check the file for unexpected structures."
    rm -f "$TEMP_FILE"
    exit 1
fi

# Replace original tasks.json with updated version
mv "$TEMP_FILE" "$TASKS_FILE"
echo "Updated $TASKS_FILE successfully with recipes and targets."