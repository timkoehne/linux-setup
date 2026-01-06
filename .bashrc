shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend

[[ $- != *i* ]] && return

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

PS1="\[\033[38;5;10m\][\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;12m\]\w\[$(tput sgr0)\]\[\033[38;5;10m\]]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

alias yay="yay --color always"
alias rm='~/Dropbox/Scripts/saveRM'
alias ls='ls -hN --color=auto --group-directories-first'
alias grep='grep --colour=auto'
alias cp="cp -i"
alias df='df -h'
alias imageviewer="imv -d"
alias imv="imv -d"

alias yt='yt-dlp -o "~/Videos/%(uploader)s/%(title)s.%(ext)s"'
alias yta='yt-dlp -x --yes-playlist \
  --embed-thumbnail \
  --audio-format mp3 \
  -o "~/Music/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"'
alias ytp='yt-dlp -r 15M --write-thumbnail --yes-playlist \
  -o "~/Videos/%(playlist)s/%(playlist_index)02d - %(title)s.%(ext)s"'

# Usage: concatVideos video_file1 video_file2
concatVideos() {
  if [ -z "$1" ]; then
    echo "no files given"
  elif [ -z "$2" ]; then
    echo "no second file given"
  else
    ffmpeg -i "$1" -i "$2" -filter_complex "[0:v] [0:a] [1:v] [1:a] concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" output.mkv
  fi
}

# Convert video to gif file.
# Usage: video2gif video_file (scale) (fps)
# scale = 0 keeps the current scale
video2gif() {
  if [ -z "$1" ]; then
    echo "no filename given"
  elif [ -z "$2" ]; then
    echo "no scale given enter 0 to keep size"
  elif [ -z "$3" ]; then
    echo "no fps given"
  else
    ffmpeg -y -i "${1}" -vf fps=${3:-10},scale=${2:-320}:-1:flags=lanczos,palettegen "${1}.png"
    ffmpeg -i "${1}" -i "${1}.png" -filter_complex "fps=${3:-10},scale=${2:-320}:-1:flags=lanczos[x];[x][1:v]paletteuse" "${1}".gif
    rm "${1}.png"
  fi
}

# Usage: cutVideo video_file (start_time) (end_time)
# end_time can be omitted to cut to the end of the video
cutVideo() {
  if [ -z "$1" ]; then
    echo "no filename given"
  elif [ -z "$2" ]; then
    echo "no start time given"
  else
    if [ -z "$3" ]; then
      to=""
    else
      to="-to $3 "
    fi

    file="$1"
    file_type="${file#*.}"
    new_file_name="${file%.*}-cut.$file_type"
    ffmpeg -i "$1" -ss "$2" $to"$new_file_name"
  fi
}

qrcode() {
  if [ -z $1 ]; then
    echo "no text to encode"
  else
    tmpfile=$(mktemp --suffix=.png)
    echo "$@" | qrencode -s 22 -o "$tmpfile"
    imv "$tmpfile"
  fi
}

ex() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

tmux ls
source /opt/miniconda3/etc/profile.d/conda.sh
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# uv
export PATH="/home/tim/.local/bin:$PATH"

# QT platform for opencv2
export QT_QPA_PLATFORM=xcb
