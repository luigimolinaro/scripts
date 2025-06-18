#!/bin/bash
#*------------------------------------------------------------
#* Licensed Materials - Property of IBM
#*
#* "Restricted Materials of IBM"
#* (C) Copyright IBM Corp. 2020 All Rights Reserved.
#*
#* US Government Users Restricted Rights - Use, duplication or
#* disclosure restricted by GSA ADP Schedule Contract with
#* IBM Corp.
#*------------------------------------------------------------

#*------------------------------------------------------------
#* Define Defaults
#*    1: Tools Directory
#*------------------------------------------------------------

defineDefaults () {
    if [[ -z $CX ]]; then
        [[ $1 == . ]] || cd $1
        [[ $(pwd) == / ]] || CX=$(dirname $(pwd))
    fi
    [[ -z $CX ]] && CX="/usr/local/CX"
    export CPD_CLI_MANAGE_WORKSPACE=$CX
    Config4ROSA=$CX/data/cx.rosa.json
    [[ -f $Config4ROSA ]] || abort "ROSA Configuration, $Config4ROSA, not found"

    DeployOptions=(Hub IKC MANTA)
}

#*------------------------------------------------------------
#* Replace CX
#*    1: String
#*------------------------------------------------------------

replaceCX () {
    sed -e "s/$(sed -e "s/\//\\\\\//g" <<< $CX)/\$CX/" <<< $1
}

#*------------------------------------------------------------
#* Get Color
#*    1: Color
#*------------------------------------------------------------

getColor () {
    [[ -z $Monochrome ]] && case $1 in
        Black)      echo "\033[0;30m";;
        BoldBlack)  echo "\033[1;30m";;
        Red)        echo "\033[0;31m";;
        Green)      echo "\033[0;32m";;
        Blue)       echo "\033[0;34m";;
        BoldBlue)   echo "\033[1;34m";;
        Purple)     echo "\033[0;35m";;
        BoldCyan)   echo "\033[1;36m";;
        None)       echo "\033[0m";;
    esac
}

#*------------------------------------------------------------
#* Color Text
#*    1: Text
#*------------------------------------------------------------

colorText () {
    echo -e -n "$*$(getColor None)"
}

#*------------------------------------------------------------
#* Normal Text
#*    1: Text
#*------------------------------------------------------------

normal () {
    colorText "$(getColor Black)$*"
}

#*------------------------------------------------------------
#* Bold Text
#*    1: Text
#*------------------------------------------------------------

bold () {
    colorText "$(getColor BoldBlack)$*"
}

#*------------------------------------------------------------
#* Always log this message
#*    1: Message
#*------------------------------------------------------------

log () {
    echo -e "[$(date +"%Y-%m-%d %H:%M %Z")] $*$(getColor None)" 1>&2
}

#*------------------------------------------------------------
#* Always log Command To this message
#*    1: Message
#*------------------------------------------------------------

logCommand () {
    echo -e "$(bold [$(date +"%Y-%m-%d %H:%M %Z")] Command to) $(getColor blue)$*$(getColor None):-"
}

#*------------------------------------------------------------
#* Always log Content To this message
#*    1: Message
#*------------------------------------------------------------

logContent () {
    echo -e "$(bold [$(date +"%Y-%m-%d %H:%M %Z")] Content of) $(getColor blue)$*$(getColor None):-"
}
#*------------------------------------------------------------
#* Log this Information Message if not Terse
#*    1: Message
#*    2: Force Verbose
#*------------------------------------------------------------

info () {
    [[ $_LoggingMode == --terse && -z $2 ]] || log "$(getColor Blue)INFO: $1"
}

#*------------------------------------------------------------
#* Log this Debug Message if Verbose
#*    1: Message
#*    2: Force Verbose
#*------------------------------------------------------------

debug () {
    [[ $_LoggingMode == --verbose || ! -z $2 ]] && log "$(getColor Purple)DEBUG: $1"
}

#*------------------------------------------------------------
#* Log this Warning Message if not Terse
#*    1: Message
#*    2: Force Verbose
#*------------------------------------------------------------

warning () {
    [[ $_LoggingMode == --terse && -z $2 ]] || log "$(getColor Purple)WARNING: $1"
}

#*------------------------------------------------------------
#* Log this Pass Message if not Terse
#*    1: Message
#*    2: Force Verbose
#*------------------------------------------------------------

pass () {
    [[ $_LoggingMode == --terse && -z $2 ]] || log "$(getColor Green)PASS: $1"
}

#*------------------------------------------------------------
#* Always log this Fail Message
#*    1: Message
#*------------------------------------------------------------

fail () {
    log "$(getColor Red)FAIL: $*"
}

#*------------------------------------------------------------
#* Always log this Abort Message
#*    1: Message
#*------------------------------------------------------------

abort () {
    log "$(getColor Red)Aborting: $*\n"
    exit 1
}

#*------------------------------------------------------------
#* Abort on Fail
#*    1: Outcome to achieve
#*    2: Command to execute
#*    3: Silently
#*------------------------------------------------------------

abortOnFail () {
    local Outcome2Achieve=$1
    local Command2Execute=$2
    local Silently=$3
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$Command2Execute
$(echo -e $(getColor None))
EOF
    [[ -z $Silently ]] && info "  $Outcome2Achieve" force
    eval "$Command2Execute" >> $LogFile 2>&1 && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
}

#*------------------------------------------------------------
#* Option Name Text
#*    1: Text
#*------------------------------------------------------------

option () {
    colorText "$(getColor Blue)$*"
}

#*------------------------------------------------------------
#* Option Value Text
#*    1: Text
#*------------------------------------------------------------

value () {
    colorText "$(getColor Purple)$*"
}

#*------------------------------------------------------------
#* Options List
#*    1: List
#*------------------------------------------------------------

options () {
    colorText "$(getColor Purple)$*"
}

#*------------------------------------------------------------
#* Default Text
#*    1: Text
#*------------------------------------------------------------

default () {
    colorText "$(getColor Purple)$*"
}

#*------------------------------------------------------------
#* Red Text
#*    1: Text
#*------------------------------------------------------------

red () {
    colorText "$(getColor Red)$*"
}

#*------------------------------------------------------------
#* Bold Blue Text
#*    1: Text
#*------------------------------------------------------------

boldBlue () {
    colorText "$(getColor BoldBlue)$*"
}

#*------------------------------------------------------------
#* Dashes
#*    1: Count
#*------------------------------------------------------------

dashes () {
    printf '\055%.0s' $(seq $1)
}

#*------------------------------------------------------------
#* Get Options
#*    1: Type of Option
#*------------------------------------------------------------

getOptions () {
    case $1 in
        deploy) echo ${DeployOptions[@]};;
    esac
}

#*------------------------------------------------------------
#* List Options
#*    1: Type of Option
#*------------------------------------------------------------

listOptions () {
    unset Options
    for Option in $(getOptions $1); do
        [[ -z $Options ]] || Options+=", "
        Options+=$Option
    done
    echo $Options
}

#*------------------------------------------------------------
#* Get Default Option
#*    1: Type of Option
#*------------------------------------------------------------

getDefaultOption () {
    getOptions $1 | head -1 | awk '{print $1}'
}

#*------------------------------------------------------------
#* Show help
#*------------------------------------------------------------

showHelp () {
    cat << EOF 1>&2

Usage:
  $(bold $(basename $0)) $(option --configure) [$(option --CX) <$(value home)>] [$(option --monochrome)] [$(option --verbose)]

  $(bold $(basename $0)) $(option --deploy) <$(value option)> [$(option --CX) <$(value home)>] [$(option --monochrome)] [$(option --verbose)]

  $(bold $(basename $0)) $(option --query) [$(option --CX) <$(value home)>] [$(option --monochrome)] [$(option --verbose)]

  $(bold $(basename $0)) $(option --purge) [$(option --CX) <$(value home)>] [$(option --monochrome)] [$(option --verbose)]

  $(bold $(basename $0)) $(option --help) [$(option --CX) <$(value home)>] [$(option --monochrome)] [$(option --verbose)]

EOF
    if [[ $_LoggingMode == --verbose ]]; then
        cat << EOF 1>&2
    where
      $(option --configure)    Configure Pre-requisites
                         - Configure Utilities (podman, jq, yq, oc)
                         - Configure special File Storage Class for Db2
                         - Configure Container PIDs Limit
                         - Configure Pull Secrets
                         - Configure OLM Utilities

      $(option --deploy)       Deploy Options:- $(options $(listOptions deploy))
                     - Hub
                         - Configure IBM Certificate Manager and Licensing
                         - Configure IBM CPD Scheduler
                         - Authorize Instance Topology
                         - Setup IBM Software Hub
                     - IKC
                         - Enable Knowledge Graph
                         - Configure unlimited privilege for Db2
                         - Configure unrestricted Db2-as-a-service
                         - Patch to create the missing databases
                     - MANTA

      $(option --query)        Query Cluster Detail

      $(option --purge)        Purge existing deployment

      $(option --CX)           CX Home ($(value default):- $(default $CX))
      $(option --monochrome)   Monochrome Logging
      $(option --verbose)      Verbose Execution

      $(option --help)         Print this usage help

Assumptions:
- Cluster has been created. Instructions are available in below reference document
- File Storage Class has been created
- Script will be used to deploy Cloud Pak for Data 5.1.x on any officially supported OCP version

Reference:
  Deploying IBM Cloud Pak for Data on Red Hat OpenShift Service on AWS (ROSA)
  https://aws.amazon.com/blogs/ibm-redhat/deploying-ibm-cloud-pak-for-data-on-red-hat-openshift-service-on-aws-rosa/

EOF
    fi
    exit $?
}

#*------------------------------------------------------------
#* Log Usage
#*    1: Message
#*------------------------------------------------------------

usage () {
    echo 1>&2
    fail "$1"
    echo 1>&2
    showHelp 1
}

#*------------------------------------------------------------
#* Check Parameter
#*    1: Name of Option
#*    2: Name of Value
#*    3: Value specified
#*------------------------------------------------------------

checkParameter () {
    [[ -z $3 || $(echo $3 | cut -c1,1) == - ]] && usage "--$1 <$2> not specified"
}

#*------------------------------------------------------------
#* Check Option
#*    1: Name of Option
#*    2: Name of Value
#*    3: Value specified
#*------------------------------------------------------------

checkOption () {
    checkParameter $1 $2 $3
    for Option in $(getOptions $1); do
        [[ $Option == $3 ]] && return 0
    done
    echo 1>&2
    echo "Invalid $2 ($3) specified for --$1" 1>&2
    echo "Valid $1 ${2}s: $(listOptions $1)" 1>&2
    echo 1>&2
    showHelp 2
}

#*------------------------------------------------------------
#* Parse Options
#*------------------------------------------------------------

