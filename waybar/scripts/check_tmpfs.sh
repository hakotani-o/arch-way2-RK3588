#!/bin/bash

# tmpfsかつホームディレクトリ配下のものに絞り込み、最初の1行だけを取得
MOUNT_NAME=$(mount | grep 'tmpfs' | grep "$HOME" | awk '{ print $3 }' | head -n 1)

# 変数を「"」で囲むことで、空のときや複数判定時のエラーを防ぎます
if [ -n "$MOUNT_NAME" ] && [ -d "$MOUNT_NAME" ]; then
    DIR_NAME=$(basename "$MOUNT_NAME")
    echo "{\"text\":\"🛠 $DIR_NAME\",\"class\": \"mounted\"}"
else
    echo "{\"text\":\"\", \"class\": \"unmounted\"}"
fi

