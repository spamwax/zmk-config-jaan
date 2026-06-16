#!/usr/bin/env bash
set -u

PATH="$PATH:$HOME/Library/Application Support/Code - Insiders/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"

remote_name="${1:-}"
remote_url="${2:-}"

# Customize these.
protected_remotes_regex='^(origin)$'
protected_branches_regex='^(keymap-editor)$'

should_run_checks=false

if [ "$#" -eq 0 ]; then
    echo "manual: running devcontainer build from shell."
    should_run_checks=true
else
    echo "pre-push: remote_name=$remote_name"
    echo "pre-push: remote_url=$remote_url"

    while read -r local_ref local_sha remote_ref remote_sha
    do
        local_branch="${local_ref#refs/heads/}"
        remote_branch="${remote_ref#refs/heads/}"

        echo "pre-push: $local_branch -> $remote_name/$remote_branch"

        # Skip branch deletes.
        if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
            echo "pre-push: branch deletion detected; skipping checks for $remote_branch"
            continue
        fi

        if [[ "$remote_name" =~ $protected_remotes_regex ]] && [[ "$remote_branch" =~ $protected_branches_regex ]]; then
            should_run_checks=true
        fi
    done

    if [ "$should_run_checks" != true ]; then
        echo "pre-push: skipping devcontainer build for this remote/branch."
        exit 0
    fi
fi

PROJECT_PATH="$(pwd)"
BUILD_LOG_PATH="/tmp/_mydevcontainer_build.log"
DEVCONTAINER_CMD=(devcontainer-insiders exec --workspace-folder "$PROJECT_PATH" -- direnv exec . just build all)

echo "Running protected pre-push checks..."

rm -f "$BUILD_LOG_PATH"

RUNNING="$(docker ps --filter "label=devcontainer.local_folder=$PROJECT_PATH" --quiet)"

if [ -n "$RUNNING" ]; then
    echo "Devcontainer is already running, building the firmware..."
else
    echo "Devcontainer is not running. Starting it..."

    UP_OUTPUT="$(devcontainer-insiders up --workspace-folder "$PROJECT_PATH" --log-level=debug 2>&1)"
    UP_EXIT_CODE=$?

    if [ "$UP_EXIT_CODE" -ne 0 ]; then
        echo "Failed to start the devcontainer. Exiting."
        echo "$UP_OUTPUT"
        exit "$UP_EXIT_CODE"
    fi
fi

"${DEVCONTAINER_CMD[@]}"
SCRIPT_EXIT_CODE=$?

printf "\n\n"

if [ "$SCRIPT_EXIT_CODE" -ne 0 ]; then
    echo "Pre-push checks failed. Aborting push."

    if [ -f "$BUILD_LOG_PATH" ]; then
        cat "$BUILD_LOG_PATH"
        echo
        echo "Above is the build log, which can be found at $BUILD_LOG_PATH"
    else
        echo "No build log found at $BUILD_LOG_PATH"
    fi

    exit 1
fi

echo "Pre-push checks passed. Proceeding with push."
exit 0
