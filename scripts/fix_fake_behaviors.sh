#!/bin/bash

# Ensure GNU sed is installed
sed_version=$(gsed --version 2>/dev/null | grep GNU)
if [ -z "$sed_version" ]; then
    >&2 echo "GNU sed is not installed. Please install GNU sed first."
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
gsed -i \
    -e '/fake_.*_behavior/!s/\<fake_\([a-zA-Z0-9_]*\)\>/\1/g' \
    -e '38s#^//##' \
    "$input_file"

# Notify the user
echo "File processed successfully. Backup created at $backup_file."

