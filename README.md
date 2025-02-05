# RemoteNodeChecker
A script that remotely audits multiple nodes over SSH, validating kernel version, disk space, required packages, and banned services 

----------------------------------------------------------------------------------------------------------------------------------

**Requirements**

**Inputs:**
1. List of nodes to validate
2. Expected configurations:
	- Required kernel version (kernel being the core part of an OS that acts as a bridge between hardware/software, managing memory, processes, devices)
	- Minimum disk space available
	- Required security package
	- List of banned services that must not be running
3. SSH access to nodes for remote execution

**Outputs:**
1. Log file containing:
	- Node validation results
	- Errors found (e.g missing package, incorrect kernel, low disk space, banned service running).
	- Nodes that failed SSH access
2. Final validation summary with the status of all nodes

**Edge Cases:**
1. SSH failures
2. Permission issues preventing remote checks
3. Nodes missing required tools
4. Unexpected node responses 

----------------------------------------------------------------------------------------------------------------------------------------------------

<u>**Version 1.0**</u>

-**Create an array of Nodes containing the hostnames/IPs of the servers**
(using an array makes it easy to loop though multiple nodes instead of writing seperate commands for each)

`NODES=("node1.example.com" "node2.example.com")`
 
-Create a function to check SSH connectivity
`check_ssh() {`

-Create a `local` variable (so it only exists inside this function) called `node` that takes the first argument passed to the fuction `$1`
`local node="$1"`


-**Attempt the SSH connection with a timeout** 
`if ssh -o ConnectTimeout=5 -q "$node" exit; then`
- tries to connect to `"$node"` using SSH
- Uses:
	- `-o ConnectTimeout=5` limits SSH timeout to 5 seconds (prevents hanging if node is unreachable)
	- `-q` Quiet mode (hides any unnecessary output) (suppresses SSH warning, keeping the output clean)
	- `exit` immediately exits the SSH session

(if *successful*)
`echo "[$node] SSH connection successful"`

it will print: `[node1.example.com] SSH connection successful`

(if *unsuccessful*)
`else`

`echo "[$node] SSH FAILED"

it will print: `[node1.example.com] SSH FAILED` after 5 seconds
`fi`
`}`


-**Loop through each node and check SSH**
`for node in "${NODES[@]}"; do`
- loops through each *node* in the `NODES` array.
- stores the current node in `node` and executes the commands inside the loop.

`check_ssh "$node"`
- calls `check_ssh` function and passes `"$node"` as an argument.
- the function checks if SSH works for the current node in the loop.
`done` - ends the `for` loop

----------------------------------------------------------------------------------------------------
**Pseudocode**

1. Create an `array` of nodes called *NODES* e.g.("tony@192.168.2.37" "toby@192.168.2.38")

2. create a `function` to check the `ssh` connectivity:
	- create a `local` node called `node` that takes the first argument `$1`
	- check `if` the `node` will connect via `ssh`, exit after 5 seconds (prevents hanging) 
		- `true` - then `echo` a successful ssh connection
		- `else` - `echo` a failed ssh connection  

3. `for` loop through `$NODES`
	- passing each iteration as an arguement for the `function`


```
#!/bin/bash

# Define the list of nodes
NODES=("node1.example.com" "node2.example.com")

# Function to check SSH connectivity
check_ssh() {
    local node="$1"
    
    # Attempt SSH connection with a timeout
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
```
---------------------------------------------------------------------------------------------
<u>**Version 2.0: Kernel Validation Added**</u>

1. Added a variable for storing the required kernel version:
`REQUIRED_KERNEL="5.4.0-100"`
-makes it easy to update the requirement without having to modify it in multiplaces within the script.


within the `check_node` function, we want to retrieve kernel version:
`kernel=$(ssh "$node" "uname -r")`

	- `uname -r` prints the kernel version currently running on a system
	- stores the kernel version of from the remote machine into `kernel` variable


2. Compare Kernel Version to `REQUIRED_KERNEL`
```
if [[ "$kernel" == "$REQUIRED_KERNEL" ]]; then
	echo "[$node] Kernel version is correct ($kernel)"
else
	echo "[$node] Kernel mismatch: expected $REQUIRED_KERNEL, found $kernel"
fi 	
```
	- Checks if the retrieved kernel version matches the expected one (REQUIRED_KERNEL)
	- prints a different message depending if the match was successful or not.
	