parseOptions () {
    _Action=showHelp
    for opt in $*; do
        case $1 in
            -c | --configure)                                                         _Action=configure;   shift;;
            -d | --deploy)     checkOption deploy option $2; DeployOption=$2;         _Action=deploy$2;    shift 2;;
            -q | --query)                                                             _Action=queryDetail; shift;;
            -p | --purge)                                                             _Action=purgeDeploy; shift;;
            -T | --Test)                                                              _Action=testSnippet; shift;;

            -C | --CX)         checkParameter CX home $2;    CX=$2;                                        shift 2;;
            -m | --monochrome)                               Monochrome=--monochrome;                      shift;;
            -v | --verbose)                                  _LoggingMode=--verbose;                       shift;;

            -h | --help)                                                              _Action=showHelp;    shift;;
            -u | --usage)                                                             _Action=showHelp;    shift;;
            *) break;;
        esac
    done

    [[ $# -ne 0 ]] && usage "Invalid option $1"
    [[ $_Action == showHelp ]] && showHelp 0
}

#*------------------------------------------------------------
#* Parse OpenShift Cluster Configuration
#*    1: Silently
#*------------------------------------------------------------

parseConfiguration () {
    local Silently=$1
    [[ -z $Silently ]] && info "Checking OpenShift Cluster Configurations" force

    InstanceNS=$(jq --raw-output .namespace.instance $Config4ROSA)
    [[ $InstanceNS == null ]] && abort "Instance Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $InstanceNS ]] && abort "Instance Namespace is missing in ROSA Configuration, $Config4ROSA"
    OperatorNS=$(jq --raw-output .namespace.operator $Config4ROSA)
    [[ $OperatorNS == null ]] && abort "Operator Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $OperatorNS ]] && abort "Operator Namespace is missing in ROSA Configuration, $Config4ROSA"
    SchedulerNS=$(jq --raw-output .namespace.scheduler $Config4ROSA)
    [[ $SchedulerNS == null ]] && abort "IBM CPD Scheduler Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $SchedulerNS ]] && abort "IBM CPD Scheduler Namespace is missing in ROSA Configuration, $Config4ROSA"
    CertManagerNS=$(jq --raw-output .namespace.certManager $Config4ROSA)
    [[ $CertManagerNS == null ]] && abort "IBM Certificate Manager Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $CertManagerNS ]] && abort "IBM Certificate Manager Namespace is missing in ROSA Configuration, $Config4ROSA"
    LicensingNS=$(jq --raw-output .namespace.licensing $Config4ROSA)
    [[ $LicensingNS == null ]] && abort "IBM Licensing Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $LicensingNS ]] && abort "IBM Licensing Namespace is missing in ROSA Configuration, $Config4ROSA"

    FileStorageClass=$(jq --raw-output .storageClass.file $Config4ROSA)
    [[ $FileStorageClass == null ]] && abort "File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $FileStorageClass ]] && abort "File Storage Class name is missing in ROSA Configuration, $Config4ROSA"
    BlockStorageClass=$(jq --raw-output .storageClass.block $Config4ROSA)
    [[ $BlockStorageClass == null ]] && abort "Block Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $BlockStorageClass ]] && abort "Block Storage Class name is missing in ROSA Configuration, $Config4ROSA"
    Db2FileStorageClass=$(jq --raw-output .storageClass.db2 $Config4ROSA)
    [[ $Db2FileStorageClass == null ]] && abort "Db2-specific File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Db2FileStorageClass ]] && abort "Db2-specific File Storage Class name is missing in ROSA Configuration, $Config4ROSA"

    [[ -z $Silently ]] && echo
}

#*------------------------------------------------------------
#* Configure utilities
#*    1: Log File
#*------------------------------------------------------------

configureUtilities () {
    local LogFile=$1
    log "Configure Utilities"

    local Utility="Podman Utility"
    [[ -z $(which podman 2>/dev/null) ]] && abortOnFail "Configure $Utility" "yum install -y podman --allowerasing"
    pass "  $Utility $(podman version | awk '{if($1=="Version:") print $2}')"

    Utility="JSON Processor (jq) Utility"
    [[ -z $(which jq 2>/dev/null) ]] && abortOnFail "Configure $Utility" "yum install -y jq"
    pass "  $Utility $(jq --version | awk -F'-' '{print $2}')"

    Utility="YAML Processor (yq) Utility"
    if [[ -z $(which yq 2>/dev/null) ]]; then
        local YQ=https://github.com/mikefarah/yq/releases/latest/download/yq_linux
        case $(uname -m) in
            x86_64)  YQ+="_amd64";;
            ppc64le) YQ+="_ppc64le";;
        esac
        abortOnFail "Download latest $Utility" "wget -qO /usr/local/bin/yq $YQ"
        abortOnFail "Add execute permission to $Utility" "chmod u+x /usr/local/bin/yq" Silently
    fi
    pass "  $Utility $(yq --version | awk '{print $NF}')"

    local OpenShiftClient=$(jq --raw-output .openshift.clientVersion $Config4ROSA)
    [[ $OpenShiftClient == null ]] && abort "OpenShift Client Version definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $OpenShiftClient ]] && abort "OpenShift Client Version is missing in ROSA Configuration, $Config4ROSA"

    Utility="OpenShift Client Utility"
    if [[ -z $(which oc 2>/dev/null) ]]; then
        local Tarball=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$OpenShiftClient/openshift-client-linux
        [[ $(uname -m) == ppc64le ]] && Tarball+="-ppc64le"
        Tarball+=".tar.gz"
        abortOnFail "Configure $Utility $OpenShiftClient" "wget -c $Tarball -O - 2>/dev/null | sudo tar -xz -C /usr/local/bin"
    fi
    pass "  $Utility $(oc version 2>/dev/null | awk '/Client Version/{print $NF}')"
}

#*------------------------------------------------------------
#* Generate DaemonSet to push updated Pull Secrets to worker nodes
#*------------------------------------------------------------

generateDaemonSet2PushPullSecrets () {
    cat << EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: $SecretName
  namespace: kube-system
  labels:
    tier: management
    app: $SecretName
spec:
  selector:
    matchLabels:
      name: $SecretName
  template:
    metadata:
      labels:
        name: $SecretName
    spec:
      hostNetwork: true
      hostPID: true
      hostIPC: true
      containers:
        - name: sleepforever
          resources:
            requests:
              cpu: 0.01
          image: registry.access.redhat.com/ubi8:latest
          command: ["/bin/sh", "-c"]
          args:
            - >
              date >> /ext-tmp/$SecretName.log ;
              echo "Following new Pull Secrets configuration will be applied to $PullSecretsConfigJSON" ;
              cat /pull-secret/newdockerconfigjson ;
              cat /pull-secret/newdockerconfigjson > /ext-config/$(basename $PullSecretsConfigJSON) ;
              while true; do
                sleep 100000;
              done
          volumeMounts:
            - name: pull-secret
              mountPath: /pull-secret
              readOnly: true
            - name: modifytmp
              mountPath: /ext-tmp
            - name: modifyconfig
              mountPath: /ext-config
      volumes:
        - name: pull-secret
          secret:
            secretName: $SecretName
        - name: modifytmp
          hostPath:
            path: /tmp
        - name: modifyconfig
          hostPath:
            path: $(dirname $PullSecretsConfigJSON)
EOF
}

#*------------------------------------------------------------
#* Wait for DaemonSet
#*    1: DaemonSet Name
#*    2: Outcome to Achieve
#*    3: Expected Pod Count
#*------------------------------------------------------------

wait4DaemonSet () {
    local DaemonSetName=$1
    local Outcome2Achieve=$2
    local ExpectedPodCount=$3
    local Counter=0
    while true; do
        (( Counter++ ))
        [[ $(oc get pod --selector name=$DaemonSetName --namespace kube-system --no-headers 2>> /dev/null |\
             awk '{if($2==Ready&&$3=Status) print $1}' Ready=1/1 Status=Running | wc -l) -eq $ExpectedPodCount ]] && break
        [[ $Counter -eq 120 ]] && abort "Failed to $Outcome2Achieve even after $(expr $Counter / 6) mins"
        [[ $(expr $Counter % 6) -eq 0 ]] && info "  Still waiting to $Outcome2Achieve after $(expr $Counter / 6) mins" force
        sleep 10
    done
}

#*------------------------------------------------------------
#* Wait for Rolling Upgrade
#*------------------------------------------------------------

wait4RollingUpgrade () {
    local Counter=0
    while [[ $(oc get MachineConfigPool worker --output json |\
               jq --raw-output --arg type Updated '.status.conditions[] | select(.type == $type) | .status') == True && \
             $(oc get MachineConfigPool master --output json |\
               jq --raw-output --arg type Updated '.status.conditions[] | select(.type == $type) | .status') == True ]]; do
        (( Counter++ ))
        [[ $(expr $Counter % 6) -eq 0 ]] && info "  Still waiting for Rolling Upgrade to begin after $(expr $Counter / 6) mins ..." force
        sleep 10
    done
    Counter=0
    info "  Rolling Upgrade started" force
    while [[ $(oc get MachineConfigPool worker --output json |\
               jq --raw-output --arg type Updated '.status.conditions[] | select(.type == $type) | .status') == False || \
             $(oc get MachineConfigPool master --output json |\
               jq --raw-output --arg type Updated '.status.conditions[] | select(.type == $type) | .status') == False ]]; do
        (( Counter++ ))
        if [[ $(expr $Counter % 12) -eq 0 ]]; then
            info "  Still waiting for Rolling Upgrade to complete after $(expr $Counter / 6) mins ..." force
            oc get MachineConfigPool | awk '{print $1" "$3" "$4" "$5" "$6" "$7" "$8" "$9}' |\
            sed -e "s/NAME/Name/;s/UPDATED/Updated/g;s/UPDATING/Updating/g;s/DEGRADED/Degraded/g;s/MACHINECOUNT/MachineCount/g" | column -t
        fi
        sleep 10
    done
    pass "  Rolling Upgrade Completed" force
}

#*------------------------------------------------------------
#* Configure Pull Secrets
#*    1: Log File
#*------------------------------------------------------------

