#!/bin/bash

# Check if a filename is provided as a parameter
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename.tar.gz>"
    exit 1
fi

# Get the filename from the first parameter
TAR_FILE="$1"

# Extract the contents of the .tar.gz file
tar -xzvf "$TAR_FILE"

# Check the integrity of the .tar.gz file
echo "Checking integrity of the .tar.gz file..."
tar --check -zvf "$TAR_FILE"

# Check the integrity of nested zip files
echo "Checking integrity of nested zip files..."
find . -name "*.zip" -exec unzip -t {} \;

# Check the result of the checks
if [ $? -eq 0 ]; then
    echo "Everything seems to be in order."
else
    echo "There seem to be problems with the integrity of the files."
fi
