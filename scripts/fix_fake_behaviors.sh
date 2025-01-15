#!/bin/bash

# Ensure GNU sed is available
GNU_SED=$(command -v gsed || echo "")

if [[ -z "$GNU_SED" ]]; then
    echo "GNU sed (gsed) is not installed. Please install it via 'brew install gnu-sed'."
    exit 1
fi

# File to process
INPUT_FILE="./config/jaan.keymap"

# Process the file using GNU sed with backup creation
"$GNU_SED" -E -i.bak '
37,38 s|^// ||;  # Uncomment lines 37 to 38
/fake_[^:]*:/! s/\&fake_([a-zA-Z0-9_]+)/\&\1     /g  # Perform substitutions for fake_ references and add 5 spaces
' "$INPUT_FILE"

# Copy the modified input file to the output file
cp "$INPUT_FILE" "$OUTPUT_FILE"

echo "Processed $INPUT_FILE, backup created as ${INPUT_FILE}.bak
