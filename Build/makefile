# 在头部添加 MAKEFLAGS += -e
MAKEFLAGS += -e

# 定义变量来存储路径和命令
BUILD_PATH := ../Build

# 默认版本为空
VERSION := $(shell xcodebuild -project "../YKApp/YKApp.xcodeproj" -showBuildSettings | grep -m 1 "MARKETING_VERSION" | sed 's/MARKETING_VERSION = //')
# 定义变量来存储配置参数 (make mode=log1)
CONFIG := -log1
# 定义编译工具(默认为Xcode自带的Clang)
TOOLCHAINS := XcodeDefault

ifeq ($(mode), log0)
    CONFIG := -log0
	TOOLCHAINS := Hikari_LLVM19.0.0git
endif
ifeq ($(mode), log1)
    CONFIG := -log1
endif
ifeq ($(mode), log2)
    CONFIG := -log2
endif

# 执行命令的目标
run_command:
	@echo "运行命令。"
	(cd $(BUILD_PATH) && ./$(COMMAND))


# 执行 有根 workspace 构建
build_rootful_workspace:
	@echo "开始-有根-Workspace-构建"
	$(MAKE) run_command COMMAND="./build_workspace.sh -r -clean -hasroot $(CONFIG) $(TOOLCHAINS)"

# 执行有 有根 deb 构建
build_rootful_deb:
	@echo "开始-有根-deb-构建"
	$(MAKE) run_command COMMAND="./build_rootful.sh -r $(VERSION)"
	
	
# 执行 无根 workspace 构建
build_rootless_workspace:
	@echo "开始-无根-Workspace-构建"
	$(MAKE) run_command COMMAND="./build_workspace.sh -r -clean -rootless $(CONFIG) $(TOOLCHAINS)"
	
# 执行 无根 deb 构建
build_rootless_deb:
	@echo "开始-无根-deb-构建"
	$(MAKE) run_command COMMAND="./build_rootless.sh -r $(VERSION)"
	

# 执行 隐根 workspace 构建
build_roothide_workspace:
	@echo "开始-隐根-Workspace-构建"
	$(MAKE) run_command COMMAND="./build_workspace.sh -r -clean -roothide $(CONFIG) $(TOOLCHAINS)"
	

# 执行 隐根 deb 构建
build_roothide_deb:
	@echo "开始-隐根-deb-构建"
	$(MAKE) run_command COMMAND="./build_roothide.sh -r $(VERSION)"
	
	
# 执行安装deb的命令
install_deb:
	@echo "安装deb文件"
	(cd $(BUILD_PATH) && ./install_deb.sh)
	
	

# 告诉Makefile这不是一个文件目标
.PHONY: run_command build_rootful_workspace build_rootful_deb build_rootless_workspace build_rootless_deb  build_roothide_workspace build_roothide_deb install_deb

# 连接四个操作的目标，使用all构建有根
rootful: build_rootful_workspace build_rootful_deb install_deb
	@echo "构建、deb构建、安装到手机完成"

# 连接两个操作的目标，使用rootless
rootless: build_rootless_workspace build_rootless_deb install_deb
	@echo "构建、无根deb构建、安装到手机完成"
	
# 连接两个操作的目标，使用rootless
roothide: build_roothide_workspace build_roothide_deb install_deb
	@echo "构建、隐根deb构建、安装到手机完成"
