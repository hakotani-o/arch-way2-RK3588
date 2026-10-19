#!/bin/bash
# ※「hakotani」の部分をご自身のLinuxユーザー名に変更してください
USB_DIR="/run/media/$USER"

# マウントされているディレクトリがあるか確認
if [ -d "$USB_DIR" ] && [ "$(ls -A "$USB_DIR")" ]; then
    # 最初に見つかったマウント名を取得
    MOUNT_NAME=$(ls "$USB_DIR" | head -n 1)
    echo "{\"text\": \"$MOUNT_NAME\", \"class\": \"mounted\", \"tooltip\": \"USBマウント中: $MOUNT_NAME\"}"
else
    # 未マウント時は何も表示しない（または空アイコン）
    echo "{\"text\": \"\", \"class\": \"unmounted\"}"
fi
