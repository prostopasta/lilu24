#!/usr/bin/env bash

cat >> ~/.bashrc <<\EOF
source /etc/bash_completion.d/git-prompt
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00;32m\]`__git_ps1`\[\033[0m\]\n$ '
PROMPT_COMMAND='echo -n [$(date +%k:%M:%S)]\ '
EOF

cd /tmp
git clone https://github.com/prostopasta/dot-vim.git
cd dot-vim/ && bash install.sh

mkdir ~/.config/kitty
curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/kitty/kitty.conf > ~/.config/kitty/kitty.conf

mkdir ~/.config/openbox
curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/openbox/rc.xml > ~/.config/openbox/rc.xml

mkdir ~/.config/featherpad
curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/featherpad/fp.conf > ~/.config/featherpad/fp.conf

curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/picom.conf > ~/.config/picom.conf

curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/lxqt/panel.conf > ~/.config/lxqt/panel.conf

curl -L https://github.com/bayrell-os/lxqt_home/raw/main/src/.config/spectaclerc > ~/.config/spectaclerc
