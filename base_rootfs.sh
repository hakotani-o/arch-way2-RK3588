#!/bin/bash
set -eE
set -x

kernel=$(uname -a|awk '{ print $2 }')

if [ $kernel != "archlinux" ]; then
sudo apt install -y arch-install-scripts archlinux-keyring pacman-package-manager systemd-container libalpm13t64 
# libalpm16
sudo pacman-key --init
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp  -a keyrings /usr/share/
sudo cp  etc/pacman.d/mirrorlist /etc/pacman.d
sudo cp etc/pacman.conf /etc
sudo pacman-key --populate archlinuxarm
else
sudo pacman -S --noconfirm arch-install-scripts
fi
sudo pacman -Syyu

sudo rm -rf base_camp && sudo mkdir base_camp
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        sudo mount -t tmpfs -o size=10G tmpfs base_camp
fi
sudo pacstrap ./base_camp base sudo arch-install-scripts archlinux-keyring
sudo cp waybox.sh ai-wayland.sh firstboot-growroot.sh MY.tar waybox-10:0.2.2-4-aarch64.pkg.tar.xz wlroots0.20-10:0.20.2-1-aarch64.pkg.tar.xz ./base_camp
sudo cp autostart  environment  menu.xml rc.xml ./base_camp
sudo cp -r waybar ./base_camp
sudo cp -a etc keyrings ./base_camp
sudo cp linux-aarch64-*-aarch64.pkg.tar.xz  u-boot-menu-4.2.4.tar.gz ./base_camp
sudo systemd-nspawn -D ./base_camp --resolv-conf=replace-host --as-pid2 /waybox.sh
cp base_camp/Arch-linux.rootfs.tar.gz .
cp base_camp/kernel_version .
if [ $mem_size -gt 13 ]; then
        sudo umount base_camp
        sleep 2
fi