configurePullSecrets () {
    local LogFile=$1

    info "Checking Credentials to access Public IBM Container Registry (ICR)" force
    local URL4ICR=$(jq --raw-output .access.registry.URL $Config4ROSA)
    [[ $URL4ICR == null ]] && abort "URL for IBM Container Registry definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $URL4ICR ]] && abort "URL for IBM Container Registry is missing in ROSA Configuration, $Config4ROSA"
    local Email4ICR=$(jq --raw-output .access.registry.email $Config4ROSA)
    [[ $Email4ICR == null ]] && abort "Email Address for IBM Container Registry definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Email4ICR ]] && abort "Email Address for IBM Container Registry is missing in ROSA Configuration, $Config4ROSA"
    local User4ICR=$(jq --raw-output .access.registry.user $Config4ROSA)
    [[ $User4ICR == null ]] && abort "User for IBM Container Registry definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $User4ICR ]] && abort "User for IBM Container Registry is missing in ROSA Configuration, $Config4ROSA"
    local Key4ICR=$(jq --raw-output .access.registry.key $Config4ROSA)
    [[ $Key4ICR == null ]] && abort "Key for IBM Container Registry definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Key4ICR ]] && abort "Key for IBM Container Registry is missing in ROSA Configuration, $Config4ROSA"
    local TargetPullSecret=$(echo -n "$User4ICR:$Key4ICR" | base64 -w0)

    info "Checking Pull Secrets from worker node, $AnyWorkerNode" force
    local PullSecretsConfigJSON=/var/lib/kubelet/config.json
    local RemotePullSecretsJSON=$CX/data/rosa.config.json
    local UpdatedPullSecretsJSON=$CX/data/updated.rosa.config.json
    [[ -f $UpdatedPullSecretsJSON ]] && rm -f $UpdatedPullSecretsJSON 2>/dev/null
    local Outcome2Achieve="Get Pull Secrets Config JSON, $PullSecretsConfigJSON, from $AnyWorkerNode"
    cat << EOS >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
cat << EOF | oc debug node/$AnyWorkerNode > $(replaceCX $RemotePullSecretsJSON)
chroot /host
cat $PullSecretsConfigJSON
EOF
$(echo -e $(getColor None))
EOS
    cat << EOF | oc debug node/$AnyWorkerNode > $RemotePullSecretsJSON 2>>$LogFile || abort "Failed to $Outcome2Achieve"
chroot /host 2>/dev/null
cat $PullSecretsConfigJSON
EOF
    local RemotePullSecret=$(jq --raw-output --arg RepoPath $URL4ICR '.auths | .[$RepoPath] | .auth' $RemotePullSecretsJSON)
    if [[ $RemotePullSecret == null ]]; then
        info "  Append Pull Secret for $URL4ICR" force
        jq --arg URL $URL4ICR \
           --arg PullSecret "$TargetPullSecret" \
           --arg Email $Email4ICR \
           '.auths += {($URL): {"auth": $PullSecret,
                                "email": $Email}}' $RemotePullSecretsJSON > $UpdatedPullSecretsJSON
    elif [[ $RemotePullSecret != $TargetPullSecret ]]; then
        info "  Update Pull Secret for $URL4ICR" force
        jq --arg URL $URL4ICR \
           --arg PullSecret "$TargetPullSecret" \
           '.auths += {($URL): {"auth": $PullSecret}}' $RemotePullSecretsJSON > $UpdatedPullSecretsJSON
    fi
    if [[ ! -f $UpdatedPullSecretsJSON ]]; then
        pass "Pull Secrets are up-to-date" force
        return
    fi

    if [[ $(oc version | awk '/Server Version/{print $3}') =~ 4.1[2-4]. ]]; then
        Need2RestartCrio=true
        local SecretName=rosa-pull-secrets
        [[ -z $(oc get secret $SecretName --namespace kube-system --ignore-not-found 2> /dev/null) ]] || \
            abortOnFail "Delete Secret, $SecretName" "oc delete secret $SecretName --namespace kube-system"
        abortOnFail "Create Generic Secret, $SecretName, from $(replaceCX $UpdatedPullSecretsJSON)" \
                    "oc create secret generic $SecretName --namespace kube-system --from-file=newdockerconfigjson=$UpdatedPullSecretsJSON"

        if [[ ! -z $(oc get DaemonSet $SecretName --namespace kube-system --ignore-not-found 2> /dev/null) ]]; then
            abortOnFail "Delete DaemonSet, $SecretName, that push updated Pull Secrets to all worker nodes" \
                        "oc delete DaemonSet $SecretName --namespace kube-system"
            wait4DaemonSet $SecretName "Delete DaemonSet, $SecretName, to push updated Pull Secrets to all worker nodes" 0
        fi

        Outcome2Achieve="Create DaemonSet, $SecretName, to push updated Pull Secrets to all worker nodes"
        cat << EOS >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
cat << EOF | oc apply -f -
$(generateDaemonSet2PushPullSecrets | yq --colors)$(echo -e $(getColor Purple))
EOF
$(echo -e $(getColor None))
EOS
        info "  $Outcome2Achieve" force
        generateDaemonSet2PushPullSecrets | oc apply -f - >> $LogFile 2>&1 && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
        wait4DaemonSet $SecretName "Apply DaemonSet, $SecretName, to push updated Pull Secrets to all worker nodes" $WorkerNodes
    else
        Outcome2Achieve="Configure Pull Secrets"
        cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
oc set data secret/pull-secret --namespace openshift-config \\
                               --from-file=.dockerconfigjson=\$CX/data/$(basename $UpdatedPullSecretsJSON)
$(echo -e $(getColor None))
EOF
        info "  $Outcome2Achieve" force
        oc set data secret/pull-secret --namespace openshift-config \
                                       --from-file=.dockerconfigjson=$UpdatedPullSecretsJSON >> $LogFile 2>&1 \
            && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
        wait4RollingUpgrade
    fi
    sleep 60
}

#*------------------------------------------------------------
#* Generate PIDs Limit YAML
#*------------------------------------------------------------

generatePIDsLimitYAML () {
    cat << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: ContainerRuntimeConfig
metadata:
  name: new-large-pidlimit
spec:
  containerRuntimeConfig:
    pidsLimit: $MinimumPIDsLimit
  machineConfigPoolSelector:
    matchExpressions:
    - key: pools.operator.machineconfiguration.openshift.io/worker
      operator: Exists
EOF
}

#*------------------------------------------------------------
#* Configure PIDs Limit
#*    1: Log File
#*------------------------------------------------------------

