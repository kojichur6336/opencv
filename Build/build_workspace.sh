#!/bin/bash

# 确保任何命令失败时脚本立即退出
set -e

# 切换当前工作目录为当前脚本所在目录
cd `dirname $0`

# 定义函数 CheckBuildResult 用于检查编译结果
function CheckBuildResult()
{

    res=$? # 获取上一个命令的执行结果
    if [ $res != 0 ]; then # 如果执行结果不为 0（即出现错误）
        echo -e "\033[31;1m ******************* BUILD FAILED $1 ******************* \033[0m"
        exit 1 # 退出脚本
    fi
}

# 定义函数 BuildWorkSpace 用于构建工作空间
function BuildWorkSpace()
{
    echo "building -configuration $1" # 打印正在构建的配置信息
    echo "输出 TOOLCHAINS: $5" # 打印正在构建的 TOOLCHAINS 值
    
    if [ "$2" == "-clean" ]; then # 如果第二个参数为 "-clean"

        echo "clean..." # 打印清理项目的消息
        
        # 分别对各个 scheme 进行清理，添加了 -sdk 和 -destination
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKApp -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKSBTweak -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKUITweak -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKMediaserverdTweak -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKService -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        xcodebuild clean -workspace ../YK.xcworkspace -scheme YKLaunchd -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS'
        
        
    else
        echo "no clean..." # 打印不清理项目的消息
    fi
 
    echo "删除旧包文件夹..Products"
    rm -rf Products
    
    echo "删除旧的符号表..dSYM"
    rm -rf DSYM
    
    echo "创建新的文件夹...Products"
    mkdir Products
    
    echo "创建新的文件夹...DSYM"
    mkdir DSYM
    
    #对ollvm进行构建
    if [ "$4" == "-log0" ]; then
        echo "开始构建ollvm"
        ruby build_ollvm.rb modify
    fi
    
    # 对App scheme 进行构建，增加了 -sdk 和跳过签名逻辑
    xcode_macro_ykApp='COCOAPODS=1 $(inherited)'
    new_macro_App="${xcode_macro_ykApp} ${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKApp -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_App" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKApp -configuration:$1"
    
    
    # 对SBTweak scheme 进行构建
    new_macro_SBTweak="${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKSBTweak -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_SBTweak" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKSBTweak -configuration:$1"
    
    # 对UITweak scheme 进行构建
    new_macro_UITweak="${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKUITweak -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_UITweak" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKUITweak -configuration:$1"
    
    # 对YKMediaserverdTweak scheme 进行构建
    new_macro_MediaserverdTweak="${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKMediaserverdTweak -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_MediaserverdTweak" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKMediaserverdTweak -configuration:$1"
            
    
    # 对YKService scheme 进行构建
    xcode_macro_ykservice='COCOAPODS=1 $(inherited)'
    new_macro_YKService="${xcode_macro_ykservice} ${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKService -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_YKService" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKService -configuration:$1"
    
    
    # 对YKLaunchd scheme 进行构建
    new_macro_YKLaunchd="${MACRO_DEFINITION}"
    TOOLCHAINS=$5 xcodebuild -workspace ../YK.xcworkspace -scheme YKLaunchd -configuration $1 GCC_PREPROCESSOR_DEFINITIONS="$new_macro_YKLaunchd" -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
    CheckBuildResult "-target:YKLaunchd -configuration:$1"
    
    
    # 获取构建完成后的配置信息，这里也需要指定 sdk 和 destination 才能准确获取路径
    mqapp_settings=$(xcodebuild -workspace ../YK.xcworkspace -scheme YKApp -configuration $1 -sdk iphoneos -destination 'generic/platform=iOS' -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | head -n 1)
    mqapp_build_dir=$(echo "$mqapp_settings" | grep "CONFIGURATION_BUILD_DIR" | awk -F" = " '{print $2}')
    # 打印路径
    echo $mqapp_build_dir
    
    app_path="$mqapp_build_dir/YKApp.app"
    target_dir="./Products"
    app_name=$(basename "$app_path")
    target_app="$target_dir/$app_name"
    
    #1.复制App
    cp -r "$app_path" "$target_dir/"
    # 2. 【关键】删除描述文件 (防止泄露 Team ID)
    rm -f "$target_app/embedded.mobileprovision"
    # 3. 【推荐】删除旧的签名文件夹 (彻底清除原有签名痕迹)
    rm -rf "$target_app/_CodeSignature"
    # 4. 【必须】删除 CodeResources (如果存在，它包含文件哈希)
    rm -f "$target_app/CodeResources"
    echo "✅ 已移除签名信息和描述文件"
    
    sbtweak_path="$mqapp_build_dir/libYKSBTweak.dylib"
    cp -r $sbtweak_path ./Products/YKSBTweak.dylib
    
    uitweak_path="$mqapp_build_dir/libYKUITweak.dylib"
    cp -r $uitweak_path ./Products/YKUITweak.dylib
    
    mediaTweak_path="$mqapp_build_dir/libYKMediaserverdTweak.dylib"
    cp -r $mediaTweak_path ./Products/YKMediaserverdTweak.dylib
    
    service_path="$mqapp_build_dir/YKService.app/YKService"
    cp -r $service_path ./Products/YKService
    
    
    launchd_path="$mqapp_build_dir/YKLaunchd.app/YKLaunchd"
    cp -r $launchd_path ./Products/YKLaunchd
    
    #对ollvm进行清理
    if [ "$4" == "-log0" ]; then
        echo "开始清除ollvm"
        ruby build_ollvm.rb clean
    fi
}


# 根据 类型变异 参数设置编译宏
if [ "$3" = "-rootful" ]; then
    MACRO_DEFINITION='ROOTFUL=1'
    echo "构建了有根"
elif [ "$3" = "-rootless" ]; then
    MACRO_DEFINITION='ROOTLESS=1'
    echo "构建了无根"
elif [ "$3" = "-roothide" ]; then
    MACRO_DEFINITION='ROOTHIDE=1'
    echo "构建了隐根"
fi

# 判断是否为 LOGI 模式，并根据情况设置为 1 或 2 或者3
if [ "$4" == "-log0" ]; then
    MACRO_DEFINITION="$MACRO_DEFINITION YKLogMode=0"
elif [ "$4" == "-log1" ]; then
    MACRO_DEFINITION="$MACRO_DEFINITION YKLogMode=1"
elif [ "$4" == "-log2" ]; then
    MACRO_DEFINITION="$MACRO_DEFINITION YKLogMode=2"
fi


# 如果第一个参数不是 "-d"、"-r" 或 "-a"，则提示选择 debug 还是 release，并退出脚本
if [ "$1" != "-d" -a "$1" != "-r" ]; then
    echo "debug or release?"
    exit 0
else
    if   [ "$1" = "-d" ]; then # 如果第一个参数为 "-d"，则构建 Debug 配置
        configuration="Debug-iphoneos"
        BuildWorkSpace "Debug" $2 $3 $4 $5
    elif [ "$1" = "-r" ]; then # 如果第一个参数为 "-r"，则构建 Release 配置
        configuration="Release-iphoneos"
        BuildWorkSpace "Release" $2 $3 $4 $5
    fi
fi
