#!/bin/sh
#
# Force delete OpenShift namespaces stuck in "Terminating" state.
# Source: https://blog.jefferyb.me/force-delete-openshift-project-namespace/
#
# This script helps delete namespaces in an OpenShift cluster that are stuck in a terminating state and cannot be removed using the standard "oc delete project <namespace>" command.
#
# Example error message:
# "Error from server (Conflict): Operation cannot be fulfilled on namespaces '<namespace>': The system is ensuring all content is removed from this namespace. Upon completion, this namespace will automatically be purged by the system."
#

# Display usage instructions
show_help() {
  echo "
Usage:
  -n: List of namespaces to delete
  -u: OpenShift server's REST API URL. Default: 'oc whoami --show-server'
  -t: Authentication token. Default: 'oc whoami -t'

Examples:
  # Get help:
  ./force-delete-openshift-project -h
  
  # Delete a single namespace 'test123':
  ./force-delete-openshift-project -n test123
  
  # Delete multiple namespaces, e.g., 'test123 alpha beta':
  ./force-delete-openshift-project -n 'test123 alpha beta'

  # Specify a custom server URL:
  ./force-delete-openshift-project -n test123 -u https://console.example.com:8443
  
  # Provide a specific token:
  ./force-delete-openshift-project -n test123 -t <your_token>
"
}

# Parse options
while getopts n:u:t:h option; do
  case "${option}" in
    n) NAMESPACE_LIST=${OPTARG};;
    u) REST_API_URL=${OPTARG};;
    t) TOKEN=${OPTARG};;
    h) show_help; exit 0;;
    *) echo "Invalid option"; show_help; exit 1;;
  esac
done

# Default to the current OpenShift session's server and token if not provided
OC_SERVER_URL="${REST_API_URL:-$(oc whoami --show-server)}"
OC_TOKEN="${TOKEN:-$(oc whoami -t)}"

if [ -z "$NAMESPACE_LIST" ]; then
  echo "Error: No namespaces specified. Use -n to specify namespaces."
  show_help
  exit 1
fi

echo "Starting to delete namespaces: ${NAMESPACE_LIST}"
for namespace in ${NAMESPACE_LIST}; do
  echo "Deleting namespace: ${namespace}"
  oc get ns "${namespace}" -o json > "${namespace}-finalizer.json"
  sed -i '/"kubernetes"/d' "${namespace}-finalizer.json"

  # Send delete request
  curl --silent --insecure -H "Content-Type: application/json" \
       -H "Authorization: Bearer ${OC_TOKEN}" \
       -X PUT --data-binary @"${namespace}-finalizer.json" \
       "${OC_SERVER_URL}/api/v1/namespaces/${namespace}/finalize"
  
  # Clean up
  rm -f "${namespace}-finalizer.json"
done

echo "Namespace deletion process completed."