configurePIDsLimit () {
    local LogFile=$1
    local MinimumPIDsLimit=$(jq --raw-output .minimumPIDsLimit $Config4ROSA)
    [[ $MinimumPIDsLimit == null ]] && abort "Minimum PIDs Limit definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $MinimumPIDsLimit ]] && abort "Minimum PIDs Limit is missing in ROSA Configuration, $Config4ROSA"

    info "Checking PIDs Limit from worker node, $AnyWorkerNode" force
    cat << EOS >> $LogFile

$(logCommand Get current PIDs Limit)$(echo -e $(getColor Purple))
    cat << EOF | oc debug node/$AnyWorkerNode 2>/dev/null | awk '/pids_limit/{print $NF}'
chroot /host 2>/dev/null
cat /etc/crio/crio.conf.d/*
EOF
$(echo -e $(getColor None))
EOS
    local CurrentPIDsLimit=$(cat << EOF | oc debug node/$AnyWorkerNode 2>/dev/null | awk '/pids_limit/{print $NF}'
chroot /host 2>/dev/null
cat /etc/crio/crio.conf.d/*
EOF
)
    if [[ $CurrentPIDsLimit -lt $MinimumPIDsLimit ]]; then
        Need2RestartCrio=true
        local Outcome2Achieve="Configure PIDs Limit to $MinimumPIDsLimit from $CurrentPIDsLimit on all worker nodes"
        cat << EOS >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
cat << EOF | oc apply -f -
$(generatePIDsLimitYAML | yq --colors)$(echo -e $(getColor Purple))
EOF
$(echo -e $(getColor None))
EOS
        info "  $Outcome2Achieve" force
        generatePIDsLimitYAML | oc apply -f - >> $LogFile 2>&1 || abort "Failed to $Outcome2Achieve"
        local attempt=1
        while true; do
            cat << EOF | oc debug node/$AnyWorkerNode 2>/dev/null | grep "pids_limit = $MinimumPIDsLimit" >> /dev/null && break
chroot /host 2>/dev/null
cat /etc/crio/crio.conf.d/*
EOF
            [[ $attempt -eq 90 ]] && abort "Failed to $Outcome2Achieve even after $(expr $attempt / 6) mins"
            [[ $(expr $attempt % 6) -eq 0 ]] && info "  $Outcome2Achieve still not completed after $(expr $attempt / 6) mins" force
            sleep 10
            (( attempt++ ))
        done
        pass "  $Outcome2Achieve" force
    else
        pass "  PIDs Limit of $CurrentPIDsLimit from $AnyWorkerNode node satisfies minimum PIDs limit ($MinimumPIDsLimit) needed on the worker nodes" force
    fi
}

#*------------------------------------------------------------
#* Restart CRI-O Service
#*    1: Log File
#*------------------------------------------------------------

restartCrioService () {
    local LogFile=$1
    local Outcome2Achieve="Restart CRI-O Service on ROSA Worker Node"
    info "  ${Outcome2Achieve}s" force
    for WorkerNode in $(oc get nodes --selector node-role.kubernetes.io/worker --output custom-columns='name:.metadata.name' --no-headers); do
        [[ -z $(oc get node $WorkerNode --show-labels | grep node-role.kubernetes.io=infra) ]] || continue
        cat << EOS >> $LogFile

$(logCommand $Outcome2Achieve, $WorkerNode)$(echo -e $(getColor Purple))
cat << EOF | oc debug node/$WorkerNode
chroot /host
systemctl restart crio
EOF
$(echo -e $(getColor None))
EOS
        cat << EOF | oc debug node/$WorkerNode >> $LogFile 2>&1 && pass "    $Outcome2Achieve, $WorkerNode" force || fail "    $Outcome2Achieve, $WorkerNode"
chroot /host 2>/dev/null
systemctl restart crio
EOF
    done
    sleep 60
}

#*------------------------------------------------------------
#* Generate Db2-specific File Storage Class
#*    1: Db2-specific File Storage Class
#*    2: File System ID
#*------------------------------------------------------------

generateDb2FileStorageClass () {
    local Db2FileStorageClass=$1
    local FileSystemID=$2
    cat << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $Db2FileStorageClass
parameters:
  directoryPerms: "777"
  fileSystemId: $FileSystemID
  uid: "0"
  gid: "0"
  provisioningMode: efs-ap
provisioner: efs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
}

#*------------------------------------------------------------
#* Configure Storage Classes
#*    1: Log File
#*------------------------------------------------------------

configureStorageClasses () {
    local LogFile=$1
    log "Configure Storage Classes"

    FileStorageClass=$(jq --raw-output .storageClass.file $Config4ROSA)
    [[ $FileStorageClass == null ]] && abort "File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $FileStorageClass ]] && abort "File Storage Class name is missing in ROSA Configuration, $Config4ROSA"
    oc get StorageClass $FileStorageClass >/dev/null 2>&1 \
        && pass "  File Storage Class, $FileStorageClass" force || abort "File Storage Class, $FileStorageClass, not found"

    BlockStorageClass=$(jq --raw-output .storageClass.block $Config4ROSA)
    [[ $BlockStorageClass == null ]] && abort "Block Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $BlockStorageClass ]] && abort "Block Storage Class name is missing in ROSA Configuration, $Config4ROSA"
    oc get StorageClass $BlockStorageClass >/dev/null 2>&1 \
        && pass "  Block Storage Class, $BlockStorageClass" force || abort "Block Storage Class, $BlockStorageClass, not found"

    Db2FileStorageClass=$(jq --raw-output .storageClass.db2 $Config4ROSA)
    [[ $Db2FileStorageClass == null ]] && abort "Db2-specific File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Db2FileStorageClass ]] && abort "Db2-specific File Storage Class name is missing in ROSA Configuration, $Config4ROSA"
    if [[ -z $(oc get StorageClass $Db2FileStorageClass 2>/dev/null) ]]; then
        local FileSystemID=$(oc get StorageClass $FileStorageClass --output jsonpath='{.parameters.fileSystemId}')
        [[ -z $FileSystemID ]] && abort "Failed to get File System ID from File Storage Class, $FileStorageClass"
        local Outcome2Achieve="Create Db2-specific File Storage Class, $Db2FileStorageClass"
        cat << EOS >> $LogFile
$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
cat << EOF | oc apply -f -
$(generateDb2FileStorageClass $Db2FileStorageClass $FileSystemID | yq --colors)$(echo -e $(getColor Purple))
EOF
$(echo -e $(getColor None))
EOS
        info "  $Outcome2Achieve" force
        generateDb2FileStorageClass $Db2FileStorageClass $FileSystemID | oc apply -f - >> $LogFile 2>&1 \
            && pass "  $Outcome2Achieve" || abort "Failed to $Outcome2Achieve"
    else
        pass "  Db2-specific File Storage Class, $Db2FileStorageClass" force
    fi
}

#*------------------------------------------------------------
#* Configure OLM Utilities
#*    1: Log File
#*------------------------------------------------------------

configureOLMutilities () {
    local LogFile=$1

    local ImageOLM=olm-utils-v3
    local ContainerOLM=olm-utils-play-v3
    export run_utils="podman exec $ContainerOLM"

    if [[ ! -z $(podman images | grep $ImageOLM) && ! -z $(podman ps | grep $ContainerOLM) ]]; then
        podman exec $ContainerOLM versioninfo >> /dev/null 2>&1
        [[ $? -eq 126 ]] || return
    fi

    for ExistingContainerOLM in $(podman ps | awk '/olm-utils-play/{print $NF}'); do
        abortOnFail "Terminate running OLM Utility, $ExistingContainerOLM" "podman rm --force $ExistingContainerOLM"
    done
    for ImageID in $(podman images | awk '/olm-utils/{print $3}'); do
        abortOnFail "Delete existing OLM Utility Image with ID, $ImageID" "podman rmi --force $ImageID"
    done

    export work_dir=$CX/work
    [[ -d $work_dir ]] && rm -rf $work_dir
    mkdir -p $work_dir
    chmod 777 $work_dir

    Release=$(jq --raw-output .release $Config4ROSA)
    [[ $Release == null ]] && abort "Cloud Pak for Data Release definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Release ]] && abort "Cloud Pak for Data Release is missing in ROSA Configuration, $Config4ROSA"

    abortOnFail "Initialize OLM Utilities" "podman run -d --name $ContainerOLM -v $work_dir:/tmp/work icr.io/cpopen/cpd/$ImageOLM:$Release"
    local Counter=0
    while true; do
        (( Counter++ ))
        $run_utils ls -d /tmp/work/.airgap >> /dev/null 2>&1 && break
        [[ $Counter -eq 60 ]] && abort "Failed waiting for OLM Utilities to initialize after $(expr $Counter / 6) mins"
        [[ $(expr $Counter % 12) -eq 0 ]] && info "  Still waiting for OLM Utilities to initialize after $(expr $Counter / 6) mins" force
        sleep 10
    done
    [[ -z $(grep "export CPD_CLI_MANAGE_WORKSPACE=$CX" ~/.bashrc 2>/dev/null) ]] && echo "export CPD_CLI_MANAGE_WORKSPACE=$CX" >> ~/.bashrc
    podman cp $ContainerOLM:/opt/ansible/ansible-play/config-vars/global.yml $CX/data/global.yml
    podman cp $ContainerOLM:/opt/ansible/ansible-play/config-vars/release-$Release.yml $CX/data/release-$Release.yml
}

#*------------------------------------------------------------
#* Configure Pre-requisites
#*------------------------------------------------------------

configurePreRequisites () {
    local LogFile=$CX/log/Configure.PreReqs.log
    log "Configure Pre-requisites"
    configureUtilities $LogFile
    prepareOLMutilities $LogFile
    configureStorageClasses $LogFile
    local Need2RestartCrio
    unset Need2RestartCrio
    configurePIDsLimit $LogFile
    configurePullSecrets $LogFile
    [[ -z $Need2RestartCrio ]] || restartCrioService $LogFile
}

#*------------------------------------------------------------
#* Login via OLM Utilities
#*    1: Log File
#*------------------------------------------------------------

loginViaOLMutilities () {
    local LogFile=$1
    info "Checking Credentials to access OpenShift Cluster" force
    URL4REST=$(jq --raw-output .access.openshiftAPI.restURL $Config4ROSA)
    [[ $URL4REST == null ]] && abort "URL for OpenShift REST API definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $URL4REST ]] && abort "URL for OpenShift REST API is missing in ROSA Configuration, $Config4ROSA"

    Token4REST=$(jq --raw-output .access.openshiftAPI.token $Config4ROSA)
    if [[ $Token4REST == null ]]; then
        unset Token4REST
        User4REST=$(jq --raw-output .access.openshiftAPI.adminUser $Config4ROSA)
        if [[ $User4REST == null ]]; then
            abort "Token for OpenShift REST API definition is missing in ROSA Configuration, $Config4ROSA"
        else
            [[ -z $User4REST ]] && abort "User for OpenShift REST API is missing in ROSA Configuration, $Config4ROSA"
            Password4REST=$(jq --raw-output .access.openshiftAPI.password $Config4ROSA)
            [[ $Password4REST == null ]] && abort "Password for OpenShift REST API definition is missing in ROSA Configuration, $Config4ROSA"
            [[ -z $Password4REST ]] && abort "Password for OpenShift REST API is missing in ROSA Configuration, $Config4ROSA"
        fi
    elif [[ -z $Token4REST ]]; then
        abort "Token for OpenShift REST API is missing in ROSA Configuration, $Config4ROSA"
    fi
    oc cluster-info >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        $run_utils oc cluster-info >/dev/null 2>&1 && return 0
    fi

    local Outcome2Achieve="Login to OpenShift Cluster"
    if [[ -z $Token4REST ]]; then
        cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils login-to-ocp \\
    --username $User4REST \\
    --password <Password for $User4REST> \\
    --server=$URL4REST
$(echo -e $(getColor None))
EOF
        info "  $Outcome2Achieve" force
        oc login \
            --username $User4REST \
            --password $Password4REST \
            --server=$URL4REST \
            --insecure-skip-tls-verify=true >> $LogFile 2>&1 && pass "  $Outcome2Achieve" || abort "Failed to $Outcome2Achieve"
        Outcome2Achieve+=" via OLM utilities"
        $run_utils login-to-ocp \
            --username $User4REST \
            --password $Password4REST \
            --server=$URL4REST >> $LogFile 2>&1 && pass "  $Outcome2Achieve" || abort "Failed to $Outcome2Achieve"
    else
        cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils login-to-ocp \\
    --token <Token> \\
    --server=$URL4REST
$(echo -e $(getColor None))
EOF
        info "  $Outcome2Achieve" force
        oc login \
            --token $Token4REST \
            --server=$URL4REST \
            --insecure-skip-tls-verify=true >> $LogFile 2>&1 && pass "  $Outcome2Achieve" || abort "Failed to $Outcome2Achieve"
        Outcome2Achieve+=" via OLM utilities"
        $run_utils login-to-ocp \
            --token $Token4REST \
            --server=$URL4REST >> $LogFile 2>&1 && pass "  $Outcome2Achieve" || abort "Failed to $Outcome2Achieve"
    fi
}

#*------------------------------------------------------------
#* Prepare OLM Utilities
#*    1: Log File
#*------------------------------------------------------------

prepareOLMutilities () {
    local LogFile=$1
    configureOLMutilities $LogFile
    loginViaOLMutilities $LogFile

    if [[ ! -z $(which jq 2>/dev/null) ]]; then
        Release=$(jq --raw-output .release $Config4ROSA)
        [[ $Release == null ]] && abort "Cloud Pak for Data Release definition is missing in ROSA Configuration, $Config4ROSA"
        [[ -z $Release ]] && abort "Cloud Pak for Data Release is missing in ROSA Configuration, $Config4ROSA"
    fi

    if [[ ! -z $(which oc 2>/dev/null) ]]; then
        for WorkerNode in $(oc get nodes --selector node-role.kubernetes.io/worker --output custom-columns='name:.metadata.name' --no-headers | sort -R); do
            [[ -z $(oc get node $WorkerNode --show-labels | grep node-role.kubernetes.io=infra) ]] || continue
            AnyWorkerNode=$WorkerNode
            break
        done

        WorkerNodes=$(oc get nodes --selector node-role.kubernetes.io/worker --no-headers | wc -l)
        (( WorkerNodes -= $(oc get nodes --selector node-role.kubernetes.io/worker,node-role.kubernetes.io/infra --no-headers 2>/dev/null | wc -l) ))
    fi
}

#*------------------------------------------------------------
#* Get Metadata ID
#*    1: Component ID
#*    2: Metadata ID
#*------------------------------------------------------------

getMetadataID () {
    local ComponentID=$1
    local MetadataID=$2
    yq .global_components_meta.$ComponentID.$MetadataID < $CX/data/global.yml
}

#*------------------------------------------------------------
#* Get Release Metadata ID
#*    1: Component ID
#*    2: Metadata ID
#*------------------------------------------------------------

getReleaseMetadataID () {
    local ComponentID=$1
    local MetadataID=$2
    yq .release_components_meta.$ComponentID.$MetadataID < $CX/data/release-$Release.yml
}


#*------------------------------------------------------------
#* Wait for Component
#*    1: Log File
#*    2: Component ID
#*------------------------------------------------------------

wait4Component () {
    local LogFile=$1
    local ComponentID=$2
    local ResourceKind=$(getMetadataID $ComponentID cr_kind)
    [[ $ResourceKind == null ]] && return
    local ResourceNames=$(getMetadataID $ComponentID cr_name)
    [[ $ResourceNames == null ]] && abort "Missing Resource Name for $ComponentID"
    local StatusField=$(getMetadataID $ComponentID status_field)
    [[ "|placeholderStatus|null|" =~ "|$StatusField|" ]] && return
    local StatusSuccess=$(getMetadataID $ComponentID status_success)
    [[ $StatusSuccess == null ]] && StatusSuccess=Completed
    local StatusFailed=$(getMetadataID $ComponentID status_failed)
    [[ $StatusFailed == null ]] && StatusFailed=Failed
    local MaxRetries=$(getMetadataID $ComponentID status_max_retries)
    [[ $MaxRetries == null ]] && MaxRetries=25
    MaxRetries=$(expr $MaxRetries \* 6)

    local ComponentName=$(getMetadataID $ComponentID description)
    [[ $ComponentName == null ]] && ComponentName=$(getMetadataID $ComponentID crd_description)
    [[ $ComponentName == null ]] && ComponentName=$(getMetadataID $ComponentID cr_comment)
    [[ $ComponentName == null ]] && ComponentName=$ResourceKind

    if [[ $ResourceKind != NotebookRuntime ]]; then
        local MaxCounter=60
        [[ $ComponentID == cpd_platform ]] && MaxCounter=180
        local Counter=1
        while true; do
            local ActualResourceName=$(oc get $ResourceKind --namespace $InstanceNS --no-headers 2> /dev/null | awk '{if($2!=Type) print $1}' Type=serviceInstance)
            [[ -z $ActualResourceName ]] || break
            [[ $Counter -eq $MaxCounter ]] && abort "Failed to get Actual Resource Name for $ResourceKind even after $(expr $MaxCounter / 6) mins"
            if [[ $(expr $Counter % 6) -eq 0 ]]; then
                [[ $MaxCounter -eq 60 || $Counter -gt 120 ]] && info "  Still waiting to get Actual Resource Name for $ResourceKind after $(expr $Counter / 6) mins ..." force
            fi
            (( Counter++ ))
            sleep 10
        done
        if [[ $(wc -w <<< $ActualResourceName) -gt 1 && $ResourceKind != rstudio ]]; then
            warning "Found multiple Custom Resource Names for $ResourceKind" force
            oc get $ResourceKind --sort-by=.metadata.creationTimestamp --namespace $InstanceNS
            ActualResourceName=$(oc get $ResourceKind --sort-by=.metadata.creationTimestamp --namespace $InstanceNS -o name | awk -F'/' '{print $2}' | tail -1)
        fi
        if [[ $ActualResourceName != $ResourceNames ]]; then
            [[ $ResourceKind == rstudio ]] || warning "Replacing OLM Utils Resource Name, $ResourceNames with $ActualResourceName from cluster" force
            ResourceNames=$ActualResourceName
        fi
    fi

    for ResourceName in $ResourceNames; do
        cat << EOF >> $LogFile

$(logCommand Checking $ComponentName)$(echo -e $(getColor Purple))
oc get $ResourceKind $ResourceName --namespace $InstanceNS --output jsonpath="{.status.$StatusField}"
$(echo -e $(getColor None))
EOF
        local FailedCount=0
        local Retry=1
        while true; do
            local ElapsedMins=$(expr $Retry / 6)
            local ResourceStatus=$(oc get $ResourceKind $ResourceName --namespace $InstanceNS --output jsonpath="{.status.$StatusField}" 2> /dev/null)
            if [[ $ResourceStatus == $StatusSuccess ]]; then
                [[ $ElapsedMins -eq 0 ]] && pass "  $ComponentName is ready" force || pass "  $ComponentName is ready after $ElapsedMins mins" force
                break
            elif [[ $ResourceStatus == $StatusFailed ]]; then
                [[ $FailedCount -gt 180 ]] && abort "Failed to deploy $ComponentName"
                if [[ $FailedCount -eq 0 ]]; then
                    debug "Ignoring Failed reported by $ResourceKind.$ResourceName.$StatusField. Normally would have aborted ..." force
                elif [[ $(expr $FailedCount % 6) -eq 0 ]]; then
                    debug "Ignoring Failed reported by $ResourceKind.$ResourceName.$StatusField after $(expr $FailedCount / 6) mins. Normally would have aborted ..." force
                else
                    debug "Ignoring Failed reported by $ResourceKind.$ResourceName.$StatusField. Normally would have aborted ..."
                fi
                ResourceStatus="In-Progress"
                (( FailedCount++ ))
            else
                FailedCount=0
            fi
            if [[ $Retry -eq 1 ]]; then
                info "  Waiting for $ComponentName to be ready" force
                debug "    oc get $ResourceKind $ResourceName --namespace $InstanceNS -o jsonpath='{.status.$StatusField}'" force
            fi
            [[ $Retry -gt $MaxRetries ]] && abort "Still waiting for $ComponentName to be running after $ElapsedMins mins"
            [[ $(expr $Retry % 30) -eq 0 ]] && info "  Still waiting for $ComponentName to be ready after $ElapsedMins mins" force
            (( Retry++ ))
            sleep 10
        done
    done
}

#*------------------------------------------------------------
#* Wait for all Related Components to be Ready
#*    1: Component ID
#*    2: Log File
#*------------------------------------------------------------

wait4AllRelatedComponents () {
    local ComponentID=$1
    local LogFile=$2
    local ParentComponentName=$(getMetadataID $ComponentID description)
    [[ $ParentComponentName == null ]] && ParentComponentName=$(getMetadataID $ComponentID crd_description)
    [[ $ParentComponentName == null ]] && ParentComponentName=$(getMetadataID $ComponentID cr_comment)
    [[ $ParentComponentName == null ]] && ParentComponentName=$ResourceKind
    info "Waiting for $ParentComponentName-related Custom Resources to be Ready" force
    sleep 120

    for DependentComponentID in $($run_utils list-prereqs --components=$ComponentID --release=$Release |\
                                  sed -e "s/.*: //" | tr -d "[,']"); do
        local ResourceKind=$(getMetadataID $ComponentID cr_kind)
        local ResourceName=$(getMetadataID $ComponentID cr_name)
        if [[ $ComponentID == wkc ]]; then
            if [[ $DependentComponentID == datastage_ent ]]; then
                [[ $(oc get $ResourceKind $ResourceName --namespace $InstanceNS -o jsonpath='{.spec.enableDataQuality}')       == true ]] || continue
            elif [[ "|opencontent_fdb|fdb_k8s|ibm_neo4j|" =~ "|$DependentComponentID|" ]]; then
                if [[ $(oc get $ResourceKind $ResourceName --namespace $InstanceNS -o jsonpath='{.spec.enableKnowledgeGraph}') == true ]]; then
                    ResourceKind=$(yq .global_components_meta.opencontent_fdb.cr_kind < $CX/data/global.yml)
                    if [[ -z $(oc get $ResourceKind --namespace $InstanceNS --output custom-columns='name:.metadata.name' --no-headers 2>/dev/null) ]]; then
                        [[ "|opencontent_fdb|fdb_k8s|" =~ "|$DependentComponentID|" ]] && continue
                    else
                        [[ $DependentComponentID == ibm_neo4j ]] && continue
                    fi
                else
                    continue
                fi
            fi
        fi
        if [[ $DependentComponentID == ws_runtimes ]]; then
            local ResourceKind=$(getMetadataID $DependentComponentID cr_kind)
            for ResourceName in $(oc get $ResourceKind --namespace $InstanceNS --output custom-columns='name:.metadata.name' --no-headers 2>/dev/null); do
                wait4Component $LogFile $DependentComponentID $ResourceKind $ResourceName
            done
        else
            wait4Component $LogFile $DependentComponentID
        fi
    done

    wait4Component $LogFile $ComponentID
}

#*------------------------------------------------------------
#* Deploy IBM Software Hub
#*------------------------------------------------------------

deploySoftwareHub () {
    local LogFile=$CX/log/Deploy.Software.Hub.log
    rm -f $LogFile
    prepareOLMutilities $LogFile

    info "Checking OpenShift Cluster Configurations" force
    local OperatorNS=$(jq --raw-output .namespace.operator $Config4ROSA)
    [[ $OperatorNS == null ]] && abort "Operator Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $OperatorNS ]] && abort "Operator Namespace is missing in ROSA Configuration, $Config4ROSA"
    local InstanceNS=$(jq --raw-output .namespace.instance $Config4ROSA)
    [[ $InstanceNS == null ]] && abort "Instance Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $InstanceNS ]] && abort "Instance Namespace is missing in ROSA Configuration, $Config4ROSA"
    local SchedulerNS=$(jq --raw-output .namespace.scheduler $Config4ROSA)
    [[ $SchedulerNS == null ]] && abort "IBM CPD Scheduler Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $SchedulerNS ]] && abort "IBM CPD Scheduler Namespace is missing in ROSA Configuration, $Config4ROSA"
    local CertManagerNS=$(jq --raw-output .namespace.certManager $Config4ROSA)
    [[ $CertManagerNS == null ]] && abort "IBM Certificate Manager Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $CertManagerNS ]] && abort "IBM Certificate Manager Namespace is missing in ROSA Configuration, $Config4ROSA"
    local LicensingNS=$(jq --raw-output .namespace.licensing $Config4ROSA)
    [[ $LicensingNS == null ]] && abort "IBM Licensing Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $LicensingNS ]] && abort "IBM Licensing Namespace is missing in ROSA Configuration, $Config4ROSA"

    local FileStorageClass=$(jq --raw-output .storageClass.file $Config4ROSA)
    [[ $FileStorageClass == null ]] && abort "File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $FileStorageClass ]] && abort "File Storage Class is missing in ROSA Configuration, $Config4ROSA"
    local BlockStorageClass=$(jq --raw-output .storageClass.block $Config4ROSA)
    [[ $BlockStorageClass == null ]] && abort "Block Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $BlockStorageClass ]] && abort "Block Storage Class is missing in ROSA Configuration, $Config4ROSA"

    local Outcome2Achieve="Configure IBM Certificate Manager and Licensing"
    local AnsibleLogFile=$CX/log/OLM.Configure.CertManager.Licensing.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils apply-cluster-components \\
    --release=$Release \\
    --enable_licensing=true \\
    --cert_manager_ns=$CertManagerNS \\
    --licensing_ns=$LicensingNS \\
    --license_acceptance=true > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $run_utils apply-cluster-components \
        --release=$Release \
        --enable_licensing=true \
        --cert_manager_ns=$CertManagerNS \
        --licensing_ns=$LicensingNS \
        --license_acceptance=true > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
    cat << EOF >> $LogFile 2>&1
$(oc get pods --namespace $CertManagerNS)

$(oc get pods --namespace $LicensingNS | grep "NAME\|licensing")
EOF

# Failed to deploy IBM CPD Scheduler on Classic ROSA cluster OCP 4.18.16
if [[ skip == step ]]; then
    Outcome2Achieve="Configure IBM CPD Scheduler, $SchedulerNS"
    AnsibleLogFile=$CX/log/OLM.Configure.CPD.Scheduler.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils apply-scheduler \\
    --release=$Release \\
    --scheduler_ns=$SchedulerNS \\
    --license_acceptance=true > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $run_utils apply-scheduler \
        --release=$Release \
        --scheduler_ns=$SchedulerNS \
        --license_acceptance=true > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
fi

    Outcome2Achieve="Authorize Instance Topology, $InstanceNS"
    AnsibleLogFile=$CX/log/OLM.Authorize.Instance.Topology.$InstanceNS.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils authorize-instance-topology \\
    --cpd_operator_ns=$OperatorNS \\
    --cpd_instance_ns=$InstanceNS > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $run_utils authorize-instance-topology \
        --cpd_operator_ns=$OperatorNS \
        --cpd_instance_ns=$InstanceNS > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"

    Outcome2Achieve="Setup IBM Software Hub, $InstanceNS"
    AnsibleLogFile=$CX/log/OLM.Setup.Software.Hub.$InstanceNS.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils setup-instance \\
    --release=$Release \\
    --file_storage_class=$FileStorageClass \\
    --block_storage_class=$BlockStorageClass \\
    --cpd_operator_ns=$OperatorNS \\
    --cpd_instance_ns=$InstanceNS \\
    --license_acceptance=true > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $run_utils setup-instance \
        --release=$Release \
        --file_storage_class=$FileStorageClass \
        --block_storage_class=$BlockStorageClass \
        --cpd_operator_ns=$OperatorNS \
        --cpd_instance_ns=$InstanceNS \
        --license_acceptance=true > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"

    wait4Component $LogFile cpd_platform
}

#*------------------------------------------------------------
#* Generate Db2U Product Config Map to grant unlimited privilege 
#*------------------------------------------------------------

generateDb2uProductConfigMap () {
    cat << EOF
apiVersion: v1
data:
  DB2U_RUN_WITH_LIMITED_PRIVS: "false"
kind: ConfigMap
metadata:
  name: db2u-product-cm
  namespace: $OperatorNS
EOF
}

#*------------------------------------------------------------
#* Configure Unlimited Privilege for Db2U
#*    1: Log File
#*------------------------------------------------------------

configureUnlimitedPrivilege4Db2U () {
    local LogFile=$1

    info "Checking OpenShift Cluster Instance Namespace definition" force
    local InstanceNS=$(jq --raw-output .namespace.instance $Config4ROSA)
    [[ $InstanceNS == null ]] && abort "Instance Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $InstanceNS ]] && abort "Instance Namespace is missing in ROSA Configuration, $Config4ROSA"

    if [[ $(oc get ConfigMap db2u-product-cm --namespace $InstanceNS --output jsonpath='{.data}' 2>/dev/null |\
            jq --raw-output .DB2U_RUN_WITH_LIMITED_PRIVS) == false ]]; then
        pass "  Db2U is configured to run with unlimited privileges" force
    else
        local Outcome2Achieve="Configure Db2U to run with unlimited privileges"
        cat << EOS >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
    cat << EOF | oc apply -f -
$(generateDb2uProductConfigMap | yq --colors)
EOF
$(echo -e $(getColor None))
EOS
        info "  $Outcome2Achieve" force
        generateDb2uProductConfigMap | oc apply -f - >> $LogFile 2>&1 || abort "Failed to $Outcome2Achieve"
        pass "  $Outcome2Achieve" force
    fi
}

#*------------------------------------------------------------
#* Patch Db2-as-a-service
#*    1: Log File
#*------------------------------------------------------------

patchDb2 () {
    local LogFile=$1
    local Execute="oc exec --stdin=false --tty=false c-db2oltp-wkc-db2u-0 --namespace $InstanceNS -- su - db2inst1 -c"
    local Outcome2Achieve="for Db2U Cluster db2oltp-wkc to be ready"
    info "  Waiting $Outcome2Achieve" force
    local Counter=0
    unset ZenDatabaseCore Command2Execute
    while true; do
        (( Counter++ ))
        if [[ $(oc get db2uclusters db2oltp-wkc --namespace $InstanceNS --output custom-columns='name:.status.state' --no-headers 2>/dev/null) == Ready ]]; then
            if [[ -z $ZenDatabaseCore ]]; then
                ZenDatabaseCore=$(oc get pod --selector component=zen-database-core --namespace $InstanceNS \
                                             --output custom-columns='name:.metadata.name' --no-headers)
                Outcome2Achieve="for Zen Database Core to be ready"
            fi
            if [[ ! -z $ZenDatabaseCore && -z $Command2Execute ]]; then
                Command2Execute=$(oc logs $ZenDatabaseCore --namespace $InstanceNS |\
                                  grep "manage_databases --dblist" | tail -1 |\
                                  sed -e "s/.*command //;s/\".*//;s/--db-cfg-overrides /--db-cfg-overrides '/;s/$/'/")
                Outcome2Achieve="to extract command to create the remaining three databases"
            fi
            [[ -z $Command2Execute ]] || break
        fi
        [[ $Counter -eq 720 ]] && abort "Failed to wait $Outcome2Achieve even after $(expr $Counter / 6) mins"
        [[ $(expr $Counter % 60) -eq 0 ]] && info "  Still waiting $Outcome2Achieve after $(expr $Counter / 6) mins" force
        sleep 10
    done
    pass "  Extracted command to create the remaining three databases" force

    Outcome2Achieve="Current list of databases and aliases"
    cat << EOF >> $LogFile 2>&1
$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$($Execute "manage_databases --show" 2>/dev/null)
$(echo -e $(getColor None))
EOF

    Outcome2Achieve="Create the remaining three databases"
    local Db2LogFile=$CX/log/Db2.Create.Databases.$InstanceNS.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$Execute "$Command2Execute" > $Db2LogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $Execute "$Command2Execute" > $Db2LogFile 2>&1

    Outcome2Achieve="Current list of databases and aliases"
    Counter=0
    while true; do
        [[ $(expr $Counter % 6) -eq 0 ]] && cat << EOF >> $LogFile 2>&1
$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$($Execute "manage_databases --show" 2>/dev/null)
$(echo -e $(getColor None))
EOF
        (( Counter++ ))
        [[ $($Execute "manage_databases --show" 2>/dev/null | grep ^Database | wc -l) -ne 8 ]] && continue
        pass "  All 4 Db2 databases and aliases created" force
        break
    done

    for Database in WF ILGDB BG; do
        Outcome2Achieve="Configure Database $Database"
        local ScriptFile="/db2uadm/${Database}-PostInstall.db2"
        Db2LogFile=$CX/log/Db2.Configure.$Database.$InstanceNS.$$.log
        Counter=0
        while [[ -z $($Execute "ls $ScriptFile 2>/dev/null" 2>/dev/null) ]]; do
            (( Counter++ ))
            [[ $(expr $Counter % 6) -eq 0 ]] && info "  Still waiting for $ScriptFile after $(expr $Counter / 6) mins" force
            sleep 10
        done
        cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$Execute "db2 -f $ScriptFile" > $Db2LogFile
$(echo -e $(getColor None))
EOF
        info "  $Outcome2Achieve" force
        $Execute "db2 -f $ScriptFile" > $Db2LogFile 2>&1
        [[ $(grep ^DB $Db2LogFile | awk '{print $1}' | sort -u | grep -v DB20000I | wc -l) -eq 0 ]] && pass "  $Outcome2Achieve" force || fail "  $Outcome2Achieve"
    done
}

