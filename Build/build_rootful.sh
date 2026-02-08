#!/bin/bash

# 如果第一个参数不是 "-d"、"-r"，则提示选择 debug 还是 release，并退出脚本
if [ "$1" != "-d" -a "$1" != "-r" ]; then
    # 检查第一个参数是否为 "-d" 或 "-r"，如果不是，则输出提示信息并退出脚本
    echo "请输入-d(debug) 或者 -r(release)?"
    exit 0
else
    # 如果第一个参数是 "-d" 或 "-r"，则执行以下操作
    if   [ "$1" = "-d" ]; then
        # 如果第一个参数是 "-d"，则将配置设置为 "Debug-iphoneos"
        configuration="Debug-iphoneos"
    elif [ "$1" = "-r" ]; then
        # 如果第一个参数是 "-r"，则将配置设置为 "Release-iphoneos"
        configuration="Release-iphoneos"
    fi
fi

function Clean_DS_Store()
{
    for file in `ls -a $1`
    do
        if [ x"$file" != x"." -a x"$file" != x".." ]; then
            if [ $file = ".DS_Store" ]; then
                echo "remove .DS_Store: $1/$file"
                rm "$1/$file"
            fi

            if [ -d "$1/$file" ]; then
                Clean_DS_Store "$1/$file"
            fi
        fi
    done
}


# 检查是否传入版本号参数
if [ -z "$2" ]; then
    echo "请输入版本号。例如: ./script.sh -r 1.0.0"
    exit 0
else
    # 定义软件包的版本号
    VER="$2"
fi

# 定义软件包的渠道
CHANNELS=(
default
)

# 定义软件包的唯一标识符或包名
PackageName="com.sky.ykpro"

# 定义软件包的显示名称或描述
PackageDisplayName="远控Pro"

# 定义软件包描述
PackageDepiction="远程控制手机"

# 定义企业名称
PackageAuthor="YKP"

# 定义软件包替代的其他软件包
REPLACES=""

# 定义软件包与其他软件包冲突的列表
CONFLICTS=""


echo "制作中..."

# 切换到脚本所在目录
cd `dirname $0`

# 输出提示信息，表示正在删除旧的 Layout 目录
echo "删除旧Layout..."
rm -rf     Layout
echo "删除成功Layout..."


echo "制作新的文件夹..."
# 创建 Layout 目录，作为软件包文件结构的主目录
mkdir     Layout
# 创建 Applications 目录，用于存放应用程序文件
mkdir    Layout/Applications
# 创建 Library 目录，用于存放库文件
mkdir    Layout/Library
# 创建 MobileSubstrate 目录，用于存放移动基板相关文件
mkdir    Layout/Library/MobileSubstrate
# 创建 DynamicLibraries 目录，用于存放动态库文件
mkdir    Layout/Library/MobileSubstrate/DynamicLibraries
# 创建 LaunchDaemons 目录，用于存放启动守护程序文件
mkdir    Layout/Library/LaunchDaemons
# 创建 DEBIAN 目录，用于存放软件包的控制文件
mkdir    Layout/DEBIAN
# 创建 Packages 目录，用于存放生成的软件包
if [ ! -d "Packages" ]; then
    mkdir Packages
fi
# 创建 bz2 目录，用于存放生成的压缩软件包
if [ ! -d "Packages/bz2" ]; then
    mkdir Packages/bz2
fi
echo "制作新的文件夹成功..."

echo "拷贝文件..."
cp -rf    Products/YKApp.app                               Layout/Applications/YKApp.app
mkdir -p Layout/Applications/YKApp.app/bin

cp      Products/YKSBTweak.dylib                           Layout/Library/MobileSubstrate/DynamicLibraries/YKSBTweak.dylib
cp      ../YKSBTweak/YKSBTweak.plist                       Layout/Library/MobileSubstrate/DynamicLibraries/YKSBTweak.plist

cp      Products/YKUITweak.dylib                           Layout/Library/MobileSubstrate/DynamicLibraries/YKUITweak.dylib
cp      Plist/YKUITweak.plist                              Layout/Library/MobileSubstrate/DynamicLibraries/YKUITweak.plist

