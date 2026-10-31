#!/usr/bin/env bash
# Logitech wireless mouse battery, via the kernel's hid-logitech-hidpp driver.
#
# Emits the "hidden" class (collapsed by style.css, same as waybar-tailscale.sh)
# when no such device is present or the link is down -- the mouse is off, it is
# unpaired, or this machine has no Logitech receiver at all. These scripts are
# shared across machines via Dropbox, and a stale percentage would be worse
# than no percentage.
#
# NOTE: the icons are the NERD FONT codepoints (U+EFBA, U+F0E7, U+F1E6), not
# Font Awesome's own U+F8CC. style.css asks for Roboto/Helvetica/Arial at
# normal weight, and on this box U+F8CC is carried by exactly one font -- Font
# Awesome 7 Free *Solid*, weight 900 -- which the fallback never reaches, so it
# renders as nothing. All three used here are in the same ~44 Nerd Font faces
# at weight 400, the same coverage as the cpu/battery icons that already work.
#
# PLUGGING THE MOUSE IN CREATES A SECOND, DIFFERENT POWER_SUPPLY DEVICE, and
# that is what this script gets wrong if written the obvious way. The
# LIGHTSPEED receiver link and the USB cable are two hidpp_battery_N entries
# with the SAME serial_number:
#
#   hidpp_battery_0  .../C543.0009/40A8.000B/  online=0  status=Unknown
#   hidpp_battery_1  .../C09A.001C/            online=1  status=Charging
#
# Two consequences, each of which alone hides the widget exactly when you plug
# in -- i.e. the failure is invisible until it is the one thing you wanted:
#
#   * The wired entry hangs off the HID++ VENDOR INTERFACE (:1.2), which has NO
#     input node at all -- the mouse's input nodes are on the sibling
#     interfaces :1.0/:1.1 of the same USB device. So a name check scoped to
#     the battery's own HID device finds nothing and rejects the real mouse.
#     _device_name therefore widens to the whole USB device, but only AFTER the
#     precise scope comes up empty: a receiver's USB device is shared with
#     every other paired device, so widening first would let a HID++ keyboard's
#     name qualify the mouse's battery.
#
#   * "online" is 0 for the sleeping receiver link, which is right, and would
#     be the only surviving candidate if the wired one were rejected above.
#
# When both entries are live (the link stays up while charging on some models)
# they disagree: one reports the stale wireless reading, the other the charger.
# _rank prefers the plugged one, so the pick is deterministic rather than
# whatever the glob happened to enumerate first.

# Overridable ONLY so the arms that need a cable, a flat battery or a sleeping
# link can be exercised against a synthetic tree -- there is no way to reach
# them on demand otherwise, and this file is shared across machines.
PS_ROOT=${MOUSEBAT_SYSFS:-/sys/class/power_supply}

# WRITTEN AS \u ESCAPES, NEVER AS LITERAL GLYPHS.  These are Private Use Area
# codepoints: they carry no meaning to anything that is not a Nerd Font, they
# look like a blank in every editor, diff and terminal that lacks one, and they
# are silently dropped by tools that filter or re-encode text.  That is not
# hypothetical -- the bolt below was ALREADY an empty string in this file
# before it was written this way, so the charging icon had never once rendered,
# and the failure is invisible: an empty icon just looks like the trailing
# space it leaves behind.  An escape is ASCII, survives anything, and says
# which codepoint it is without needing the font installed to read it.
ICON_MOUSE=$'\uefba'   # nf-fa-computer_mouse
ICON_BOLT=$'\uf0e7'    # nf-fa-bolt      -- charging
ICON_PLUG=$'\uf1e6'    # nf-fa-plug      -- plugged, not charging / full

emit_hidden() {
    printf '{"text":"","tooltip":"%s","class":"hidden"}\n' "$1"
    exit 0
}