#*------------------------------------------------------------
#* Deploy Service
#*    1: Component ID
#*------------------------------------------------------------

deployService () {
    local ComponentID=$1
    local LogFile=$CX/log/Deploy.$DeployOption.log
    rm -f $LogFile
    prepareOLMutilities $LogFile

    info "Checking OpenShift Cluster Configurations" force
    local InstanceNS=$(jq --raw-output .namespace.instance $Config4ROSA)
    [[ $InstanceNS == null ]] && abort "Instance Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $InstanceNS ]] && abort "Instance Namespace is missing in ROSA Configuration, $Config4ROSA"
    local OperatorNS=$(jq --raw-output .namespace.operator $Config4ROSA)
    [[ $OperatorNS == null ]] && abort "Operator Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $OperatorNS ]] && abort "Operator Namespace is missing in ROSA Configuration, $Config4ROSA"

    local FileStorageClass=$(jq --raw-output .storageClass.file $Config4ROSA)
    [[ $FileStorageClass == null ]] && abort "File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $FileStorageClass ]] && abort "File Storage Class is missing in ROSA Configuration, $Config4ROSA"
    local BlockStorageClass=$(jq --raw-output .storageClass.block $Config4ROSA)
    [[ $BlockStorageClass == null ]] && abort "Block Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $BlockStorageClass ]] && abort "Block Storage Class is missing in ROSA Configuration, $Config4ROSA"
    local Db2FileStorageClass=$(jq --raw-output .storageClass.db2 $Config4ROSA)
    [[ $Db2FileStorageClass == null ]] && abort "Db2 File Storage Class definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $Db2FileStorageClass ]] && abort "Db2 File Storage Class is missing in ROSA Configuration, $Config4ROSA"

    [[ $DeployOption == IKC ]] && configureUnlimitedPrivilege4Db2U $LogFile

    local Outcome2Achieve="Create $DeployOption Catalog Source and Subscription in $OperatorNS namespace"
    AnsibleLogFile=$CX/log/OLM.Create.$DeployOption.Operator.$InstanceNS.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils apply-olm \\
    --components=$ComponentID \\
    --release=$Release \\
    --cpd_operator_ns=$OperatorNS > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $run_utils apply-olm \
        --components=$ComponentID \
        --release=$Release \
        --cpd_operator_ns=$OperatorNS > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"
 
    unset ParamFileOption
    local CustomSpecYAML="{}"
    if [[ $ComponentID == wkc ]]; then
        CustomSpecYAML=$(yq ".custom_spec.wkc.wkc_db2u_restricted_mode=false" <<< $CustomSpecYAML)
        CustomSpecYAML=$(yq ".custom_spec.wkc.enableKnowledgeGraph=true" <<< $CustomSpecYAML)
        CustomSpecYAML=$(yq ".custom_spec.wkc.useFDB=true" <<< $CustomSpecYAML)
        CustomSpecYAML=$(yq ".custom_spec.wkc.wkc_db2u_data_storage_class=\"$BlockStorageClass\"" <<< $CustomSpecYAML)
        CustomSpecYAML=$(yq ".custom_spec.wkc.wkc_db2u_meta_storage_class=\"$Db2FileStorageClass\"" <<< $CustomSpecYAML)
        CustomSpecYAML=$(yq ".custom_spec.wkc.wkc_db2u_backup_storage_class=\"$Db2FileStorageClass\"" <<< $CustomSpecYAML)
        yq <<< $CustomSpecYAML > $CX/work/CustomSpec.wkc.$$.yaml
        ParamFileOption+=" --param-file=/tmp/work/CustomSpec.wkc.$$.yaml"
    fi

    Outcome2Achieve="Create $DeployOption Custom Resource in $InstanceNS namespace"
    AnsibleLogFile=$CX/log/OLM.Create.$DeployOption.Operands.$InstanceNS.$$.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$run_utils apply-cr \\
    --components=$ComponentID \\
    --release=$Release \\
    --file_storage_class=$FileStorageClass \\
    --block_storage_class=$BlockStorageClass \\
    --cpd_instance_ns=$InstanceNS \\
    --cpd_operator_ns=$OperatorNS \\
EOF
    [[ CustomSpecYAML == "{}" ]] || cat << EOF >> $LogFile
    --param-file=/tmp/work/CustomSpec.wkc.$$.yaml \\
EOF
    cat << EOF >> $LogFile
    --license_acceptance=true > $AnsibleLogFile
$(echo -e $(getColor None))
EOF
    [[ -z $ParamFileOption ]] || cat << EOF >> $LogFile
$(logContent Custom Specification Parameters File, $CX/work/CustomSpec.wkc.$$.yaml)$(echo -e $(getColor Purple))
$(cat $CX/work/CustomSpec.wkc.$$.yaml | yq --colors)
$(jq --color-output . <<< $PatchJSON)$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    [[ $DeployOption == IKC ]] && patchDb2 $LogFile &
    $run_utils apply-cr \
        --components=$ComponentID \
        --release=$Release \
        --file_storage_class=$FileStorageClass \
        --block_storage_class=$BlockStorageClass \
        --cpd_instance_ns=$InstanceNS \
        --cpd_operator_ns=$OperatorNS \
        $ParamFileOption \
        --license_acceptance=true > $AnsibleLogFile 2>&1 \
        && pass "  $Outcome2Achieve" force || abort "Failed to $Outcome2Achieve"

    wait4AllRelatedComponents $ComponentID $LogFile
}

