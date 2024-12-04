#!/bin/bash

# Configurable variables
OPENSHIFT_URL="URL" 
OPENSHIFT_USER="kubeadmin"                                
OPENSHIFT_PASSWORD="xxx"                                  
GKLM_SCRIPT="/tmp/secondoScript.bash"

# Function to authenticate to OpenShift
function authenticate_openshift() {
    echo "Authenticating to OpenShift at $OPENSHIFT_URL..."
    # Perform the OpenShift login
    oc login "$OPENSHIFT_URL" -u "$OPENSHIFT_USER" -p "$OPENSHIFT_PASSWORD" --insecure-skip-tls-verify=true
    # Check if the login command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to authenticate to OpenShift. Exiting."
        exit 1
    fi
    echo "Successfully authenticated."
}

# Function to execute the second script
function gklm_script() {
    # Check if the second script exists
    if [ -f "$GKLM_SCRIPT" ]; then
        echo "Executing GKLM script: $GKLM_SCRIPT"
        # Run the second script
        bash "$GKLM_SCRIPT"
        # Check if the script execution was successful
        if [ $? -ne 0 ]; then
            echo "GKLM script execution failed. Exiting."
            exit 1
        fi
        echo "GKLM script executed successfully."
    else
        echo "GKLM script not found at $GKLM_SCRIPT. Exiting."
        exit 1
    fi
}

# Main script execution
authenticate_openshift
gklm_script    

