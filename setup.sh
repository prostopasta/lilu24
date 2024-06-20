#!/usr/bin/env bash

if ! [ "$(id -u)" = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

if [ "$SUDO_USER" ]; then
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

cat >> /root/.bashrc <<\EOF
PS1='${debian_chroot:+($debian_chroot)}\[\e[0;91m\]\u@\h \W\\$ \[\e[0m\]'
#PS1='${debian_chroot:+($debian_chroot)}\[\e[0;91m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen

cat > /etc/profile.d/0.editor.sh << EOF
export EDITOR=vim
EOF

cat >> /etc/inputrc << EOF
set enable-bracketed-paste off
EOF

cat > /etc/default/keyboard <<\EOF
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

apt-get install -y flatpak
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
  font-manager kitty kcolorchooser vlc ark featherpad git

apt purge -y okular okular-extra-backends apparmor ifupdown resolvconf \
  geoclue-2.0 modemmanager xfwm4 xfwm4-theme-breeze obconf connman cmst \
  xscreensaver gnome-keyring gnome-power-manager gnome-session-bin \
  smplayer
apt -y autoremove
apt-get clean all

mkdir /opt/desktop_scripts
curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/screenshot.sh > /opt/desktop_scripts/screenshot.sh
curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/brightness.sh > /opt/desktop_scripts/brightness.sh
chmod +x /opt/desktop_scripts/*.sh

echo "user ALL = NOPASSWD: /opt/desktop_scripts/brightness.sh" | tee /etc/sudoers.d/brightness

cat > /etc/NetworkManager/NetworkManager.conf <<\EOF
[main]
plugins=ifupdown,keyfile
dns=none

[ifupdown]
managed=false

[device]
wifi.scan-rand-mac-address=no

[keyfile]
unmanaged-devices=*,except:type:ethernet,except:type:wifi,except:type:gsm,except:type:cdma,interface-name:lxc*,interface-name:docker*,interface-name:virtual*,interface-name:veth*
EOF

echo "nameserver 127.0.0.1" > /etc/resolv.conf

systemctl disable systemd-networkd.socket
systemctl disable systemd-networkd.service
systemctl disable systemd-resolved.service
systemctl disable avahi-daemon.service
systemctl disable avahi-daemon.socket

# Настройка dnsmasq
cat > /etc/dnsmasq.conf <<\EOF
port=53
#listen-address=0.0.0.0
no-dhcp-interface=
bind-interfaces
expand-hosts
local-ttl=1
no-negcache

# Динамические настройки DNS
resolv-file=/run/NetworkManager/resolv.conf

# Настройки DNS по умолчанию
#resolv-file=/etc/resolv.dnsmasq

conf-dir=/etc/dnsmasq.d
cache-size=150
max-cache-ttl=600
min-cache-ttl=60

# Одновременный запрос ко всем DNS серверам
# all-servers

# Запрещаем резолвить домены без точки (нужно для Docker Swarm)
domain-needed

# Для отладки
#log-queries
EOF

sed -i 's/#IGNORE_RESOLVCONF=yes/IGNORE_RESOLVCONF=yes/g' /etc/default/dnsmasq

# Выключаем резолвер из внешней сети интернет
cat > /etc/dnsmasq.d/disable-external-network <<\EOF
bind-interfaces
except-interface=eth*
except-interface=enp*
except-interface=wlan*
except-interface=wlp*
EOF

# Рестарт dnsmasq при включении/отключении сети
cat > /etc/dnsmasq.d/disable-external-network <<\EOF
#!/bin/bash

if [[ "$2" = "up" || "$2" = "down" ]]; then
    kill -9 `cat /var/run/dnsmasq/dnsmasq.pid`
    sleep 2
    systemctl start dnsmasq
fi
EOF

# Настройка синхронизации времени
mv -f /etc/openntpd/ntpd.conf /etc/openntpd/ntpd.orig.conf
echo "servers pool.ntp.org" > /etc/openntpd/ntpd.conf

# Установим BFQ
# BFQ это диспетчер I/O. Это улучшенная версия, которая позволяет ускорить работу с системой
echo 'bfq' >> /etc/initramfs-tools/modules
echo 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*", ATTR{queue/scheduler}="bfq"' >> /etc/udev/rules.d/60-scheduler.rules
update-initramfs -u

# Настройка GRUB
sed -i.bak 's/^.\?GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/g' /etc/default/grub
sed -i 's/^.\?GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/g' /etc/default/grub
sed -i 's/^.\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/g' /etc/default/grub
sed -i 's/^.\?GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="LiveUSB Lubuntu 24"/g' /etc/default/grub
sed -i 's/^.\?GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="splash quiet acpi_backlight=none scsi_mod.use_blk_mq=1"/g' /etc/default/grub
update-grub

# Настройка iptables
cat > /etc/iptables/rules.v4 <<\EOF
*filter
:INPUT ACCEPT [19:913]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [39:3584]
:ALLOW-INPUT - [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT

# Разрешаем входящие соединения ssh
#-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT

# Разрешить http
#-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
#-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# Перейти к цепочке ALLOW-INPUT
-A INPUT -j ALLOW-INPUT

# Запрещаем остальные входящие соединения
-A INPUT -j REJECT
-A FORWARD -j REJECT

-A ALLOW-INPUT -j RETURN

COMMIT
EOF

# Скопируем rules.v4 в rules.v6
cp -f /etc/iptables/rules.v4 /etc/iptables/rules.v6

# 2. Выполнять из-под пользователя

sudo -u "$real_user" ./user_setup.sh
