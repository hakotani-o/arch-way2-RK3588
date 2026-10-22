#!/bin/bash
set -eE



# コンテナの初期設定（root権限で実行）
pacman-key --init
cp -a keyrings /usr/share/pacman 2>/dev/null || true
pacman-key --populate archlinuxarm
pacman -Syyu --noconfirm

# 必要なパッケージのインストール
pacman -S --noconfirm --need base-devel pacman-contrib wget git devtools cairo pango librsvg gtk4 seatd wlroots0.20

# ビルド用一般ユーザー「builder」の作成とsudo権限付与
useradd -m -G wheel builder

mkdir -p /etc/sudoers.d
echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chmod 0440 /etc/sudoers.d/builder


# 💡【ここを追加】/etc/gitconfig の権限エラーを根本解決する
# もしファイルがなければ空で作成し、すべてのユーザーが読み込める権限（644）を与えます
touch /etc/gitconfig
chmod 644 /etc/gitconfig
# /etc自体のパーミッションも、一般ユーザーが読み込める状態（755）か確認・修正
chmod 755 /etc

# 作業ディレクトリを /home/builder 内に作成し、所有権を builder に変更
chown -R builder:builder /home/builder

# === ここから一般ユーザー「builder」として実行 ===
sudo -u builder bash  << 'EOF_'
set -eE
set -x


cd /home/builder/
mkdir ~/.gnupg
echo "keyserver-options auto-key-retrieve" > .gnupg/gpg.conf
# 必要なフォルダだけをプル
git clone https://aur.archlinux.org/waybox.git
#git clone https://github.com/wizbright/waybox.git

cd waybox
echo "------------- packaging/packages/waybox ------------------"
ls -la
echo "---------------------------------------------------"

cp PKGBUILD PKGBUILD.org


SED_FLAGS='   export V=1\n  export RUSTFLAGS="-C opt-level=2 -C target-cpu=cortex-a76" \n export CFLAGS="-O2 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -pipe -fno-plt "\n  export CXXFLAGS="${CFLAGS}"\n'
# ※ 警告を回避し、dotprod（AI/ベクトル演算）などの機能をフル有効化
sed -i "s/arch=(x86_64)/arch=(aarch64)\nepoch=10/" PKGBUILD
sed -i "s/arch=('x86_64')/arch=('aarch64')\nepoch=10/" PKGBUILD
sed -i 's/arch=("x86_64")/arch=("aarch64")\nepoch=10/' PKGBUILD
sed -i "/epoch=10/a \\${SED_FLAGS}" PKGBUILD

sed -i "s/'libwlroots-0.18.so' //" PKGBUILD


sed -i 's|^source=("git+https://github.com/wizbright/${pkgname}.git#commit=b2e686171f3b5874f30cc19495416de81482a0e9")|source=("git+https://github.com/TheCleaners/waybox.git")|' PKGBUILD
# updpkgsums --nocheck
updpkgsums

MAKEFLAGS="-j$(nproc)" makepkg -srf --noconfirm --skippgpcheck 2>&1|tee ~/arch-waybox.txt

EOF_
# === 一般ユーザーでの実行ここまで ===

# 出来上がったパッケージをコンテナのルート「/」に配置
sudo cp /home/builder/waybox/*aarch64.pkg.tar.* /MY-rockchip
sudo cp /home/builder/arch-waybox.txt /
