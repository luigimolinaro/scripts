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

# Execute the additional DB2 configuration commands in the specific pod
DB2_POD="c-db2oltp-wkc-db2u-0"
echo "Executing DB2 configuration commands in pod: $DB2_POD"
oc exec -it "$DB2_POD" -- bash -c "
    db2 update database configuration for BGDB using LOGSECOND 128 &&
    db2 update database configuration for BGDB using LOGFILSIZ 10240
"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] DB2 configuration updated successfully${NC}"
else
    echo -e "${RED}[ERROR] Failed to update DB2 configuration${NC}"
    exit 1
fi


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


# Get the pod name of the IMPORT POD dynamically
CPD_AUX_POD_NAME=$(oc get pods --no-headers -o custom-columns=":metadata.name" | grep cpd-aux-)

# Check if the pod name was found
if [ -z "$CPD_AUX_POD_NAME" ]; then
    echo -e "${RED}[ERROR] No pod found with name containing 'cpd-aux-'.${NC}"
    exit 1
fi

echo "Found pod: $CPD_AUX_POD_NAME"

# Get uid, gid and groups from the pod
USER_INFO=$(oc rsh "$CPD_AUX_POD_NAME" id)

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to retrieve user information from the pod.${NC}"
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

# Copy the new tar file to the pod
echo "Copying $NEW_TAR_FILE to the pod $CPD_AUX_POD_NAME:/data/cpd/data/exports/wkc"
oc cp "$NEW_TAR_FILE" "$CPD_AUX_POD_NAME:/data/cpd/data/exports/wkc/"
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to copy $NEW_TAR_FILE to the pod.${NC}"
    exit 1
fi

# Untar the copied tar file and remove the tar file inside the pod
echo "Untarring the copied tar file inside the pod $CPD_AUX_POD_NAME"
oc exec -it "$CPD_AUX_POD_NAME" -- bash -c "
    cd /data/cpd/data/exports/wkc &&
    tar -xf $NEW_TAR_FILE &&
    rm -f $NEW_TAR_FILE
"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Tar file extracted and removed successfully inside the pod${NC}"
else
    echo -e "${RED}[ERROR] Failed to extract and remove tar file inside the pod${NC}"
    exit 1
fi
