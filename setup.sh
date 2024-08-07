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

apt-get install -y flatpak gnome-software-plugin-flatpak
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
  font-manager kitty kcolorchooser vlc ark featherpad git seahorse wireguard

apt purge -y okular okular-extra-backends apparmor ifupdown resolvconf \
  geoclue-2.0 modemmanager xfwm4 xfwm4-theme-breeze obconf connman cmst \
  xscreensaver gnome-power-manager gnome-session-bin smplayer
apt -y autoremove
apt-get clean all

mkdir /opt/desktop_scripts
curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/screenshot.sh > /opt/desktop_scripts/screenshot.sh
#curl -L https://github.com/bayrell-os/desktop_scripts/raw/main/brightness.sh > /opt/desktop_scripts/brightness.sh
chmod +x /opt/desktop_scripts/*.sh

#echo "user ALL = NOPASSWD: /opt/desktop_scripts/brightness.sh" | tee /etc/sudoers.d/brightness

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

systemctl stop systemd-networkd.socket
systemctl disable systemd-networkd.socket
systemctl stop systemd-networkd.service
systemctl disable systemd-networkd.service
systemctl stop systemd-networkd.service
systemctl disable systemd-resolved.service
systemctl stop avahi-daemon.service
systemctl disable avahi-daemon.service
systemctl stop avahi-daemon.socket
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

sed -i.bak 's/^.\?IGNORE_RESOLVCONF=.*/IGNORE_RESOLVCONF=yes/g' /etc/default/dnsmasq

# Выключаем резолвер из внешней сети интернет
cat > /etc/dnsmasq.d/disable-external-network <<\EOF
bind-interfaces
except-interface=eth*
except-interface=enp*
except-interface=wlan*
except-interface=wlp*
except-interface=wg*
EOF

# Рестарт dnsmasq при включении/отключении сети
cat > /etc/NetworkManager/dispatcher.d/99-dnsmasq <<\EOF
#!/bin/bash

if [[ "$2" = "up" || "$2" = "down" ]]; then
    kill -9 `cat /var/run/dnsmasq/dnsmasq.pid`
    sleep 2
    systemctl start dnsmasq
fi
EOF

chmod u+x /etc/NetworkManager/dispatcher.d/99-dnsmasq

# Make sure Ethernet, Wifi, WireGuard all set as exception
cat > /etc/NetworkManager/NetworkManager.conf <<\EOF
[main]
plugins=ifupdown,keyfile
dns=none

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no

[keyfile]
unmanaged-devices=*,except:type:ethernet,except:type:wifi,except:type:gsm,except:type:cdma,except:type:wireguard,interface-name:lxc*,interface-name:docker*,interface-name:virtual*,interface-name:veth*
EOF

cat > /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf <<\EOF
[keyfile]
unmanaged-devices=*,except:type:wifi,except:type:gsm,except:type:cdma,except:type:ethernet,except:type:wireguard
EOF

# Настройка синхронизации времени
apt install -y systemd-timesyncd
timedatectl set-ntp true
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

# Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT

# Разрешаем входящие соединения ssh
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT

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

# Настройка udisks2
# udisks2 отвечает за подключение флешек и разных устройств.
# Рекомендуется добавить параметр sync для более корректной работы с USB устройствами
cat > /etc/udisks2/mount_options.conf <<\EOF
[defaults]
vfat_defaults=uid=$UID,gid=$GID,shortname=mixed,utf8=1,showexec,flush,sync
ntfs_defaults=uid=$UID,gid=$GID,windows_names,sync,relatime
ntfs:ntfs3_defaults=uid=$UID,gid=$GID,windows_names,sync,relatime
EOF

# Установка gnome screensaver
cat > /etc/xdg/autostart/lxqt-gnome-screensaver.desktop <<\EOF
[Desktop Entry]
Comment=Screensaver
Exec=gnome-screensaver
GenericName=GNOME Screensaver
Name=GNOME Screensaver
OnlyShowIn=LXQt;
TryExec=gnome-screensaver
Type=Application
EOF

# Установка picom
cat > /etc/xdg/autostart/lxqt-picom.desktop <<\EOF
[Desktop Entry]
Comment=A X compositor
#Exec=picom --backend glx --vsync
Exec=picom --backend
GenericName=X compositor
Name=Picom (X Compositor)
OnlyShowIn=LXQt;
TryExec=compton
Type=Application
EOF

# Настройка монитора
cat > /etc/xdg/autostart/lxqt-monitor.desktop << EOF
[Desktop Entry]
Comment=Monitor Settings
Exec=sh -c 'sleep 60 && xset dpms 200 200 200 && xset -dpms && xset s off && xset dpms 300 300 300'
GenericName=Monitor Always ON
Name=Monitor Always ON
OnlyShowIn=LXQt;
Type=Application
EOF

# Отключение автообновлений
sed -i.bak 's/^.\?APT\:\:Periodic\:\:Unattended-Upgrade.*/APT\:\:Periodic\:\:Unattended-Upgrade "0";/g' /etc/apt/apt.conf.d/20auto-upgrades
systemctl stop unattended-upgrades
systemctl disable unattended-upgrades

# Установим лимиты на размер journalctl и время ожидания запуска сервисов
echo "SystemMaxUse=128M" >> /etc/systemd/journald.conf
echo "DefaultTimeoutStartSec=60" >> /etc/systemd/system.conf
echo "DefaultTimeoutStopSec=30" >> /etc/systemd/system.conf

# Установим VSCode
apt install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
apt install -y apt-transport-https
apt update -y
apt install -y code

# 2. Выполнять из-под пользователя

sudo -u "$real_user" ./user_setup.sh
