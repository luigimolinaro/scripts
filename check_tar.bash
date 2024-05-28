#!/bin/bash
# Developed by luigi.molinaro@ibm.com


# Function to cleanup extracted directory
cleanup() {
    if [ -n "$EXTRACTED_DIR" ] && [ -d "$EXTRACTED_DIR" ]; then
        echo "Cleaning up extracted directory..."
        rm -rf "$EXTRACTED_DIR"
    fi
}

# Trap cleanup function on exit
trap cleanup EXIT

# Color variables
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if a filename is provided as a parameter
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <filename.tar.gz>${NC}"
    exit 1
fi

# Get the filename from the first parameter
TAR_FILE="$1"

# Extract the contents of the .tar.gz file
EXTRACTED_DIR=$(mktemp -d)
echo "Extracting contents of $TAR_FILE to $EXTRACTED_DIR..."
tar -xf "$TAR_FILE" -C "$EXTRACTED_DIR"

# List contents of the .tar.gz file
echo "Checking integrity of $TAR_FILE..."
tar -tf "$TAR_FILE" > /dev/null 2>&1
TAR_LIST_RESULT=$?

# Check for errors in nested zip files
echo "Checking integrity of nested zip files..."
if ! find "$EXTRACTED_DIR" -name "*.zip" -exec unzip -tq {} \;; then
    echo -e "${RED}There are errors in nested zip files.${NC}"
    exit 1
fi

# Exit if there are errors in the tar file
if [ $TAR_LIST_RESULT -ne 0 ]; then
    echo -e "${RED}[ERROR] There are errors in $TAR_FILE.${NC}"
    exit 1
else
    echo -e "${GREEN}[OK] tar file is ok${NC}"
fi


# Get the pod name dynamically
POD_NAME=$(oc get pods --no-headers -o custom-columns=":metadata.name" | grep common-web-ui-)

# Check if the pod name was found
if [ -z "$POD_NAME" ]; then
    echo -e "${RED}No pod found with name containing 'common-web-ui-'.${NC}"
    exit 1
fi

echo "Found pod: $POD_NAME"

# Get uid, gid and groups from the pod
USER_INFO=$(oc rsh "$POD_NAME" id)

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to retrieve user information from the pod.${NC}"
    exit 1
fi

echo "Retrieved ID from pod= $USER_INFO"

# Extract UID (only the first number) and groups
USER_UID=$(echo "$USER_INFO" | awk -F'[=(]' '/uid/{print $2}')
USER_GROUPS=$(echo "$USER_INFO" | awk -F'[=(]' '/groups/{print $2}')

echo "Retrieved user info: uid=$USER_UID, groups=$USER_GROUPS"

# Set the permissions of the extracted files
echo "Setting permissions of the extracted files..."
chown -R "$USER_UID:$USER_GROUPS" "$EXTRACTED_DIR"

# Recreate the .tar file without compression with new permissions
echo "Recreating $TAR_FILE without compression with new permissions..."
NEW_TAR_FILE="${TAR_FILE%%.*}.tar"
tar -cf "$NEW_TAR_FILE" -C "$EXTRACTED_DIR" .

# Check the result of the tar operation
if [ $? -eq 0 ]; then
    echo "New .tar file created: $NEW_TAR_FILE"
    echo -e "${GREEN}[OK] New tar ricreated with right permission${NC}"
else
    echo -e "${RED}[ERROR]There seem to be problems with recreating the .tar file.${NC}"
fi