# The device KIND is never in model_name -- that is the wireless LINK name
# ("PRO 2 LIGHTSPEED"). It only appears on an input node's name ("Logitech
# PRO 2 MOUSE"), which is where upower gets its model from too, or failing
# that on the USB device's own product string.
_device_name() {
    local hid=$1 inp usb name

    # 1. Input nodes under this battery's own HID device. Precise: on a
    #    receiver this is the per-paired-device node, so it cannot name a
    #    sibling. Recursive because the node is one level down, and skipping
    #    empties because the LED subnodes (input39::numlock, ...) have none.
    while IFS= read -r inp; do
        name=$(< "$inp") && [[ -n $name ]] && { printf '%s\n' "$name"; return; }
    done < <(find "$hid" -maxdepth 3 -path '*/input/input*/name' -print 2>/dev/null | sort)

    # 2. Nothing there => the HID++ vendor interface, i.e. the wired case,
    #    where the USB device IS the mouse and its other interfaces carry the
    #    input nodes.  REFUSED for a receiver-paired device even though it too
    #    can lack an input node: a receiver's USB device is shared with every
    #    other paired device, so this would answer "mouse" for the KEYBOARD's
    #    battery whenever both are on one dongle.  Unnameable is unnameable.
    [[ $(basename "$(dirname "$hid")") == 0003:* ]] && return

    usb=$hid
    while [[ $usb != / && ! -e $usb/idVendor ]]; do usb=$(dirname "$usb"); done
    [[ -e $usb/idVendor ]] || return

    while IFS= read -r inp; do
        name=$(< "$inp") && [[ -n $name ]] && { printf '%s\n' "$name"; return; }
    done < <(find "$usb" -maxdepth 5 -path '*/input/input*/name' -print 2>/dev/null | sort)

    # 3. Last resort: the USB product string ("PRO 2 MOUSE").
    [[ -r $usb/product ]] && < "$usb/product"
}

# Charging / Full / Not charging all mean A CABLE IS IN. "Not charging" is a
# plugged mouse holding its charge, not a fault, and treating it as
# discharging is how a full mouse on the cable shows up amber at 30%.
_plugged() {
    case $1 in Charging|Full|"Not charging") return 0 ;; *) return 1 ;; esac
}

# Higher wins. A plugged reading beats the link's stale one; a known status
# beats Unknown.
_rank() {
    _plugged "$1" && { echo 3; return; }
    [[ $1 == Discharging ]] && { echo 2; return; }
    echo 1
}

best_rank=0 best_pct= best_status= best_name= best_wired=

for bat in "$PS_ROOT"/hidpp_battery_*; do
    [[ -r "$bat/capacity" ]] || continue

    status=$(< "$bat/status")

    # `online` is 0 while the device is asleep/off; its capacity is then stale.
    # A plugged device is present by definition, so it is not gated on this --
    # only the wireless link is.
    if ! _plugged "$status"; then
        [[ -r "$bat/online" && "$(< "$bat/online")" == "0" ]] && continue
    fi

    hid=$(readlink -f "$bat")/../..
    name=$(_device_name "$(readlink -f "$hid")")
    [[ "${name,,}" == *mouse* ]] || continue

    rank=$(_rank "$status")
    (( rank > best_rank )) || continue

    best_rank=$rank
    best_pct=$(< "$bat/capacity")
    best_status=$status
    best_name=$name
    # A receiver-paired device is a HID node nested inside the RECEIVER's HID
    # node; a wired one hangs straight off its USB interface.
    best_wired=yes
    [[ $(basename "$(dirname "$(readlink -f "$hid")")") == 0003:* ]] && best_wired=no
done

(( best_rank > 0 )) || emit_hidden "No Logitech HID++ mouse connected"

case $best_status in
    Charging)      icon=$ICON_BOLT;  class="charging" ;;
    Full|"Not charging")
                   icon=$ICON_PLUG;  class="charging" ;;
    *)             icon=$ICON_MOUSE
                   if   (( best_pct <= 15 )); then class="critical"
                   elif (( best_pct <= 30 )); then class="warning"
                   else                            class="ok"
                   fi ;;
esac

link=wireless; [[ $best_wired == yes ]] && link="wired"
printf '{"text":"%s%% %s","tooltip":"%s — %s%%, %s (%s)","class":"%s"}\n' \
    "$best_pct" "$icon" "${best_name:-Mouse}" "$best_pct" "${best_status,,}" \
    "$link" "$class"
