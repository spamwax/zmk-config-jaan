#!/bin/bash

PATH="$PATH:$HOME/Library/Application Support/Code - Insiders/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"
# Define your project path (absolute path to your workspace folder)
PROJECT_PATH="$PWD"
DEVCONTAINER_CMD="devcontainer-insiders exec -- direnv exec . just build all"
echo "Running pre-push checks..."

# Remove the previous build log
build_log_path="/tmp/_mydevcontainer_build.log"
rm -f "$build_log_path"

# Check if the devcontainer is running
RUNNING=$(docker ps --filter "label=devcontainer.local_folder=$PROJECT_PATH" --quiet) #  --format "{{.ID}}")
if [ -n "$RUNNING" ]; then
    echo "Devcontainer is already running, building the firmware..."
else
    echo "Devcontainer is not running. Starting it..."
    devcontainer-insiders up
fi

$DEVCONTAINER_CMD
SCRIPT_EXIT_CODE=$?

if [ $SCRIPT_EXIT_CODE -ne 0 ]; then
    echo "Pre-push checks failed. Aborting push."
    cat "$build_log_path"
    echo
    echo "Above is the build log, which can be found at $build_log_path"
    exit 1
fi

echo "Pre-push checks passed. Proceeding with push."
exit 0
