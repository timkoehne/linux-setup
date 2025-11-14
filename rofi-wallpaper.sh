#!/bin/bash

WALLPAPER_DIRECTORY=~/Pictures/Wallpapers/
ROFI_THEME=~/Dropbox/Scripts/rofi-themes/solarized-image.rasi
THUMBNAIL_DIR=/tmp/Wallpapers_Thumbnails

mkdir -p "$THUMBNAIL_DIR"

FILE=$(find "$WALLPAPER_DIRECTORY" -type f | while read -r WALLPAPER; do
    THUMBNAIL="$THUMBNAIL_DIR/$(basename "$WALLPAPER").png"
    
    if [[ ! -f "$THUMBNAIL" ]]; then
        magick "$WALLPAPER" -resize 50x50 "$THUMBNAIL"
    fi
    
    echo -en "$(basename "$WALLPAPER")\0icon\x1fthumbnail://$THUMBNAIL\n"
done | rofi -i -p "Choose Wallpaper" -dmenu -show-icons -theme "$ROFI_THEME")

if [ -z "$FILE" ]; then
    echo "No wallpaper selected, exiting."
    exit 1
fi

SELECTED_WALLPAPER="$WALLPAPER_DIRECTORY$FILE"

hyprctl hyprpaper preload "$SELECTED_WALLPAPER"
hyprctl hyprpaper wallpaper ,"$SELECTED_WALLPAPER"

sleep 1

hyprctl hyprpaper unload unused

echo -e "preload = $SELECTED_WALLPAPER\nwallpaper = ,$SELECTED_WALLPAPER" > ~/.config/hypr/hyprpaper.conf