cp      Products/YKMediaserverdTweak.dylib                 Layout/Library/MobileSubstrate/DynamicLibraries/YKMediaserverdTweak.dylib
cp      Plist/YKMediaserverdTweak.plist                    Layout/Library/MobileSubstrate/DynamicLibraries/YKMediaserverdTweak.plist

cp      Products/YKLaunchd                                 Layout/Applications/YKApp.app/bin/YKLaunchd
cp      ../YKLaunchd/YKLaunchd.plist                       Layout/Library/LaunchDaemons/com.sky.yklaunchd.plist

cp      Products/YKService                                 Layout/Applications/YKApp.app/bin/YKService
echo "拷贝文件完成..."


echo "ldid 签名..."
ldid -S                                                    Layout/Library/MobileSubstrate/DynamicLibraries/YKSBTweak.dylib
ldid -S                                                    Layout/Library/MobileSubstrate/DynamicLibraries/YKUITweak.dylib
ldid -S                                                    Layout/Library/MobileSubstrate/DynamicLibraries/YKMediaserverdTweak.dylib
ldid -SSignXml/YKApp.entitlements                          Layout/Applications/YKApp.app
ldid -SSignXml/YKLaunchd.entitlements                      Layout/Applications/YKApp.app/bin/YKLaunchd
ldid -SSignXml/YKService.entitlements                      Layout/Applications/YKApp.app/bin/YKService
echo "ldid 签名完成..."


echo "create files: control"
echo "Package: ${PackageName}
Name: ${PackageDisplayName}
Version: ${VER}
Icon: file:///Applications/YKApp.app/AppIcon60x60@2x.png
Description: ${PackageDepiction}
Depiction: ${PackageDepiction}
Section: Packaging
Depends: firmware (>= 13.0), mobilesubstrate
Conflicts:${CONFLICTS}
Replaces: ${REPLACES}
Architecture: iphoneos-arm
Author: ${PackageAuthor}
Maintainer: YKP" > Layout/DEBIAN/control



# preinst 在软件包被安装之前执行。用于在安装软件包之前执行一些准备工作。例如，创建所需的目录结构，检查系统依赖项，设置权限等
echo "create files: preinst"
echo "#!/bin/bash
echo 'preinst'
echo 'Clean old files...'
killall -9 pasted >/dev/null 2>&1 || true
killall -9 YKApp >/dev/null 2>&1 || true
killall -9 YKService >/dev/null 2>&1 || true
rm -rf /Applications/YKApp.app
rm -rf /Library/LaunchDaemons/com.sky.yklaunchd.plist
exit 0" > Layout/DEBIAN/preinst


# prerm 在软件包被移除之前执行。通常用于在卸载软件包之前执行一些清理操作或准备工作。例如，停止相关的服务或进程，备份或清理配置文件等
echo "create files: prerm"
echo "#!/bin/bash
echo 'prerm'
echo 'Clean old files...'
if launchctl list | grep -q com.sky.yklaunchd; then
    launchctl stop com.sky.yklaunchd
    launchctl unload /Library/LaunchDaemons/com.sky.yklaunchd.plist
fi

killall -9 pasted >/dev/null 2>&1 || true
killall -9 YKApp >/dev/null 2>&1 || true
killall -9 YKService >/dev/null 2>&1 || true
exit 0" > Layout/DEBIAN/prerm


# postrm 在软件包被移除之后执行。用于在卸载软件包之后执行一些清理操作或收尾工作。例如，删除残留文件，停止相关的服务或进程，更新系统配置等
echo "create files: postrm"
echo "#!/bin/bash

echo 'postrm'

killall -9 pasted >/dev/null 2>&1 || true
killall -9 YKApp >/dev/null 2>&1 || true
killall -9 YKService >/dev/null 2>&1 || true

echo \$1
if [[ \$1 == remove ]]; then
    su -c /usr/bin/uicache mobile

    declare -a cydia
    cydia=(\$CYDIA)
    if [[ \${CYDIA+@} ]]; then
        eval "\""echo 'finish:reload' >&\${cydia[0]}"\""
    else
        killall -9 SpringBoard
        echo "\""remove finish! reload SpringBoard..."\""
    fi
fi

exit 0" > Layout/DEBIAN/postrm


# postinst
echo "create files: postinst"
echo "#!/bin/bash

echo 'postinst'


# 创建基础目录
if [ ! -d "/var/mobile/Library/YKApp" ]; then
    mkdir /var/mobile/Library/YKApp
