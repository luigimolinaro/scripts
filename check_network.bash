#!/bin/bash

# Define the URLs and ports
declare -A urls_ports=(
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

# Arrays to store the results
open_urls=()
closed_urls=()

# Function to check URL and port using curl (for HTTPS) and nc (for general TCP)
check_url() {
    local url=$1
    local port=$2

    if [ "$port" -eq 443 ]; then
        # Check HTTPS port with curl
        if curl -s --head --request GET https://$url:$port | grep "200 OK" > /dev/null; then
            echo -e "$url:$port ✔️"
            open_urls+=("$url:$port")
        else
            echo -e "$url:$port ❌"
            closed_urls+=("$url:$port")
        fi
    else
        # Check port with netcat
        if nc -z -w 5 $url $port; then
            echo -e "$url:$port ✔️"
            open_urls+=("$url:$port")
        else
            echo -e "$url:$port ❌"
            closed_urls+=("$url:$port")
        fi
    fi
}

# Iterate over URLs and ports to check them
for url in "${!urls_ports[@]}"; do
    ports=${urls_ports[$url]}
    # Prioritize port 443 if available, otherwise use port 80
    if [[ "$ports" == *"443"* ]]; then
        check_url $url 443
    else
        check_url $url 80
    fi
done

# Summary
echo -e "\nSummary:"
echo -e "\nOpen URLs:"
for open in "${open_urls[@]}"; do
    echo -e "$open ✔️"
done

echo -e "\nClosed URLs:"
for closed in "${closed_urls[@]}"; do
    echo -e "$closed ❌"
done
