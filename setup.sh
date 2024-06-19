#!/usr/bin/env bash

if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

# Commands that you don't want running as root would be invoked
# with: sudo -u $real_user
# So they will be run as the user who invoked the sudo command
# Keep in mind if the user is using a root shell (they're logged in as root),
# then $real_user is actually root
# sudo -u $real_user non-root-command

# Commands that need to be ran with root would be invoked without sudo
# root-command

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

mkdir /opt/desktop_scripts
curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/screenshot.sh > /opt/desktop_scripts/screenshot.sh
curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/brightness.sh > /opt/desktop_scripts/brightness.sh

echo "user ALL = NOPASSWD: /opt/desktop_scripts/brightness.sh" | tee /etc/sudoers.d/brightness


# 2. Выполнять из-под пользователя

sudo -u $real_user ./user_setup.sh