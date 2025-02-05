#!/bin/bash

# Define the list of nodes 
NODES=("node1.example.com" "node2.example.com")

# Expected kernel version 
REQUIRED_KERNEL="5.4.0-100"

# Function to check SSH connectivity 
check_ssh() {
	local node="$1"

	# Attempt the SSH connection with a timeout
	if ssh -o ConnectTimeout=5 -q "$node" exit; then
		echo "[$node] SSH connection successful"
	else
		echo "[$node] SSH FAILED"
	fi



	# Check Kernel version
	kernel=$(ssh "$node" "uname -r")
	if [[ "Skernel" == "$REQUIRED_KERNEL" ]]; then
		echo "[$node] Kernel version is correct ($kernel)"
	else
		echo "[$node] Kernel mismatch: expected $REQUIRED_KERNEL, found $kernel"
	fi
}

# Loop through each node and check SSH
for node in "${NODES[@]}"; do
	check_ssh "$node"
done


