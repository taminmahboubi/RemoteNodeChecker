#!/bin/bash

# Define the list of nodes 
NODES=("node1.example.com" "node2.example.com")

# Function to check SSH connectivity 
check_ssh() {
	local node="$1"

	# Attempt the SSH connection with a timeout
	if ssh -o ConnectTimeout=5 -q "$node" exit; then
		echo "[$node] SSH connection successful"
	else
		echo "[$node] SSH FAILED"
	fi
	
}


# Loop through each node and check SSH
for node in "${NODES[@]}"; do
	check_ssh "$node"
done