#*------------------------------------------------------------
#* Query CASE Version
#*    1: Component ID
#*------------------------------------------------------------

queryCaseVersion () {
    local ComponentID=$1

    unset CaseVersion
    ColorCase=normal

    local TargetCaseVersion=$(getReleaseMetadataID $ComponentID case_version)
    local CaseName=$(getMetadataID $ComponentID case_name)
    local CaseFolder=$CaseName
    [[ $ComponentID == postgresql ]] && CaseFolder=ibm-zen
    CaseVersion=$(ls "$CX/work/offline/$Release/.ibm-pak/data/cases/$CaseFolder/"*"/$CaseName"*.tgz 2>/dev/null |\
                  sed -n -e "s/^.*$CaseName-//;s/.tgz$//p" | tail -1)
    [[ -z $CaseVersion ]] && CaseVersion=$(ls "$CX/OLM/offline/$Release/.ibm-pak/data/cases/$CaseFolder/"*"/$CaseName"*.tgz 2>/dev/null |\
                                           sed -n -e "s/^.*$CaseName-//;s/.tgz$//p" | tail -1)
    [[ $CaseVersion =~ "+" ]] && CaseVersion=$(cut -d'+' -f1 <<< $CaseVersion)
    [[ $CaseVersion == $TargetCaseVersion ]] || ColorCase=red
}

#*------------------------------------------------------------
#* Query Operator Status
#*    1: Component ID
#*    2: Namespace
#*------------------------------------------------------------

