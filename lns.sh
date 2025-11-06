ln -f -s ~/Dropbox/Scripts/linux-setup/.bashrc ~/.bashrc
ln -f -s ~/Dropbox/Scripts/linux-setup/.profile ~/.profile
ln -f -s ~/Dropbox/Scripts/linux-setup/dunst ~/.config/dunst
ln -f -s ~/Dropbox/Scripts/linux-setup/waybar ~/.config/waybar
[ -d "~/.config/hypr/" ] && mkdir ~/.config/hypr/
ln -f -s ~/Dropbox/Scripts/linux-setup/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
ln -f -s ~/Dropbox/Scripts/linux-setup/hypr/hypridle.conf ~/.config/hypr/hypridle.conf
ln -f -s ~/Dropbox/Scripts/linux-setup/hypr/hyprlock.conf ~/.config/hypr/hyprlock.conf
[ -d "~/.config/Code/" ] && mkdir ~/.config/Code/
[ -d "~/.config/Code/User/" ] && mkdir ~/.config/Code/User
ln -f -s ~/Dropbox/Scripts/linux-setup/VSCode/settings.json ~/.config/Code/User/settings.json
ln -f -s ~/Dropbox/Scripts/linux-setup/VSCode/keybindings.json ~/.config/Code/User/keybindings.json
