#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/Dropbox/Scripts/rofi-themes/solarized-image.rasi"
THUMBNAIL_DIR="/tmp/Wallpapers_Thumbnails"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

mkdir -p "$THUMBNAIL_DIR"

if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 1
fi

FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | \
    while read -r wallpaper; do
        filename=$(basename "$wallpaper")
        thumbnail="$THUMBNAIL_DIR/$filename.png"
        [[ ! -f "$thumbnail" ]] && magick "$wallpaper" -resize 100x100 "$thumbnail"
        echo -en "$filename\0icon\x1f$thumbnail\n"
    done | rofi -i -p "Choose Wallpaper" -dmenu -show-icons -theme "$ROFI_THEME")

[[ -z "$FILE" ]] && exit 0

SELECTED="$WALLPAPER_DIR/$FILE"

{
    echo "splash = false"
    echo "wallpaper {"
    echo "  monitor = "
    echo "  path = $SELECTED"
    echo "}"
} > "$HYPRPAPER_CONF"

hyprctl hyprpaper wallpaper ",$SELECTED,cover"