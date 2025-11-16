#!/bin/bash

brightnessctl set $1

brightness=$(brightnessctl g | awk '{print int($1 / 255 * 100)}')

dunstify --urgency low --hints string:x-dunst-stack-tag:brightness --hints int:value:$brightness "Set Brightness to $brightness%" --icon=brightness-low --timeout 2000

