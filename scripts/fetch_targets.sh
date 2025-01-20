#!/bin/bash

# Suppress direnv logs
export DIRENV_LOG_FORMAT=''
# Ensure direnv environment is loaded
eval "$(direnv export bash)" || { echo "Error: Failed to load direnv environment."; exit 1; }



# Execute the command
direnv exec . just list 2>/dev/null | awk '
BEGIN { print "all" }
{
    for (i = 1; i <= NF; i++) {
        if ($i ~ /,/) print $i
    }
}'
