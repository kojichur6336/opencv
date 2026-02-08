#!/bin/bash

# --- 增加环境判断逻辑：如果是 GitHub Actions 则跳过 ---
if [ "$GITHUB_ACTIONS" == "true" ]; then
    echo "检测到 GitHub Actions 环境，正在跳过安装步骤..."
    exit 0
fi
# ----------------------------------------------

REMOTE_HOST=root@localhost
REMOTE_PATH=/tmp
DEB_NAME=com.sky.ykpro.deb
DEB_FILE=../Build/Packages/$DEB_NAME
PASSWORD=alpine

copy_deb() {
    #echo "拷贝deb文件到手机"
    sshpass -p $PASSWORD scp "$DEB_FILE" "$REMOTE_HOST:$REMOTE_PATH"
    #echo "deb文件已成功拷贝到手机Tmp目录"
}

install_deb() {
    local command_to_execute="dpkg -i $DEB_NAME"
    sshpass -p $PASSWORD ssh "$REMOTE_HOST" "cd $REMOTE_PATH && $command_to_execute"
    #echo "deb安装完成"
}

# 调用拷贝函数
copy_deb

# 调用安装函数
install_deb
