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
**Version 2.0: Kernel Validation Added**

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

<u>updated code:</u>
```
#!/bin/bash

# Define the list of nodes
NODES=("node1.example.com" "node2.example.com")

# Expected kernel version
REQUIRED_KERNEL="5.4.0-100"

# Function to check SSH connectivity and kernel version
check_node() {
    local node="$1"

    # Attempt SSH connection with a timeout
    if ssh -o ConnectTimeout=5 -q "$node" exit; then
        echo "[$node] SSH connection successful"
    else
        echo "[$node] SSH FAILED"
        return
    fi

    # Check Kernel version
    kernel=$(ssh "$node" "uname -r")
    if [[ "$kernel" == "$REQUIRED_KERNEL" ]]; then
        echo "[$node] Kernel version is correct ($kernel)"
    else
        echo "[$node] Kernel mismatch: expected $REQUIRED_KERNEL, found $kernel"
    fi
}

# Loop through each node and check SSH + Kernel
for node in "${NODES[@]}"; do
    check_node "$node"
done
```
	
-------------------------------------------------------------------------------------------------
**Version 3.0: Disk Space Validation Added**

1. Add a variable to store the minimum disk space required (in GB)
`MIN_DISK_GB=50`
	- defines the minimum required disk space 



2. Check Disk Space

	- Retrieve Disk Space information:
`disk_space=$(ssh "$node" "df -BG / | awk 'NR==2{print \$4}' | tr -d 'G'")`
	- runs `df -BG /` on the remote node to check disk space on the root `/`
	- uses `awk` to extract the available space
		- `awk` is a text-processing tool in linux, it reads input line-by-line, allowing us to manipulate text based on patterns.
		- `NR==2` refers to the current line number, so it only processes line 2
		- `{print $4}` prints column 4 (**available space** column from the `df -BG /` output, shown below)
		- `re -d 'G'` removes the "G" so we can compare it as a number

`df -BG /` will output something like:

```
Filesystem     1G-blocks  Used Available Use% Mounted on
/dev/sda1          100G    40G       60G  40% /
```

`NR==1` will be the header block(Line 1):
`Filesystem     1G-blocks  Used Available Use% Mounted on`

we need (Line 2), `NR==2`: 
`/dev/sda1          100G    40G       60G  40% /`

|**Column($1,$2,etc)** |                 ** Value**                  |
|----------------------|---------------------------------------------|
|$1                    |/dev/sda1                                    |
|$2                    |100G(Total disk space)                       |
|$3                    |40G(Used space)                              |
|$4                    |60G(Available space, we need this!)          |
|$5                    |40%(Usage percentage)                        |
|$6                    |/(Mount point)                               |

```
if (( disk_space >= MIN_DISK_GB )); then
    echo "[$node] Sufficient disk space available (${disk_space}GB)"
else
    echo "[$node] Low disk space: only ${disk_space}GB available (minimum required: ${MIN_DISK_GB}GB)"
fi

```
	
-----------------------------------------------------------------------------------------------
**Version 4.0: Required security package check**

1. Add a variable to store the name of the required (security) package
`REQUIRED_PKG="security-pkg"` 
(this could also be an array of variables if there are more than one required packages)


2. Package validation command
```
if ssh "$node" "dpkg -l | grep -q '^ii.*$REQUIRED_PKG'"; then
	echo "[$node] Required package '$REQUIRED_PKG' is installed"
else
	echo "[$node] Missing required package: $REQUIRED_PACKAGE"
fi
```

**Breakdown:**
runs this entire command on the remote node via ssh:
`dpkg -l | grep -q '^ii.*security-pkg'`
	- if the package is found it prints success
	- if the package is missing, it prints a warning

**dpkg command:**
- `dpkg -l` lists all installed packages
- `grep -q` searches the file for a specific pattern, if its found it exits with a success status of **0**. if not found within file it exits with a non-zero status.
- `'^ii.*$REQUIRED_PKG'`
	- `^` matches the beginning of a line
	- `ii` matches the two characters ii, meaning the package is installed
	- `.*` matches any character (except newline)
	- `$REQUIRED_PKG` the name of the package we're looking for
----------------------------------------------------------------------------------------------------
**Version 5.0: Banned services validation + global status tracker (ssh_ok)**

1. Implementing `ssh_ok` for node status tracking
`local ssh_ok=true`
	- initialize `ssh_ok` to **true** at the start of `check_node()` function
	- this means the node/server is assumed to have no issues (unless its changed to false)

2. setting `ssh_ok` to false when a check fails
- add `ssh_ok=false` whenever one of the services fails (within its if statements)

3. Checking for Banned services
```
for service in "${BANNED_SERVICES[@]}"; do
	if ssh "$node" "systemctl is-active --quiet $service"; then
		echo "[$node] Banned service running: $service"
		ssh_ok=false
	fi
done
```
	- loops through each banned service in the `$BANNED_SERVICES` array
	- if the service is **NOT** running, command fails, nothing happens
	- if the servie **IS** running, command succeeds, prints a warning and sets `ssh_ok=false`

4. Printing success only if all the checks pass
`$ssh_ok && echo "[$node] Configuration OK!"`
	- if `ssh_ok` is still `true` at the end, it prints the message.

--------------------------------------------------------------------------------------------------
**Version 6.0: Logging System for Audit & Truoubleshooting**

-This will log all outputs to a file, making it easier to track nodes.

1. Define the Log file name
`LOG_FILE="nodevalidation_$(date +%Y%m%d).log"`
	- defines a log filename that includes the current date
	- this helps to make sure new logs don't overwrite old ones!

2. Redirecting all output to the log file
`exec > >(tee -a "$LOG_FILE") 2>&1`
	- redirects all script output (both `stdout` and `stderr`) to:
		- the log file `$LOG_FILE`
		- the terminal `tee`, so we still see a live output.

3. Add Visual Markets for each node
Simple, just make the output more readable!
```
echo "===== Checking Node: $node ====="
echo "===== Finished Checking: $node ====="
```

4. Running checks in paralell (for speed)
edit the code to include `&` -sends it to the background(below)
```
for node in "${NODES[@]}"; do
	check_node "$node" &                        <----here!
done

wait # wait for all parallel checks
```
	- `wait` ensures all parallel processes are finished before continuing


5. Summary message
`echo "Validation complete. Review $LOG_FILE"`
	- prints the log file location after all the checks finish
	- useful for finding the log more easily

