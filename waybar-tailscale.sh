#!/usr/bin/env bash

ts_json=$(tailscale status --json 2>/dev/null)
state=$(echo "$ts_json" | jq -r '.BackendState')
exit_node=$(echo "$ts_json" | jq -r '[.Peer // {} | to_entries[] | .value | select(.ExitNode == true) | .HostName] | first // ""')

case "$state" in
    Running)
        if [[ -n "$exit_node" ]]; then
            text="VPN: $exit_node"
            tooltip="Connected via exit node: $exit_node"
            class="connected-exit"
        else
            text="TS: on"
            tooltip="Connected"
            class="connected"
        fi
        ;;
    Stopped)
        text=""
        tooltip="Tailscale disconnected"
        class="hidden"
        ;;
    NeedsLogin)
        text=""
        tooltip="Tailscale: not logged in"
        class="hidden"
        ;;
    *)
        text=""
        tooltip="Tailscale: $state"
        class="hidden"
        ;;
esac

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
