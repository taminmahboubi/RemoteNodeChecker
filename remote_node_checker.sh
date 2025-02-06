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

# Logging setup
LOG_FILE="node_validation_$(date +%Y%m%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to check SSH connectivity 
check_ssh() {
	local node="$1"
	local ssh_ok=true

	echo "===== Checking Node: $node ====="

	# Attempt the SSH connection with a timeout
	if ssh -o ConnectTimeout=5 -q "$node" exit 2>/dev/null; then
		echo "[$node] SSH connection successful"
	else
		echo "[$node] SSH FAILED"
#		return
	fi



	# Check Kernel version
	kernel=$(ssh "$node" "uname -r" 2>/dev/null)
	if [[ "Skernel" == "$REQUIRED_KERNEL" ]]; then
		echo "[$node] Kernel version is correct ($kernel)"
	else
		echo "[$node] Kernel mismatch: expected $REQUIRED_KERNEL, found $kernel"
		ssh_ok=false
	fi

	# Check Disk Space
	disk_space=$(ssh "$node" "df -BG / | awk 'NR==2{print \$4}' | tr -d 'G'" 2>/dev/null)
	if (( disk_space >= MIN_DISK_GB )); then
		echo "[$node] Sufficient disk space available (${disk_space}GB)"
	else
		echo "[$node] Low disk space: only ${disk_space}GB available (minimum required: ${MIN_DISK_GB}GB)"
		ssh_ok=false
	fi

	# Check is required package is installed
	if  ssh "$node" "dpkg -l | grep -q '^ii.*REQUIRED_PKG'" 2>/dev/null; then
		echo "[$node] $REQUIRED_PKG Installed."
	else
		echo "[$node] Missing required package: $REQUIRED_PKG"
		ssh_ok=false
	fi

	# Check for banned services
	for service in "${BANNED_SERVICES[@]}"; do
		if ssh "$node" "systemctl is-active --quiet $service" 2>/dev/null; then
			echo "[$node] Banned service running: $service"
			ssh_ok=false
		fi
	done


	# Final compliance check
	$ssh_ok && echo "[$node] Configuration OK"

	echo "===== Finished Checking: $node ====="
	echo "" # blank line for readability

}

# Loop through each node and check SSH + Kernel + Disk
for node in "${NODES[@]}"; do
	check_ssh "$node" 
done

#wait # wait for all parallel checks
echo "Validation complete. Review $LOG_FILE"

