#!/usr/bin/env bash

notify() {
    dunstify --urgency low \
             --hints string:x-dunst-stack-tag:tailscale \
             --timeout 2500 \
             "$1" "$2"
}

run_ts() {
    output=$("$@" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Error running: $*" >&2
        echo "$output" >&2
        if echo "$output" | grep -qi "permission\|operator\|not allowed"; then
            notify "Tailscale" "Run once: sudo tailscale set --operator=$USER"
        else
            notify "Tailscale Error" "$output"
        fi
        exit 1
    fi
}

pick_exit_node() {
    local exit_nodes_display exit_nodes_ips chosen idx
    exit_nodes_display=$(echo "$ts_json" | jq -r '.Peer // {} | to_entries[] | .value | select(.ExitNodeOption == true) | "\(.HostName) (\(.TailscaleIPs[0]))"')
    exit_nodes_ips=$(echo "$ts_json" | jq -r '.Peer // {} | to_entries[] | .value | select(.ExitNodeOption == true) | .TailscaleIPs[0]')
    if [[ -z "$exit_nodes_display" ]]; then
        notify "Tailscale" "No exit nodes available"
        exit
    fi
    chosen=$(echo -e "$exit_nodes_display" | rofi -dmenu -p "Exit Node")
    [[ -z "$chosen" ]] && return
    # Find the IP for the chosen line by index
    idx=$(echo -e "$exit_nodes_display" | grep -n "^${chosen}$" | cut -d: -f1)
    echo -e "$exit_nodes_ips" | sed -n "${idx}p"
}

list_nodes() {
    local nodes
    nodes=$(echo "$ts_json" | jq -r '
        .Peer // {} | to_entries[] | .value |
        "\(if .Online then "●" else "○" end)  \(.HostName)  \(.TailscaleIPs[0] // "-")\(if .ExitNodeOption then "  [exit]" else "" end)"
    ')
    if [[ -z "$nodes" ]]; then
        notify "Tailscale" "No peers found"
        exit
    fi
    echo -e "$nodes" | rofi -dmenu -p "Nodes" -no-custom
}

ts_json=$(tailscale status --json 2>/dev/null)
is_running=$(echo "$ts_json" | jq -r '.BackendState')
current_exit_node=$(echo "$ts_json" | jq -r '[.Peer // {} | to_entries[] | .value | select(.ExitNode == true) | .HostName] | first // ""')

if [[ "$is_running" == "Running" ]]; then
    if [[ -n "$current_exit_node" ]]; then
        entries="⏼ Disconnect\n🌐 Remove Exit Node ($current_exit_node)\n📋 Nodes"
    else
        entries="⏼ Disconnect\n🌐 Use Exit Node\n📋 Nodes"
    fi
elif [[ "$is_running" == "NeedsLogin" ]]; then
    notify "Tailscale: Not Logged In" "Run: sudo tailscale login\nThen: sudo tailscale set --operator=$USER"
    exit
else
    entries="▶ Connect\n▶ Connect via Exit Node\n📋 Nodes"
fi

selected=$(echo -e "$entries" | rofi -dmenu -p "Tailscale")
[[ -z "$selected" ]] && exit

case "$selected" in
    "▶ Connect")
        run_ts tailscale up --accept-routes --exit-node= --exit-node-allow-lan-access=false
        notify "Tailscale" "Connected"
        ;;
    "▶ Connect via Exit Node")
        node=$(pick_exit_node)
        [[ -z "$node" ]] && exit
        run_ts tailscale up --accept-routes --exit-node-allow-lan-access --exit-node="$node"
        notify "Tailscale" "Connected via $node"
        ;;
    "⏼ Disconnect")
        run_ts tailscale down
        notify "Tailscale" "Disconnected"
        ;;
    "🌐 Use Exit Node")
        node=$(pick_exit_node)
        [[ -z "$node" ]] && exit
        run_ts tailscale up --accept-routes --exit-node-allow-lan-access --exit-node="$node"
        notify "Tailscale" "Exit node: $node"
        ;;
    "🌐 Remove Exit Node ("*)
        run_ts tailscale up --accept-routes --exit-node= --exit-node-allow-lan-access=false
        notify "Tailscale" "Exit node removed"
        ;;
    "📋 Nodes")
        list_nodes
        ;;
esac
