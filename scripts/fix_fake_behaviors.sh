#!/bin/bash

# Determine which sed to use (gsed preferred, fallback to sed)
if command -v gsed &>/dev/null; then
    sed_cmd="gsed"
elif sed --version 2>/dev/null | grep -q GNU; then
    sed_cmd="sed"
else
    >&2 echo "Neither gsed nor GNU sed is available. Please install one of them."
    exit 1
fi

# Check if the input file exists
input_file="config/jaan.keymap"
if [ ! -f "$input_file" ]; then
    >&2 echo "Error: Input file $input_file not found."
    exit 1
fi

# Create a backup of the input file
backup_file="${input_file}.bak"
cp "$input_file" "$backup_file"

# Process the input file
$sed_cmd -i \
    -e '/fake_.*_behavior/!{s/\(<[^>]*\)fake_\([^<> ]*\)/\1\2/g}' \
    -e '/fake_.*_behavior/!{s/\<fake_\([^<> &]*\)\>/\1     /g}' \
    -e '38s#^// ##' \
    "$input_file"

# Notify the user
echo "File processed successfully. Backup created at $backup_file."