fi


# 如果 LockFile 是一个文件（不是目录），先删掉它
if [ -f \"/var/mobile/Library/YKApp/LockFile\" ]; then
    rm -f \"/var/mobile/Library/YKApp/LockFile\"
fi

# 创建LockFile目录
if [ ! -d "/var/mobile/Library/YKApp/LockFile" ]; then
    mkdir /var/mobile/Library/YKApp/LockFile
fi


# 创建Config目录
if [ ! -d "/var/mobile/Library/YKApp/Config" ]; then
    mkdir /var/mobile/Library/YKApp/Config
fi

# 创建Logs目录
if [ ! -d "/var/mobile/Library/YKApp/Logs" ]; then
    mkdir /var/mobile/Library/YKApp/Logs
fi

# 创建崩溃日志目录
if [ ! -d "/var/mobile/Library/YKApp/CrashLogs" ]; then
    mkdir /var/mobile/Library/YKApp/CrashLogs
fi

# 创建下载目录
if [ ! -d "/var/mobile/Library/YKApp/Downloads" ]; then
    mkdir /var/mobile/Library/YKApp/Downloads
    mkdir /var/mobile/Library/YKApp/Downloads/Tmp
    mkdir /var/mobile/Library/YKApp/Downloads/Deb
    mkdir /var/mobile/Library/YKApp/Downloads/Ipa
fi


# 设置 App 所属权限
chown -R root:wheel             /Applications/YKApp.app
chown -R mobile:mobile          /var/mobile/Library/
chmod -R 755                    /var/mobile/Library/YKApp

# App 二进制目录权限
chmod 755                       /Applications/YKApp.app/bin
chmod u+s                       /Applications/YKApp.app/bin/YKService

# LaunchDaemon 配置
chmod 644                       /Library/LaunchDaemons/com.sky.yklaunchd.plist
chown root:wheel                /Library/LaunchDaemons/com.sky.yklaunchd.plist



killall -9 YKApp >/dev/null 2>&1 || true
killall -9 YKService >/dev/null 2>&1 || true

su -c /usr/bin/uicache mobile

declare -a cydia
cydia=(\$CYDIA)
if [[ \${CYDIA+@} ]]; then
    eval "\""echo 'finish:reload' >&\${cydia[0]}"\""
else
    killall -9 SpringBoard
    echo "\""install finish! reload SpringBoard..."\""
fi
launchctl load /Library/LaunchDaemons/com.sky.yklaunchd.plist
exit 0" > Layout/DEBIAN/postinst


chmod 755 Layout/DEBIAN/preinst
chmod 755 Layout/DEBIAN/postinst
chmod 755 Layout/DEBIAN/prerm
chmod 755 Layout/DEBIAN/postrm


# 制作debg包
echo "clean .DS_Store"
Clean_DS_Store Layout
for (( i = 0; i < ${#CHANNELS[@]}; i++ )); do
    #statements
    channel=${CHANNELS[i]}
    echo "channel: ${channel}"

    DEBNAME="com.sky.ykpro.deb"
    BZ2NAME="com.sky.ykpro_bz2"
    DEBPATH="Packages/${DEBNAME}"
    BZ2PATH="Packages/bz2/${BZ2NAME}"

    dpkg-deb -Zgzip -b Layout $DEBPATH

    #create bz2
    echo "create bz2 file..."

    DEBMD5=`md5 < $DEBPATH`
    DEBSHA256=`shasum -a 256 < $DEBPATH | awk '{print $1}'`
    DEBSIZE=`wc -c < $DEBPATH`

    echo "Package: ${PackageName}
Name: ${PackageDisplayName}
Version: ${VER}
Icon: file:///Applications/YKApp.app/AppIcon60x60@2x.png
Description: ${PackageDepiction}
Depiction: ${PackageDepiction}
Section: Packaging
Depends: firmware (>= 13.0), mobilesubstrate
Conflicts:${CONFLICTS}
Replaces: ${REPLACES}
Architecture: iphoneos-arm
Author: ${PackageAuthor}
Maintainer: CYJH
MD5sum: ${DEBMD5}
SHA256: ${DEBSHA256}
Size: ${DEBSIZE}
Filename: debs/${DEBNAME}" > $BZ2PATH
done

echo "制作完成"



