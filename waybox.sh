#!/bin/bash
set -eE

# xmllint --noout ~/.config/waybox/rc.xml

sudo pacman-key --init
sudo cp -a keyrings /usr/share/pacman
sudo pacman-key --populate archlinuxarm
sudo pacman -Syyu

sudo rm -rf ./mnt && sudo mkdir ./mnt
sudo pacstrap ./mnt base vim sudo 

# 📌 変更点: labwc を削除し、代わりに必要な依存（wlroots等）を網羅。
# waybar, lxqt等に必要なセッションツールは残しています。
sudo pacman -S --noconfirm --root ./mnt \
    sddm pcmanfm-qt qt6-wayland lxqt-wayland-session \
    swaylock swayidle waybar qterminal \
    networkmanager network-manager-applet ttf-dejavu noto-fonts-cjk \
    pipewire-pulse alsa-utils pavucontrol zenity cloud-guest-utils \
    e2fsprogs gvfs udisks2 clapper mpv vulkan-tools mesa-docs \
    mkinitcpio linux-firmware util-linux \
    lxqt-about lxqt-admin lxqt-config lxqt-notificationd \
    lxqt-policykit lxqt-runner lxqt-session lxqt-themes \
    xorg-xwayland libinput libxkbcommon pixman seatd \
    ttf-font-awesome otf-font-awesome ttf-nerd-fonts-symbols \
    adwaita-icon-theme hicolor-icon-theme woff2-font-awesome \
    adwaita-icon-theme-legacy breeze-icons elementary-icon-theme
 # 💡 wayboxの実行に必要な下位ライブラリを明記

#sudo tar xvf /MY.tar
#for i in `pacman -Q | awk '{ print $1 }'`
#do
#if [ -f MY-rockchip/\$i ]; then
#        sudo pacman -S --noconfirm --root ./mnt MY-rockchip/\$i
#fi
#done
yes | sudo pacman -U --root ./mnt /wlroots0.20-10:0.20.2-1-aarch64.pkg.tar.xz
yes | sudo pacman -U --root ./mnt /waybox-10:0.2.2-4-aarch64.pkg.tar.xz

# kernel (カスタムカーネルパッケージの流し込み)
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-*-aarch64.pkg.tar.*
yes | sudo pacman -U --root ./mnt /linux-aarch64-rockchip-headers-*-aarch64.pkg.tar.*

# u-boot-update
sudo tar zxvf /u-boot-menu-4.2.4.tar.gz -C ./mnt/
mkdir -p ./mnt/usr/share/u-boot-menu/conf.d
        cat << 'EOF' > ./mnt/usr/share/u-boot-menu/conf.d/archlinux.conf
        U_BOOT_UPDATE="true"
        U_BOOT_PROMPT="1"
        U_BOOT_PARAMETERS="\$(cat /etc/kernel/cmdline)"
        U_BOOT_TIMEOUT="20" 
EOF
echo "rootwait rw console=ttyS2,1500000 console=tty1" > ./mnt/etc/kernel/cmdline

echo "ELECTRON_OZONE_PLATFORM_HINT=wayland" >> ./mnt/etc/environment
echo "QT_QPA_PLATFORM=wayland" >> ./mnt/etc/environment
# 📌 変更点: デスクトップ環境のヒントを環境に合わせて Openbox（または空欄）等に調整
echo "XDG_CURRENT_DESKTOP=Waybox" >> ./mnt/etc/environment
echo "XDG_SESSION_TYPE=wayland" >> ./mnt/etc/environment

# 💡 waybox用のデスクトップエントリ（セッション用ファイル）を作成
# これにより SDDM などのディスプレイマネージャーの選択肢に Waybox が出現します。
sudo mkdir -p ./mnt/usr/share/wayland-sessions
cat << 'EOF' | sudo tee ./mnt/usr/share/wayland-sessions/waybox.desktop > /dev/null
[Desktop Entry]
Name=Waybox
Comment=An Openbox clone on Wayland
Exec=waybox
Type=Application
DesktopNames=Waybox
EOF

# 1. /etc/skel の中に Waybox の設定ディレクトリを構築
sudo mkdir -p ./mnt/etc/skel/.config/waybox
sudo cp /autostart  /environment  /menu.xml /rc.xml ./mnt/etc/skel/.config/waybox
sudo cp -r /waybar ./mnt/etc/skel/.config/
sudo chmod +x ./mnt/etc/skel/.config/waybox/autostart

sudo ./ai-wayland.sh
kernel_version=$( ls ./mnt/boot/vmlinuz*| sed 's/vmlinuz-/ /'| sed 's/-aarch64-rockchip//' | awk '{ print $2 }' )
echo "kernel_version=$kernel_version" > /kernel_version
# キャッシュクリア
yes | sudo pacman -Scc --root ./mnt 

# 📌 不要なセッションの非表示処理（labwcの非表示は不要になったため削除）
sudo sed -i '$a NoDisplay=true' ./mnt/usr/share/xsessions/lxqt.desktop
sudo sed -i '$a NoDisplay=true' ./mnt/usr/share/wayland-sessions/lxqt-wayland.desktop

cd mnt && sudo bsdtar -zcf /Arch-linux.rootfs.tar.gz --xattrs ./*
cd ..

