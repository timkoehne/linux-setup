export EDITOR="/usr/bin/nvim"
export TERM="xterm-256color"
export TERMINAL="/usr/bin/kitty"
export BROWSER="/usr/bin/firefox"
export SUDO_ASKPASS="~/Dropbox/Scripts/rofipassword.sh"
export XDG_PICTURES_DIR="~/Pictures/"


output=$(pactl list short sources | grep -i "alsa_input.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00.analog-stereo-input")
if [ -n "$output" ]; then
	pactl set-source-volume alsa_input.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00.analog-stereo-input 200%
fi


if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi
