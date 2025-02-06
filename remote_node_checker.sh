#!/bin/bash

# Define the list of nodes 
NODES=("node1.example.com" "node2.example.com")

# Expected kernel version 
REQUIRED_KERNEL="5.4.0-100"

# Minimum disk space required (in GB)
MIN_DISK_GB=50

# Required security package
REQUIRED_PKG="security-pkg"

# Banned services that should not be running
BANNED_SERVICES=("telnetd" "httpd")

# Function to check SSH connectivity 
check_ssh() {
	local node="$1"
	local ssh_ok=true

	# Attempt the SSH connection with a timeout
	if ssh -o ConnectTimeout=5 -q "$node" exit; then
		echo "[$node] SSH connection successful"
	else
		echo "[$node] SSH FAILED"
#		return
	fi



	# Check Kernel version
	kernel=$(ssh "$node" "uname -r")
	if [[ "Skernel" == "$REQUIRED_KERNEL" ]]; then
		echo "[$node] Kernel version is correct ($kernel)"
	else
		echo "[$node] Kernel mismatch: expected $REQUIRED_KERNEL, found $kernel"
		ssh_ok=false
	fi

	# Check Disk Space
	disk_space=$(ssh "$node" "df -BG / | awk 'NR==2{print \$4}' | tr -d 'G'")
	if (( disk_space >= MIN_DISK_GB )); then
		echo "[$node] Sufficient disk space available (${disk_space}GB)"
	else
		echo "[$node] Low disk space: only ${disk_space}GB available (minimum required: ${MIN_DISK_GB}GB)"
		ssh_ok=false
	fi

	# Check is required package is installed
	if  ssh "$node" "dpkg -l | grep -q '^ii.*REQUIRED_PKG'"; then
		echo "[$node] $REQUIRED_PKG Installed."
	else
		echo "[$node] Missing required package: $REQUIRED_PKG"
		ssh_ok=false
	fi

	# Check for banned services
	for service in "${BANNED_SERVICES[@]}"; do
		if ssh "$node" "systemctl is-active --quiet $service"; then
			echo "[$node] Banned service running: $service"
			ssh_ok=false
		fi
	done


	# Final compliance check
	$ssh_ok && echo "[$node] Configuration OK"


	
}

# Loop through each node and check SSH + Kernel + Disk
for node in "${NODES[@]}"; do
	check_ssh "$node"
done


