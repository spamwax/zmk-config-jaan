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
if ! mkdir -p "$BASE_DIR"; then
  echo "🔴 Failed to create base directory: $BASE_DIR" >&2
  exit 4 # Exit with error code 4 if mkdir fails
fi

# Process JSON and check if there are repositories to process
REPO_LIST=$(echo "$JSON_INPUT" | jq -r '
  .manifest.projects[] as $project
  | .manifest.remotes[] | select(.name == $project.remote)
  | { name: $project.name, url: (.["url-base"] + "/" + $project.name), clone_path: $project.remote }
  | select(.name != "zmk")
  | "\(.name) \(.url) \(.clone_path)"
')

if [[ -z "$REPO_LIST" ]]; then
  echo "🔴 No repositories found in JSON input." >&2
  exit 2 # Exit with code 2 if jq output is empty
fi

# Flag to track if cloning was successful
CLONED_PROJECTS=""

# Process each repository
while read -r PROJECT_NAME REPO_URL CLONE_PATH; do
  # Ensure the values are valid
  if [[ -z "$PROJECT_NAME" || -z "$REPO_URL" ]]; then
    echo "🥴 Skipping invalid entry: $PROJECT_NAME $REPO_URL" >&2
    continue
  fi

  # Destination directory
  DEST_DIR="$BASE_DIR/$CLONE_PATH/$PROJECT_NAME"

  # Clone the repository
  if [[ ! -d "$DEST_DIR" ]]; then
    echo "📗 Cloning $REPO_URL into $DEST_DIR..." >&2
    if git clone "$REPO_URL" "$DEST_DIR" >&2; then
      CLONED_PROJECTS="${CLONED_PROJECTS:+$CLONED_PROJECTS }$PROJECT_NAME"
    else
      echo "🔴 Failed to clone $REPO_URL. Please check permissions or the repository URL." >&2
      exit 3 # Exit immediately if cloning fails
    fi
  else
    # echo "Repository $PROJECT_NAME already exists in $DEST_DIR. Skipping." >&2
    CLONED_PROJECTS="${CLONED_PROJECTS:+$CLONED_PROJECTS }$PROJECT_NAME"
  fi
done <<< "$REPO_LIST"

# Output the names of successfully cloned or already cloned projects
if [[ -n "$CLONED_PROJECTS" ]]; then
  echo "$CLONED_PROJECTS" # Only project names printed to stdout
  exit 0 # Cloning was done successfully
else
  exit 1 # No cloning was performed (all repos already exist)
fi
