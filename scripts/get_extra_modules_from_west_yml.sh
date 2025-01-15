#!/bin/bash

# Check if a file name is provided or use standard input
if [[ -n "$1" ]]; then
  JSON_INPUT=$(cat "$1")
else
  JSON_INPUT=$(cat -)
fi

# Base directory for cloning
BASE_DIR="/workspace/zmk/modules"

# Create the base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Process JSON and clone repositories
echo "$JSON_INPUT" | jq -r '
  .manifest.projects[] as $project
  | .manifest.remotes[] | select(.name == $project.remote)
  | { name: $project.name, url: (.["url-base"] + "/" + $project.name) }
  | select(.name != "zmk")
  | "\(.name) \(.url)"
' | while read -r PROJECT_NAME REPO_URL; do
  # Ensure the values are valid
  if [[ -z "$PROJECT_NAME" || -z "$REPO_URL" ]]; then
    echo "Skipping invalid entry: $PROJECT_NAME $REPO_URL"
    continue
  fi

  # Destination directory
  DEST_DIR="$BASE_DIR/$PROJECT_NAME"

  # Clone the repository
  if [[ ! -d "$DEST_DIR" ]]; then
    echo "Cloning $REPO_URL into $DEST_DIR..."
    git clone "$REPO_URL" "$DEST_DIR"
  else
    echo "Repository $PROJECT_NAME already exists in $DEST_DIR. Skipping."
  fi
done
