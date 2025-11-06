#!/bin/bash

wpctl set-volume @DEFAULT_AUDIO_SINK@ $1

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')

dunstify --urgency low --hints string:x-dunst-stack-tag:audio --hints int:value:$volume "Set Volume to $volume%" --icon=audio-volume-high

