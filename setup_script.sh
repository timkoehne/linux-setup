#!/bin/bash

folder_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# download submodule folder
git -C "$folder_path" submodule update --init --recursive

# softlink dotfiles
ln -f -s "$folder_path/.bashrc" ~/.bashrc
ln -f -s "$folder_path/.profile" ~/.profile

# softlink configs
mkdir -p ~/.config/dunst
ln -f -s "$folder_path/dunst/dunstrc" ~/.config/dunst/dunstrc

mkdir -p ~/.config/waybar
ln -f -s "$folder_path/waybar" ~/.config/waybar

mkdir -p ~/.config/hypr
ln -f -s "$folder_path/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf
ln -f -s "$folder_path/hypr/hypridle.conf" ~/.config/hypr/hypridle.conf
ln -f -s "$folder_path/hypr/hyprlock.conf" ~/.config/hypr/hyprlock.conf
echo "env = LINUX_SETUP,$folder_path" > ~/.config/hypr/envvars
touch ~/.config/hypr/monitors.conf
touch ~/.config/hypr/workspaces.conf

mkdir -p ~/.config/Code/User
ln -f -s "$folder_path/VSCode/settings.json" ~/.config/Code/User/settings.json
ln -f -s "$folder_path/VSCode/keybindings.json" ~/.config/Code/User/keybindings.json

mkdir -p ~/.config/discord
ln -f -s "$folder_path/Discord/settings.json" ~/.config/discord/settings.json