queryOperatorStatus () {
    local ComponentID=$1
    local Namespace=$2

    unset ChannelCurrent VersionCSV OperatorStatus
    ColorChannel=normal
    ColorOperator=normal
    ColorCSV=normal

    local SubscriptionJSON=$(oc get Subscription --selector operators.coreos.com/$(getMetadataID $ComponentID pkg_name).$Namespace= \
                                                 --namespace $Namespace --output json 2> /dev/null)
    if [[ $ComponentID != postgresql ]]; then
        local SubscriptionName=$(getMetadataID $ComponentID sub_name)
        [[ $SubscriptionName == null ]] && SubscriptionName=$(getMetadataID $ComponentID operator_name)
        [[ $SubscriptionName == null ]] && SubscriptionName=$(getMetadataID $ComponentID pkg_name)
        SubscriptionJSON=$(oc get Subscription $SubscriptionName --namespace $Namespace --output json 2> /dev/null)
    fi
    local ChannelPlanned=$(getReleaseMetadataID $ComponentID sub_channel)
    ChannelCurrent=$(jq --raw-output .spec.channel <<< $SubscriptionJSON)
    [[ $ChannelPlanned == null || $ChannelCurrent == $ChannelPlanned ]] || ColorChannel=red
    local CurrentCSV=$(jq --raw-output .status.currentCSV <<< $SubscriptionJSON)
    local ClusterServiceVersionJSON=$(oc get ClusterServiceVersion $CurrentCSV --namespace $Namespace --output json 2>/dev/null)
    VersionCSV=$(jq --raw-output .spec.version <<< $ClusterServiceVersionJSON | cut -d '-' -f1)
    [[ $ComponentID == postgresql ]] && VersionCSV=$(cut -d '.' -f2- <<< $CurrentCSV | tr -d 'v')
    local PlannedCSV=$(getReleaseMetadataID $ComponentID csv_version)
    [[ $VersionCSV == $PlannedCSV ]] || ColorCSV=red
    OperatorStatus=$(jq --raw-output .status.phase <<< $ClusterServiceVersionJSON | cut -d '-' -f1)
    [[ $OperatorStatus == Succeeded ]] || ColorOperator=red
}

#*------------------------------------------------------------
#* Query Operand Status
#*    1: Component ID
#*    2: Namespace
#*------------------------------------------------------------

queryOperandStatus () {
    local ComponentID=$1
    local Namespace=$2

    unset ScaleConfig ResourceStatus SpecVersion ReconciledVersion
    ColorStatus=normal
    ColorOperand=normal
    ColorSpec=normal

    local ResourceKind=$(getMetadataID $ComponentID cr_kind)
    [[ $ResourceKind == null ]] && return 1
    local ResourceName=$(getMetadataID $ComponentID cr_name)
    [[ $ResourceName == null ]] && ResourceName=$(oc get $ResourceKind --namespace $Namespace --no-headers --output custom-columns=":metadata.name")
    [[ $ResourceName == null ]] && return 1
    local ResourceJSON=$(oc get $ResourceKind $ResourceName --namespace $Namespace --output json 2> /dev/null)

    local StatusField=$(getMetadataID $ComponentID status_field)
    [[ "|placeholderStatus|null|" =~ "|$StatusField|" ]] && return 1
    local StatusSuccess=$(getMetadataID $ComponentID status_success)
    [[ $StatusSuccess == null ]] && StatusSuccess=Completed
    ResourceStatus=$(jq --raw-output .status.$StatusField <<< $ResourceJSON)
    [[ $ResourceStatus == $StatusSuccess ]] || ColorStatus=red

    OperandVersion=$(getReleaseMetadataID $ComponentID cr_version) 
    SpecVersion=.spec.version
    [[ $ComponentID == opencontent_fdb ]] && SpecVersion=.spec.foundationdb_cluster_spec.version
    SpecVersion=$(jq --raw-output $SpecVersion <<< $ResourceJSON)
    [[ $SpecVersion == null ]] && unset SpecVersion
    VersionField=$(getMetadataID $ComponentID status_reconciled_version_field)
    case $ComponentID in
        datastage_ent)   VersionField=dsVersion;;
        dv)              VersionField=version;;
        mantaflow)       VersionField=version;;
        cpd_platform)    VersionField=version;;
    esac
    [[ $VersionField == null ]] && VersionField="versions.reconciled"
    ReconciledVersion=$(jq --raw-output .status.$VersionField <<< $ResourceJSON)
    [[ $ReconciledVersion == null ]] && unset ReconciledVersion
    [[ $ComponentID == db2aaservice ]] && ReconciledVersion=$(cut -d'+' -f1 <<< $ReconciledVersion)
    [[ $ComponentID == dmc ]] && ReconciledVersion=$OperandVersion
    if [[ $ComponentID != opencontent_fdb && $OperandVersion != null ]]; then
        [[ $ReconciledVersion == $OperandVersion ]] || ColorOperand=red
        [[ $SpecVersion       == $OperandVersion ]] || ColorSpec=red
    fi

    ScaleConfig=$(jq --raw-output .spec.scaleConfig <<< $ResourceJSON)
    if [[ $ScaleConfig == null ]]; then
        [[ $(jq --raw-output .spec.autoScaleConfig <<< $ResourceJSON) == true ]] && ScaleConfig=auto || unset ScaleConfig
    fi

    return 0
}

#*------------------------------------------------------------
#* Query Cluster Detail
#*------------------------------------------------------------

