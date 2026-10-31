#!/usr/bin/env bash
# Tailscale state for waybar.
#
# Emits the "hidden" class (collapsed by style.css) whenever the tunnel is not
# actually up -- stopped, logged out, daemon not answering, tailscale not
# installed. These scripts are shared across machines via Dropbox and a stale
# or speculative "connected" would be worse than nothing.
#
# ICONS ARE WRITTEN AS \u ESCAPES, NEVER AS LITERAL GLYPHS. They are Private
# Use Area codepoints: they carry no meaning to anything that is not a Nerd
# Font, they look like a blank in every editor, diff and terminal without one,
# and they are silently dropped by anything that filters or re-encodes text.
# That is not hypothetical -- the sibling waybar-mousebattery.sh shipped for
# months with an EMPTY charging icon for exactly this reason, and the failure
# is invisible: a lost icon just looks like the space it left behind.
ICON_SHIELD=$'\uf132'   # nf-fa-shield -- the tailnet is up
ICON_GLOBE=$'\uf0ac'    # nf-fa-globe  -- ...and egress is via an exit node
#
# The STATE IS THE GLYPH, not a colour and not a text label. Two reasons:
#
#   * every other module on this bar is value+icon ("45% <mouse>", "12% <cpu>")
#     or icon-only (idle_inhibitor), so the old "TS: on" was the one label on
#     the bar -- and it spent five characters saying what a shield says;
#   * colour on this bar is reserved for a PROBLEM (.warning, .critical,
#     #temperature.critical). Connected is not a problem, and neither is
#     routing through an exit node, so a green "everything is fine" would be
#     the only decorative colour on the bar. The classes are still emitted so
#     that stays a style.css decision rather than a script change.
#
# The DETAIL moved to the tooltip, which is free: the text got shorter, so
# peers, tailnet and addresses can be spelled out properly there.

emit_hidden() { jq -nc --arg t "$1" '{text:"",tooltip:$t,class:"hidden"}'; }

command -v tailscale >/dev/null || emit_hidden "Tailscale is not installed"
command -v tailscale >/dev/null || exit 0

# ONE `tailscale status` and ONE jq, at a 2 s interval. This used to be one
# status call piped through two separate jq processes, i.e. three processes
# every two seconds, forever, to render one glyph.
# Overridable ONLY so the arms that need a live exit node, a logged-out
# daemon or a stopped tunnel can be exercised against a recorded status blob
# -- there is no way to reach them on demand, and this file is shared across
# machines.
if [[ -n ${TS_STATUS_FILE:-} ]]; then
    ts_json=$(< "$TS_STATUS_FILE")
else
    ts_json=$(tailscale status --json 2>/dev/null)
fi
[[ -n $ts_json ]] || { emit_hidden "Tailscale: daemon not responding"; exit 0; }

# The whole widget is built here rather than in bash so that a hostname
# containing a quote or a backslash cannot corrupt the JSON waybar parses --
# the old printf-with-%s could emit a broken frame, and a malformed frame is
# not a wrong icon, it is no module at all.
printf '%s' "$ts_json" | jq -c \
    --arg shield "$ICON_SHIELD" \
    --arg globe  "$ICON_GLOBE" '
  def peers: (.Peer // {}) | to_entries | map(.value);
  (.BackendState // "Unknown")                        as $state
  | (peers | map(select(.ExitNode == true)) | first)  as $exit
  | (peers | map(select(.Online == true)) | length)   as $up
  | (peers | length)                                  as $total
  | (.Self.HostName // "?")                           as $me
  | (.Self.TailscaleIPs[0]? // "")                    as $myip
  | (.MagicDNSSuffix // "")                           as $net
  | ([ ($me + (if $myip == "" then "" else "  " + $myip end)),
       (if $net == "" then empty else $net end),
       "\($up)/\($total) peers online" ] | join("\n")) as $base
  | if $state != "Running" then
      { text: "",
        tooltip: "Tailscale: \($state)",
        class: "hidden" }
    elif $exit then
      { text: "\($exit.HostName) \($globe)",
        tooltip: "Exit node: \($exit.HostName)  \($exit.TailscaleIPs[0]? // "")\n\($base)",
        class: "connected-exit" }
    else
      { text: $shield,
        tooltip: "Connected — direct egress\n\($base)",
        class: "connected" }
    end
'
