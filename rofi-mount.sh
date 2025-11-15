#!/usr/bin/env bash

# using lxqt-policykit-agent for sudo authentication

action="$1"
if [[ "$action" != "mount" && "$action" != "unmount" ]]; then
    echo "Usage: $0 <mount|unmount>"
    exit 1
fi

# Function to send notifications
notify() {
    local status="$1"
    local message="$2"
    local icon="$3"

    dunstify --urgency low \
             --hints string:x-dunst-stack-tag:mount \
             --icon="$icon" \
             --timeout 2500 \
             "$status: $message"
}

# Get all partitions as JSON
all_devices=$(lsblk --json -o NAME,SIZE,LABEL,TYPE,MOUNTPOINT)

# Prepare list for rofi: show NAME, SIZE, LABEL; keep NAME for action
if [[ "$action" == "mount" ]]; then
    devices=$(echo "$all_devices" | jq -r '
        .blockdevices[] | .. | objects 
        | select(.type=="part" and (.mountpoint == null)) 
        | "\(.name) \(.size) \(.label // "")"')
elif [[ "$action" == "unmount" ]]; then
    devices=$(echo "$all_devices" | jq -r '
        .blockdevices[] | .. | objects 
        | select(.type=="part" and (.mountpoint != null) and (.mountpoint != "/" and .mountpoint != "/boot")) 
        | "\(.name) \(.size) \(.label // "")"')
fi

# If no devices found, notify and exit
if [[ -z "$devices" ]]; then
    notify "No Devices" "No partitions available for $action." "dialog-information"
    exit 1
fi

# Let user choose device
chosen=$(echo -e "$devices" | rofi -dmenu -p "Drives")
[[ -z "$chosen" ]] && exit

dev_name=$(echo "$chosen" | awk '{print $1}')

# Perform the action
if [[ "$action" == "mount" ]]; then
    output=$(udisksctl mount -b "/dev/$dev_name" 2>&1)
    if [[ $? -eq 0 ]]; then
        mount_point=$(echo "$output" | awk -F" at " '{print $2}' | sed 's/\.//')
        notify "Mount Success" "/dev/$dev_name mounted at $mount_point" "drive-harddisk"
    else
        notify "Mount Failed" "/dev/$dev_name: $output" "dialog-error"
    fi
elif [[ "$action" == "unmount" ]]; then
    output=$(udisksctl unmount -b "/dev/$dev_name" 2>&1)
    if [[ $? -eq 0 ]]; then
        notify "Unmount Success" "/dev/$dev_name unmounted" "drive-harddisk"
    else
        notify "Unmount Failed" "/dev/$dev_name: $output" "dialog-error"
    fi
fi

