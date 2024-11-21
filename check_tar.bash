#!/bin/bash
# Developed by luigi.molinaro@ibm.com

# Function to handle error messages and exit
handle_error() {
    local message="$1"
    echo -e "${RED}[ERROR] $message${NC}"
    # cleanup
    exit 1
}

# Function to handle success messages
handle_success() {
    local message="$1"
    echo -e "${GREEN}[OK] $message${NC}"
}

# Function to cleanup temporary directory
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

# Trap cleanup function on exit
trap cleanup EXIT

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define temporary directory
TEMP_DIR="/tmp/tar-temp"

# Ensure the temporary directory is clean
if [ -d "$TEMP_DIR" ]; then
    echo "Temporary directory $TEMP_DIR already exists. Cleaning up..."
    rm -rf "$TEMP_DIR"
fi

# Create temporary directory
mkdir -p "$TEMP_DIR" || handle_error "Failed to create temporary directory $TEMP_DIR"

# Check if a filename is provided as a parameter
if [ $# -eq 0 ]; then
    handle_error "Usage: $0 <filename.tar.gz>"
fi

# Get the filename from the first parameter
TAR_FILE="$1"

# Ensure the tar file exists
if [ ! -f "$TAR_FILE" ]; then
    handle_error "File $TAR_FILE does not exist."
fi

# Extract the contents of the .tar.gz file
echo "Extracting contents of $TAR_FILE to $TEMP_DIR..."
tar -xf "$TAR_FILE" -C "$TEMP_DIR" || handle_error "Failed to extract $TAR_FILE"

# List contents of the .tar.gz file
echo "Checking integrity of $TAR_FILE..."
tar -tf "$TAR_FILE" > /dev/null 2>&1
TAR_LIST_RESULT=$?

# Check for errors in nested zip files
echo "Checking integrity of nested zip files..."
if ! find "$TEMP_DIR" -name "*.zip" -exec unzip -tq {} \; > /dev/null 2>&1; then
    handle_error "There are errors in nested zip files."
fi

# Exit if there are errors in the tar file
if [ $TAR_LIST_RESULT -ne 0 ]; then
    handle_error "There are errors in $TAR_FILE."
else
    handle_success "Tar file is OK"
fi

# Check if the extracted directory is empty before proceeding
if [ -z "$(ls -A "$TEMP_DIR")" ]; then
    handle_error "The temporary directory $TEMP_DIR is empty. Extraction may have failed."
fi

# Find the first directory inside /tmp/tar-temp
TARGET_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

# Ensure a directory was found
if [ -z "$TARGET_DIR" ]; then
    handle_error "No directory found inside $TEMP_DIR."
fi

echo "Found directory to archive: $TARGET_DIR"

# Get the pod name of the IMPORT POD dynamically
CPD_AUX_POD_NAME=$(oc get pods --no-headers -o custom-columns=":metadata.name" | grep cpd-aux-)

# Check if the pod name was found
if [ -z "$CPD_AUX_POD_NAME" ]; then
    handle_error "No pod found with name containing 'cpd-aux-'."
fi

echo "Found pod: $CPD_AUX_POD_NAME"

# Get uid, gid and groups from the pod
USER_INFO=$(oc rsh "$CPD_AUX_POD_NAME" id)
if [ $? -ne 0 ]; then
    handle_error "Failed to retrieve user information from the pod."
fi

echo "Retrieved ID from pod= $USER_INFO"

# Extract UID (only the first number) and groups
USER_UID=$(echo "$USER_INFO" | awk -F'[=(]' '/uid/{print $2}')
USER_GROUPS=$(echo "$USER_INFO" | awk -F'[=(]' '/groups/{print $2}')

echo "Retrieved user info: uid=$USER_UID, groups=$USER_GROUPS"

# Set the permissions of the extracted files
echo "Setting permissions of the extracted files..."
chown -R "$USER_UID:$USER_GROUPS" "$TARGET_DIR" || handle_error "Failed to set permissions on extracted files."

# Recreate the .tar file without compression with new permissions
NEW_TAR_FILE="${TAR_FILE%%.*}_checked.tar"
echo "Recreating $NEW_TAR_FILE with new permissions..."

# Check if the directory is empty before creating new .tar file
if [ -z "$(ls -A "$TARGET_DIR")" ]; then
    handle_error "The directory $TARGET_DIR is empty, cannot recreate the .tar file."
fi

tar -cf "$NEW_TAR_FILE" -C "$TEMP_DIR" "$(basename "$TARGET_DIR")" || handle_error "There seem to be problems with recreating the .tar file."

handle_success "New tar created: $NEW_TAR_FILE"
