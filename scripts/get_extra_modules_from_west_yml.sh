#!/bin/bash

# Usage: ./script.sh [-p] [yaml_file]

# Parse arguments
PURGE=false
YAML_FILE=""
DEST_DIR="/workspace/zmk/modules"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      PURGE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-p] [yaml_file]"
      echo "  -p: Purge (remove) existing clone folders before cloning."
      echo "  yaml_file: YAML file to read (or use stdin if not provided)."
      exit 0
      ;;
    *)
      YAML_FILE="$1"
      shift
      ;;
  esac
done

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed." >&2
  exit 2
fi

# Read YAML content
if [[ -n "$YAML_FILE" ]]; then
  if [[ ! -f "$YAML_FILE" ]]; then
    echo "Error: File '$YAML_FILE' not found." >&2
    exit 2
  fi
  YAML_CONTENT=$(cat "$YAML_FILE")
else
  YAML_CONTENT=$(cat)
fi

# Check for the presence of the 'zmk' project
HAS_ZMK=$(echo "$YAML_CONTENT" | yq -r '.manifest.projects[] | select(.name == "zmk") | .name')

# Process YAML to extract projects
# shellcheck disable=SC2016
PROJECTS=$(echo "$YAML_CONTENT" | yq -r '
  .manifest.projects[] as $project
  | .manifest.remotes[] as $remote
  | select($remote.name == $project.remote)
  | select($project.name != "zmk")
  | .name = $project.name
  | .url = ($remote["url-base"] + "/" + $project.name)
  | .clone_path = ($project.remote + "/" + $project.name)
  | .name + " " + .url + " " + .clone_path
')

if [[ -z "$HAS_ZMK" ]]; then
  echo "No 'zmk' project found in the YAML file." >&2
  exit 2
fi

if [[ -z "$PROJECTS" ]]; then
  if [[ -z "$HAS_ZMK" ]]; then
    echo "No valid projects found in the YAML file, and 'zmk' is also missing." >&2
    RESULT=""
    exit 2
  fi
  echo "No valid projects found in the YAML file." >&2
  RESULT=""
  exit 4
fi

# Clone or skip projects
CLONED_PROJECTS=()
while IFS= read -r project; do
  NAME=$(echo "$project" | awk '{print $1}')
  URL=$(echo "$project" | awk '{print $2}')
  CLONE_PATH=$(echo "$project" | awk '{print $3}')

  # Prepend DEST_DIR to clone_path
  CLONE_PATH="$DEST_DIR/$CLONE_PATH"

  # Handle purge option
  if [[ "$PURGE" == true && -d "$CLONE_PATH" ]]; then
    echo "Removing existing folder for $NAME at $CLONE_PATH..." >&2
    rm -rf "$CLONE_PATH"
  fi

  # Skip cloning if folder already exists
  if [[ -d "$CLONE_PATH" ]]; then
    echo "Skipping $NAME: folder already exists at $CLONE_PATH." >&2
    CLONED_PROJECTS+=("$(realpath "$CLONE_PATH")")
    continue
  fi

  # Clone the repository
  echo "Cloning $NAME from $URL into $CLONE_PATH..." >&2
  if ! git clone "$URL" "$CLONE_PATH"; then
    echo "Failed to clone $NAME." >&2
    exit 3
  else
    CLONED_PROJECTS+=("$(realpath "$CLONE_PATH")")
  fi
done <<< "$PROJECTS"

# Output concatenated paths of cloned/skipped projects without polluting stdout
if [[ ${#CLONED_PROJECTS[@]} -eq 0 ]]; then
  RESULT=""
  echo "No projects were cloned or skipped." >&2
  exit 1
else
  RESULT=$(IFS=\;; echo "${CLONED_PROJECTS[*]}")
  echo "$RESULT"
  exit 0
fi
