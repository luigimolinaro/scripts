#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor qw(colored);

# Function to check if a command exists
sub command_exists {
    my ($cmd) = @_;
    system("command -v $cmd >/dev/null 2>&1");
    return $? == 0;
}

# Ensure nc is installed
unless (command_exists('nc')) {
    die colored("Error: 'nc' command not found. Please install netcat.\n", 'red');
}

# Define the hostnames and ports in a hash
my %hosts = (
    "icr.io" => 443,
    "cp.icr.io" => 443,
    "gcr.io" => 443,
    "registry.redhat.io" => 443,
    "cdn02.quay.io" => 443,
    "cdn03.quay.io" => 443,
    "rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com" => 443,
    "cert-api.access.redhat.com" => 443,
    "access.redhat.com" => 443,
    "api.access.redhat.com" => 443,
    "infogw.api.openshift.com" => 443,
    "console.redhat.com/api/ingress" => 443,
    "cloud.redhat.com/api/ingress" => 443,
    "mirror.openshift.com" => 443,
    "storage.googleapis.com/openshift-release" => 443,
    "quayio-production-s3.s3.amazonaws.com" => 443,
    "api.openshift.com" => 443,
    "art-rhcos-ci.s3.amazonaws.com" => 443,
    "console.redhat.com/openshift" => 443,
    "cloud.redhat.com/openshift" => 443,
    "registry.access.redhat.com" => 443,
    "sso.redhat.com" => 443,
    "secure.esupport.ibm.com" => 443,
);

# Function to check a port on a host
sub check_port {
    my ($host, $port) = @_;
    system("nc -z -w5 $host $port 2>/dev/null");
    return $? == 0;
}

# Loop through the hash and check the specified ports
for my $full_host (keys %hosts) {
    my $port = $hosts{$full_host};
    my ($host) = split('/', $full_host, 2); # Remove everything after the first slash (if any)
    
    print "Checking $host on port $port: ";
    if (check_port($host, $port)) {
        print colored("✓", 'green');
    } else {
        print colored("✗", 'red');
    }
    
    print "\nChecking $host on port 80: ";
    if (check_port($host, 80)) {
        print colored("✓", 'green');
    } else {
        print colored("✗", 'red');
    }
    print "\n";
}
