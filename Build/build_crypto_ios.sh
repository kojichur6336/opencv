#!/bin/bash
set -e

CRYPTOPP_VERSION=CRYPTOPP_8_9_0   # 可以换成你需要的版本
CRYPTOPP_DIR=cryptopp

# 1. 拉取源码
if [ ! -d "$CRYPTOPP_DIR" ]; then
    git clone -b $CRYPTOPP_VERSION https://github.com/weidai11/cryptopp.git
fi

cd $CRYPTOPP_DIR

# 2. 清理
make clean || true

# 3. 编译 iOS arm64
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_CC=$(xcrun --sdk iphoneos -f clang)
IOS_AR=$(xcrun --sdk iphoneos -f ar)

make -f GNUmakefile-cross \
    CROSS_COMPILE=arm-apple-darwin64- \
    CXX=$IOS_CC \
    AR=$IOS_AR \
    ARCH=arm64 \
    CXXFLAGS="-std=c++11 -arch arm64 -isysroot $IOS_SDK -stdlib=libc++" \
    libcryptopp.a

cd ..

# 4. 提取纯净的头文件
rm -rf build
mkdir -p build/include
mkdir -p build/ios-arm64

# 只复制 .h 头文件
find $CRYPTOPP_DIR -type f -name "*.h" -exec cp {} build/include/ \;

# 复制编译好的库
cp $CRYPTOPP_DIR/libcryptopp.a build/ios-arm64/

# 5. 生成 XCFramework
xcodebuild -create-xcframework \
    -library build/ios-arm64/libcryptopp.a \
    -headers build/include \
    -output build/CryptoPP.xcframework

echo "✅ 构建完成: build/CryptoPP.xcframework"