queryClusterDetail () {
    local LogFile=$CX/log/Query.Cluster.log
    rm -f $LogFile
    parseConfiguration Silently
    prepareOLMutilities $LogFile

    echo
    log "Query Cluster Detail\n"

    local ConsoleURL=$(oc get ConfigMap console-public --namespace openshift-config-managed --output jsonpath='{.data.consoleURL}' 2>/dev/null)
    local ProjectURL=$(oc get ZenService lite-cr --namespace $InstanceNS --ignore-not-found --output jsonpath='{.status.url}')
    [[ -z $ProjectURL ]] && ProjectURL=$(oc get route --no-headers --namespace $InstanceNS | awk '{if($1==Route) print $2}' Route=cpd)
    [[ -z $ProjectURL ]] || ProjectURL=https://$ProjectURL
    local AdminUsername AdminPassword
    local Retry=0
    while true; do
        if [[ -z $(oc get secret platform-auth-idp-credentials --namespace $InstanceNS --no-headers 2>/dev/null) ]]; then
            AdminUsername=admin
            AdminPassword=$(oc get secret admin-user-details --namespace $InstanceNS --output jsonpath='{.data.initial_admin_password}' 2>/dev/null | base64 --decode)
        else
            local AdminCredentialJSON=$(oc get secret platform-auth-idp-credentials --namespace $InstanceNS --output json 2>/dev/null | jq .data)
            AdminUsername=$(jq --raw-output .admin_username <<< $AdminCredentialJSON | base64 --decode)
            AdminPassword=$(jq --raw-output .admin_password <<< $AdminCredentialJSON | base64 --decode)
        fi
        [[ -z $AdminUsername || -z $AdminPassword ]] || break
        (( Retry++ ))
        [[ $Retry -eq 30 ]] && abort "Failed to get Admin credentials within 5 mins"
        sleep 10
    done

    local HostWidth=${#APIURL}
    [[ ! -z $ProjectURL && ${#ProjectURL} -gt $HostWidth ]] && HostWidth=${#ProjectURL}
    local UserWidth=${#UserName4OCP}
    [[ ! -z $ProjectURL && ${#AdminUsername} -gt $UserWidth ]] && UserWidth=${#AdminUsername}
    local PasswordWidth=${#WithPassword}
    [[ ! -z $ProjectURL && ${#AdminPassword} -gt $PasswordWidth ]] && PasswordWidth=${#AdminPassword}
    local Format="  %-33s  %-$(expr $HostWidth + 11)s  %-$(expr $UserWidth + 11)s  %-$(expr $PasswordWidth + 11)s\n"
    printf "$Format" "$(boldBlue Access Info)" $(boldBlue URL )             $(boldBlue User)             $(boldBlue Password)
    printf "$Format"  $(bold $(dashes 22))     $(bold $(dashes $HostWidth)) $(bold $(dashes $UserWidth)) $(bold $(dashes $PasswordWidth))
    [[ -z $ProjectURL ]] || printf "$Format" "$(bold Project Instance URL)" "$(normal $ProjectURL)" "$(normal $AdminUsername)" "$(normal $AdminPassword)"
    [[ -z $Token4REST ]] \
        && printf "$Format" "$(bold REST API URL)" "$(normal $URL4REST)" "$(normal $User4REST)" "$(normal $Password4REST)" \
        || printf "$Format" "$(bold REST API URL)" "$(normal $URL4REST)" "$(normal <Token>)"
    printf "$Format" "$(bold OpenShift Console URL)" "$(normal $ConsoleURL)"
    echo

    local ValueWidth=$(expr $HostWidth + $UserWidth + $PasswordWidth - 11)
    Format="  %-48s  %-101s\n"
    GitFormat="  %-37s  %-$(expr $ValueWidth + 11)s\n"
    printf "$Format" $(boldBlue Configuration) $(boldBlue Value)
    printf "$Format" $(bold $(dashes 37))      $(bold $(dashes $ValueWidth))

    local ConfigurationValue=$(oc version | awk '/Server Version/{print $3}')
    ConfigurationValue+=" (Client: $(oc version | awk '/Client Version/{print $3}'),"
    ConfigurationValue+=" Kubernetes: $(oc version | awk '/Kubernetes Version/{print $3}'))"
    printf "$Format" "$(bold OpenShift Container Platform)" "$(normal $ConfigurationValue)"

    ConfigurationValue="File: $FileStorageClass"
    ConfigurationValue+=", Block: $BlockStorageClass"
    ConfigurationValue+=", Db2 File: $Db2FileStorageClass"
    printf "$Format" "$(bold OpenShift Persistent Storage Classes)" "$(normal $ConfigurationValue)"

    ConfigurationValue=$WorkerNodes
    case $(uname -m) in
        x86_64)  ConfigurationValue+=" Intel";;
        ppc64le) ConfigurationValue+=" Power";;
    esac
    ConfigurationValue+=" worker nodes"
    [[ -z $(oc get ConfigMap cluster-config-v1 --namespace kube-system --output jsonpath='{.data}' | grep -i fips) ]] || ConfigurationValue+=", FIPS encryption enabled"
    printf "$Format" "$(bold OpenShift Cluster Configuration)" "$(normal $ConfigurationValue)"

    if [[ -z $ProjectURL ]]; then
        echo
        return
    fi

    ConfigurationValue="Private Topology"
    [[ $(oc get ZenService lite-cr --namespace $InstanceNS -o jsonpath='{.spec.iamIntegration}' 2>/dev/null) == true ]] && ConfigurationValue+=", IAM integration enabled"
    [[ $(oc get configmap product-configmap --namespace $Namespace -o jsonpath='{.data.VAULT_ENABLED_STATUS}' 2>/dev/null) == true ]] && ConfigurationValue+=", Vault enabled"
    printf "$Format" "$(bold Project Instance Configuration)" "$(normal $ConfigurationValue)"

    ConfigurationValue="Instance: $InstanceNS"
    ConfigurationValue+=", Operator: $OperatorNS"
    printf "$Format" "$(bold Project Instance-related Namespaces)" "$(normal $ConfigurationValue)"

    ConfigurationValue="Scheduler: $SchedulerNS"
    ConfigurationValue+=", Cert Manager: $CertManagerNS"
    ConfigurationValue+=", Licensing: $LicensingNS"
    printf "$Format" "$(bold Cluster-wide Namespaces)" "$(normal $ConfigurationValue)"

    printf "$Format" "$(bold Cloud Pak for Data)" $(normal $Release)

    echo
    Format="  %-29s  %-17s  %-24s  %18.18s  %21.21s  %-21s  %19.19s  %23.23s  %18.18s\n"
    printf "$Format" "$(boldBlue CP4D Service)" $(boldBlue Scale)  "$(boldBlue CR Status)" $(boldBlue Version) $(boldBlue Reconciled) \
                                               "$(boldBlue OLM Status)" $(boldBlue Operator) $(boldBlue Channel)  $(boldBlue CASE)
    printf "$Format"  $(bold $(dashes 18))      $(bold $(dashes 6)) $(bold $(dashes 13))   $(bold $(dashes 7)) $(bold $(dashes 10)) \
                                                $(bold $(dashes 10))    $(bold $(dashes 8))  $(bold $(dashes 12)) $(bold $(dashes 7))
    for ComponentID in $(yq '.global_components_meta | keys' < $CX/data/global.yml | grep -v "^#" | sed '/^\s*$/d;s/- //'); do
        oc get Subscription $(yq .global_components_meta.$ComponentID.sub_name < $CX/data/global.yml) --namespace $OperatorNS > /dev/null 2>&1 || continue
        queryCaseVersion $ComponentID
        queryOperatorStatus $ComponentID $OperatorNS
        queryOperandStatus $ComponentID $InstanceNS
        printf "$Format" "$(bold $ComponentID)" "$(normal $ScaleConfig)" "$($ColorStatus $ResourceStatus)" "$($ColorSpec $SpecVersion)" "$($ColorOperand $ReconciledVersion)" \
                                                "$($ColorOperator $OperatorStatus)" "$($ColorCSV $VersionCSV)" "$($ColorChannel $ChannelCurrent)" "$($ColorCase $CaseVersion)"
    done

    if [[ ! -z $(oc get crd | awk -F '.' '{if($1!=WKC&&$2==WKC) print $1}' WKC=wkc |\
                 xargs -n 1 oc get --namespace $InstanceNS --no-headers 2>/dev/null) ]]; then
        echo
        Format="  %-25s  %-28s  %-17s  %-24s  %18.18s  %21.21s\n"
        printf "$Format" "$(boldBlue WKC Component)" "$(boldBlue Custom Resource)" $(boldBlue Scale)   $(boldBlue Status)   $(boldBlue Version) $(boldBlue Reconciled)
        printf "$Format"  $(bold $(dashes 14))        $(bold $(dashes 17))         $(bold $(dashes 6)) $(bold $(dashes 13)) $(bold $(dashes 7)) $(bold $(dashes 10))
        for Component in $(oc get crd | awk -F '.' '{if($1!=WKC&&$2==WKC) print $1}' WKC=wkc); do
            [[ "|dataquality|wkcgovui|" =~ "|$Component|" ]] && ComponentStatus=componentStatus || ComponentStatus=${Component}Status
            ComponentJSON=$(oc get $Component --namespace $InstanceNS --output json |\
                            jq --compact-output ".items[] | {name: .metadata.name,
                                                             version: .spec.version,
                                                             scale: .spec.scaleConfig,
                                                             status: .status,
                                                             reconciled: .status.versions.reconciled}")
            [[ -z $ComponentJSON ]] && continue
            local Scale=$(jq --raw-output .scale <<< $ComponentJSON)
            [[ $Scale == null ]] && unset Scale
            local StatusWKC=$(jq --raw-output --arg Status $ComponentStatus '.status | .[$Status]' <<< $ComponentJSON)
            local StatusColor=normal
            [[ $StatusWKC == Completed ]] || StatusColor=red
            printf "$Format" "$(bold $Component)" "$(bold   $(jq --raw-output .name       <<< $ComponentJSON))" \
                                                  "$(normal $Scale)" "$($StatusColor $StatusWKC)" \
                                                  "$(normal $(jq --raw-output .version    <<< $ComponentJSON))" \
                                                  "$(normal $(jq --raw-output .reconciled <<< $ComponentJSON))"
        done
    fi

    if [[ ! -z $(oc get neo4j --namespace $InstanceNS 2>/dev/null) ]]; then
        echo
        Format="  %-29s  %-20s  %18.18s  %21.21s\n"
        printf "$Format" "$(boldBlue Neo4J Cluster)" $(boldBlue Status)  $(boldBlue Version) $(boldBlue Reconciled)
        printf "$Format"  $(bold $(dashes 18))       $(bold $(dashes 9)) $(bold $(dashes 7)) $(bold $(dashes 10))
        for Neo4jJSON in $(oc get neo4j --namespace $InstanceNS --output json |\
                           jq --compact-output '.items[] | {name: .metadata.name,
                                                            status: .status.neo4jStatus,
                                                            current: .status.versions.current,
                                                            reconciled: .status.versions.reconciled}'); do
            local NameNeo4j=$(jq --raw-output .name <<< $Neo4jJSON)
            local StatusNeo4j=$(jq --raw-output .status <<< $Neo4jJSON)
            local StatusColor=normal
            [[ $StatusNeo4j == Completed ]] || StatusColor=red
            printf "$Format" "$(bold $NameNeo4j)" "$($StatusColor $StatusNeo4j)" \
                             "$(normal $(jq --raw-output .current    <<< $Neo4jJSON))" \
                             "$(normal $(jq --raw-output .reconciled <<< $Neo4jJSON))"
        done
    fi

    if [[ ! -z $(oc get cluster --namespace $InstanceNS 2>/dev/null) ]]; then
        echo
        Format="  %-48s  %-35s\n"
        printf "$Format" "$(boldBlue Postgres Cluster)" $(boldBlue Status)
        printf "$Format"  $(bold $(dashes 37))          $(bold $(dashes 24))
        for PostgresClusterJSON in $(oc get cluster --namespace $InstanceNS --output json |\
                             jq --compact-output '.items[] | {name: .metadata.name,
                                                              status: .status.phase}' | tr ' ' '#'); do
            local NamePostgreSQL=$(jq --raw-output .name <<< $PostgresClusterJSON | tr '#' ' ')
            local StatusPostgreSQL=$(jq --raw-output .status <<< $PostgresClusterJSON | tr '#' ' ')
            local StatusColor=normal
            [[ $StatusPostgreSQL == "Cluster in healthy state" ]] || StatusColor=red
            printf "$Format" "$(bold $NamePostgreSQL)" "$($StatusColor $StatusPostgreSQL)"
        done
    fi

    if [[ ! -z $(oc get db2ucluster --namespace $InstanceNS 2>/dev/null) ]]; then
        echo
        Format="  %-23s  %-20s\n"
        printf "$Format" "$(boldBlue Db2U Cluster)" $(boldBlue Status)
        printf "$Format"  $(bold $(dashes 12))      $(bold $(dashes 9))
        for Db2uClusterJSON in $(oc get db2ucluster --namespace $InstanceNS --output json |\
                             jq --compact-output '.items[] | {name: .metadata.name, status: .status.state}'); do
            local StatusDb2U=$(jq --raw-output .status <<< $Db2uClusterJSON)
            local StatusColor=normal
            [[ $StatusDb2U == Ready ]] || StatusColor=red
            printf "$Format" "$(bold $(jq --raw-output .name <<< $Db2uClusterJSON))" "$($StatusColor $StatusDb2U)"
        done
    fi
    echo
}

#*------------------------------------------------------------
#* Delete Namespace
#*    1: Namespace ID
#*    2: Namespace
#*------------------------------------------------------------

deleteNamespace () {
    local NamespaceID=$1
    local Namespace=$2

    local DeleteProjectNamespace=$CX/tools/delete-cpd-namespace.sh
    if [[ ! -f $DeleteProjectNamespace ]]; then
        curl https://raw.githubusercontent.com/IBM/cpd-cli/refs/heads/master/cpdops/files/delete-cpd-namespace.sh 2> /dev/null |\
            sed -e "s/read -p.*/REPLY=Y/;s/retry_delay=5/retry_delay=30/" > $DeleteProjectNamespace
        chmod 755 $DeleteProjectNamespace
    fi

    local Outcome2Achieve="Delete ${NamespaceID^} Namespace, $Namespace"
    local DeleteLogFile=$CX/log/Delete.Namespace.$Namespace.log
    cat << EOF >> $LogFile

$(logCommand $Outcome2Achieve)$(echo -e $(getColor Purple))
$DeleteProjectNamespace $Namespace > $DeleteLogFile
$(echo -e $(getColor None))
EOF
    info "  $Outcome2Achieve" force
    $DeleteProjectNamespace $Namespace > $DeleteLogFile 2>&1 || abort "Failed to $Outcome2Achieve"
}

#*------------------------------------------------------------
#* Purge existing Deployment
#*------------------------------------------------------------

purgeDeployment () {
    log "Purge existing Deployment"
    LogFile=$CX/log/Purge.Existing.Deployment.log
    rm -f $LogFile

    prepareOLMutilities $LogFile

    local SchedulerNS=$(jq --raw-output .namespace.scheduler $Config4ROSA)
    [[ $SchedulerNS == null ]] && abort "IBM CPD Scheduler Namespace definition is missing in ROSA Configuration, $Config4ROSA"
    [[ -z $SchedulerNS ]] && abort "IBM CPD Scheduler Namespace is missing in ROSA Configuration, $Config4ROSA"

    if [[ ! -z $(oc project $SchedulerNS 2>/dev/null) ]]; then
        [[ -z $(oc get Scheduling ibm-cpd-scheduler --namespace $SchedulerNS 2>/dev/null) ]] || \
            abortOnFail "Delete IBM CPD Scheduler Custom Resource" \
                        "oc delete Scheduling ibm-cpd-scheduler --namespace $SchedulerNS"
        [[ -z $(oc get CustomResourceDefinition scheduling.scheduler.spectrumcomputing.ibm.com 2>/dev/null) ]] || \
            abortOnFail "Delete IBM CPD Scheduler Custom Resource Definition" \
                        "oc delete CustomResourceDefinition scheduling.scheduler.spectrumcomputing.ibm.com"
        for NamespaceID in $(jq --raw-output '.namespace | keys_unsorted | .[]' $Config4ROSA); do
            local Namespace=$(jq --raw-output --arg ID $NamespaceID '.namespace | .[$ID]' $Config4ROSA)
            oc project $Namespace >/dev/null 2>&1 || continue
            oc get pods --namespace $Namespace --no-headers | while read Pod Ready Status Misc; do
                if [[ $(oc get pod $Pod --namespace $Namespace --output jsonpath='{.spec.schedulerName}') == ibm-cpd-scheduler && \
                      $Status == Pending ]]; then
                    abortOnFail "Delete pending pod $Pod in namespace $Namespace" "oc delete pod $Pod --namespace $Namespace"
                fi
            done
        done
        deleteNamespace scheduler $SchedulerNS
    fi

    for NamespaceID in $(jq --raw-output '.namespace | keys_unsorted | .[]' $Config4ROSA); do
        local Namespace=$(jq --raw-output --arg ID $NamespaceID '.namespace | .[$ID]' $Config4ROSA)
        oc project $Namespace >/dev/null 2>&1 || continue
        deleteNamespace $NamespaceID $Namespace
    done
    pass "Purged existing Deployment" force
}

#*------------------------------------------------------------
#* Test Snippet
#*------------------------------------------------------------

testSnippet () {
    log "Test Snippet"
}

#*------------------------------------------------------------
#* Main
#*------------------------------------------------------------

defineDefaults $(dirname $0)

parseOptions $*

case $_Action in
    configure)   configurePreRequisites;;
    deployHub)   deploySoftwareHub;;
    deployIKC)   deployService wkc;;
    deployMANTA) deployService mantaflow;;
    queryDetail) queryClusterDetail;;
    purgeDeploy) purgeDeployment;;
    testSnippet) testSnippet;;
esac

exit 0
