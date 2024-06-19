#!/usr/bin/env bash
# 1. Выполнять из-под рута

sudo su

export DEBIAN_MIRROR="http://en.archive.ubuntu.com"
export DEBIAN_VERSION="noble"

cat > /etc/apt/sources.list.d/ubuntu-noble.list << EOF
deb $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION main universe restricted multiverse
deb-src $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION main universe restricted multiverse

deb $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-updates main universe restricted multiverse
deb-src $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-updates main universe restricted multiverse

deb $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-security main universe restricted multiverse
deb-src $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-security main universe restricted multiverse

deb $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-backports main universe restricted multiverse
deb-src $DEBIAN_MIRROR/ubuntu/ $DEBIAN_VERSION-backports main universe restricted multiverse
EOF

cat > /etc/profile.d/0.locale.sh << EOF
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
export LANG
export LANGUAGE
EOF

cat > /etc/profile.d/0.welcome.sh <<\EOF
HOSTNAME=`hostname`
if [[ `whoami` = "root" ]]; then
    HILIT="\e[0;91m"
else
    HILIT="\e[0;94m"
fi
PS1="\[${HILIT}\][\u@${HOSTNAME} \W]\\$ \[\e[0m\]"
export PS1
EOF

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen

cat > /etc/profile.d/0.editor.sh << EOF
export EDITOR=vim
EOF

cat >> /etc/inputrc << EOF
set enable-bracketed-paste off

cat >> /etc/default/keyboard <<\EOF
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="us,ru"
XKBVARIANT=""
XKBOPTIONS="grp:ctl_shift_toggle,grp_led:scroll"
BACKSPACE="guess"
EOF

cat > /etc/apt/sources.list.d/google-chrome.list << EOF
deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main
EOF

apt-get update
apt-get install -y google-chrome-stable 

apt-get install flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

apt install -y ubuntu-drivers-common
apt install -y nvidia-driver-550 linux-modules-nvidia-550-generic
echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia-drm-nomodeset.conf
update-initramfs -u

apt-get install -y bash-completion bsdmainutils psmisc uuid-runtime \
  htop mc nano curl pv dnsutils sudo man-db anacron iotop preload \
  git cmake g++ openssh-client wget unrar unar zip unzip p7zip-full \
  rar inxi attr libnotify-bin traceroute bridge-utils mtools xfsprogs \
  network-manager rsync dnsmasq python3-pynput network-manager-gnome \
  iptables-persistent net-tools dnsutils linux-base dbus grub-efi \
  grub-efi-amd64-bin grub-efi-ia32-bin grub-pc-bin openntpd python3-pip \
  libnss-nis libnss-nisplus whois flatpak picom xorg xterm xxkb xkbind \
  gxkb openbox sddm sddm-theme-maldives gnome-disk-utility smbclient \
  compton breeze breeze-gtk-theme kde-cli-tools kde-spectacle obconf-qt \
  scrot software-properties-gtk kcalc konsole dolphin dconf-editor \
  gnome-screensaver fonts-noto-core fonts-dejavu fonts-freefont-ttf \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-kde \
  font-manager kitty kcolorchooser vlc ark git
  
apt autoremove
apt-get clean all

logout

# 2. Выполнять из-под пользователя

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

sudo mkdir /opt/desktop_scripts
sudo curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/screenshot.sh > /opt/desktop_scripts/screenshot.sh
sudo curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/brightness.sh > /opt/desktop_scripts/brightness.sh

echo "user ALL = NOPASSWD: /opt/desktop_scripts/brightness.sh" | sudo tee /etc/sudoers.d/brightness
