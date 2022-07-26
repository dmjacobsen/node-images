#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
set -euo pipefail

RETRY=0
MAX_RETRIES=30
RETRY_SECONDS=10
export KUBECONFIG="/etc/kubernetes/admin.conf"

if [ $(hostname) != "ncn-m001" ]; then
  echo "$0 is designed to run on ncn-m001. If this is a different node then there is no reason for this to try to join storage nodes to spire. Exiting."
  exit 1
fi

until kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server healthcheck | grep 'Server is healthy'; do
    if [[ "$RETRY" -lt "$MAX_RETRIES" ]]; then
        RETRY="$((RETRY + 1))"
        echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
    else
        echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
        exit 1
    fi
    sleep "$RETRY_SECONDS"
done

URL="https://spire-tokens.spire:54440/api/token"
POD=$(kubectl get pods -n spire | grep spire-server | grep Running | awk 'NR==1{print $1}')
LOADBALANCERIP=$(kubectl get service -n spire spire-lb --no-headers --output=jsonpath='{.spec.loadBalancerIP}')

function sshnh() {
    /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}

if hostname | grep -q 'pit'; then
    echo "This script is not supported on pit nodes. Please run it on ncn-m002."
    exit 1
fi

nodes=$(ceph node ls | jq -r '.[] | keys[]' | sort -u)

# Make changes to the installation prefix a bit easier with vars
prefix=/var/lib/spire
conf="${prefix}/conf"
socket="${prefix}/agent.sock"
datadir="${prefix}/data"
svidkey="${datadir}/svid.key"
bundleder="${datadir}/bundle.der"
agentsvidder="${datadir}/agent_svid.der"
jointoken="${conf}/join_token"
spireagent="${conf}/spire-agent.conf"
spirebundle="${conf}/bundle.crt"

for node in $nodes; do
	if sshnh "$node" spire-agent healthcheck -socketPath="${socket}" 2>&1 | grep -q "healthy"; then
		echo "$node is already joined to spire and is healthy."
	else
		if sshnh "$node" ls "${svidkey}" > /dev/null 2>&1; then
			echo "$node was once joined to spire. Cleaning up old files"
			sshnh "$node" rm "${svidkey}" "${bundleder}" "${agentsvidder}"
		fi
		echo "$node is being joined to spire."
		XNAME="$(sshnh "$node" cat /proc/cmdline | sed 's/.*xname=\([A-Za-z0-9]*\).*/\1/')"
		TOKEN="$(kubectl exec -n spire "$POD" --container spire-registration-server -- curl -k -X POST -d type=storage\&xname="$XNAME" "$URL" | tr ':' '=' | tr -d '"{}')"
		sshnh "$node" "echo $TOKEN > ${jointoken}"
		kubectl get configmap -n spire spire-ncn-config -o jsonpath='{.data.spire-agent\.conf}' | sed "s/server_address.*/server_address = \"$LOADBALANCERIP\"/" | sshnh "$node" "cat > ${spireagent}"
		kubectl get configmap -n spire spire-bundle -o jsonpath='{.data.bundle\.crt}' | sshnh "$node" "cat > ${spirebundle}"
		sshnh "$node" systemctl enable spire-agent
		sshnh "$node" systemctl start spire-agent
	fi
done
