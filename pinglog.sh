#!/bin/bash

# Define the base name for the PID files
PID_BASE_NAME="./pids"
LAST_PID_FILE="last_pids_file"

# Create log directory
create_log_dir() {
    DATE=$(date +"%Y%m%d")
    HOUR=$(date +"%H")
    MINUTE=$(date +"%M")
    LOG_DIR="./logs/$DATE"
    mkdir -p "$LOG_DIR"
}

# Define a function for pinging
ping_ip() {
    local ip=$1
    local LOG_FILE="${LOG_DIR}/${DATE}${HOUR}${MINUTE}__${ip//./_}.log"  # Replace "." in IP address with "_"

    # Create a named pipe
    PIPE=/tmp/ping_pipe_$RANDOM
    mkfifo "$PIPE"

    # Start the tee process in the background
    tee -a "$LOG_FILE" < "$PIPE" > /dev/null 2>&1 &

    # Start the ping command and redirect output to the named pipe
    ping "$ip" > "$PIPE" 2>&1 &
    local pid=$!  # Save the PID of the ping command

    # Cleanup
    trap "rm -f '$PIPE'" EXIT

    echo "$pid"  # Return the PID of the ping process
}

# Start ping processes and save their PIDs
start_ping() {
    create_log_dir
    local ips=()
    local pid_file="${PID_BASE_NAME}_$(date +%s)"  # Use current timestamp as part of the filename, without suffix

    # Stop previous processes if any
    if [[ -f "$LAST_PID_FILE" ]]; then
        last_pid_file_content=$(<"$LAST_PID_FILE")  # Read the content of the last PID file
        stop_ping "$last_pid_file_content"  # Stop the processes listed in the last PID file
    fi

    echo "$pid_file" > "$LAST_PID_FILE"  # Write the current PID file path to the last PID file

    if [[ -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            # Read file content line by line
            while IFS= read -r line; do
                # Ignore empty lines
                if [[ -n "$line" ]]; then
                    ips+=("$line")
                fi
            done < "$1"
        else
            ips=("$@")  # Treat all arguments as IP addresses
        fi
    else
        echo "Please provide an IP address or file path."
        exit 1
    fi

    for ip in "${ips[@]}"; do
        # Start the ping process and capture its PID
        local pid=$(ping_ip "$ip")  # Get the returned PID
        echo "$pid" >> "$pid_file"  # Save the PID of the process
    done
}

# Stop ping processes
stop_ping() {
    if [[ -n "$1" && -f "$1" ]]; then
        while read -r pid; do
            if ps -p "$pid" > /dev/null; then
                kill -9 "$pid"
                echo "Stopped process: $pid"
            else
                echo "Process $pid does not exist"
            fi
        done < "$1"
        # Delete the PID file
        rm "$1"
    else
        echo "Please provide a valid PID file path or ensure LAST_PID_FILE exists."
    fi
}

# Main logic
if [[ "$1" == "start" ]]; then
    shift  # Remove the first argument (start)
    start_ping "$@"
elif [[ "$1" == "stop" ]]; then
    if [[ -f "$2" ]]; then
        stop_ping "$2"  # The second argument is the PID file path
    elif [[ -f "$LAST_PID_FILE" ]]; then
        last_pid_file_content=$(<"$LAST_PID_FILE")  # Read the content of the last PID file
        stop_ping "$last_pid_file_content"  # Stop the processes listed in the last PID file
        rm "$LAST_PID_FILE"
    fi
else
    echo "Usage: $0 {start|stop} [IP address or file path]"
    exit 1
fi
