#!/bin/bash

# Define the hostnames and ports in an associative array
declare -A HOSTS=(
  ["icr.io"]="443"
  ["cp.icr.io"]="443"
  ["gcr.io"]="443"
  ["registry.redhat.io"]="443"
  ["cdn02.quay.io"]="443"
  ["cdn03.quay.io"]="443"
  ["rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com"]="443"
  ["cert-api.access.redhat.com"]="443"
  ["access.redhat.com"]="443"
  ["api.access.redhat.com"]="443"
  ["infogw.api.openshift.com"]="443"
  ["console.redhat.com/api/ingress"]="443"
  ["cloud.redhat.com/api/ingress"]="443"
  ["mirror.openshift.com"]="443"
  ["storage.googleapis.com/openshift-release"]="443"
  ["quayio-production-s3.s3.amazonaws.com"]="443"
  ["api.openshift.com"]="443"
  ["art-rhcos-ci.s3.amazonaws.com"]="443"
  ["console.redhat.com/openshift"]="443"
  ["cloud.redhat.com/openshift"]="443"
  ["registry.access.redhat.com"]="443"
  ["sso.redhat.com"]="443"
  ["secure.esupport.ibm.com"]="443"
)

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check a port on a host
check_port() {
  local host=$1
  local port=$2

  if nc -z -w5 $host $port 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
  fi
}

# Loop through the associative array and check the specified ports
for full_host in "${!HOSTS[@]}"; do
  port=${HOSTS[$full_host]}
  host=${full_host%%/*} # Remove everything after the first slash (if any)
  echo -n "Checking $host on port $port: "
  check_port $host $port
  echo -n "Checking $host on port 80: "
  check_port $host 80
done
