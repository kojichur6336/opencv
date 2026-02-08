require 'xcodeproj'

# 构建ollvm
def build_ollvm(project_path:, target_name:, files_to_modify:, compiler_flags:, build:)
  # 打开 Xcode 项目
  project = Xcodeproj::Project.open(project_path)

  # 获取目标（Target），确保目标名称与实际目标名称一致
  target = project.targets.find { |t| t.name == target_name }

  # 如果找不到目标，打印错误信息并退出
  unless target
    puts "未找到目标：#{target_name} (项目: #{project_path})"
    return
  end

  # 获取 "Compile Sources" 构建阶段
  compile_sources = target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }

  # 如果没有找到 "Compile Sources" 构建阶段，打印错误信息并退出
  unless compile_sources
    puts "未找到 'Compile Sources' 构建阶段 (项目: #{project_path})"
    return
  end

  # 找到要修改的 .m 文件
  files_to_modify = compile_sources.files.select { |file| files_to_modify.include?(file.display_name) }
  
  # 为指定的文件添加编译器标志
  if files_to_modify.any?
    files_to_modify.each do |file_to_modify|
      file_to_modify.settings ||= {}
      flags = file_to_modify.settings['COMPILER_FLAGS']
      flags ||= ""
      puts "获取到当前的编译：#{flags}"
      # 先移除
      flags = flags.gsub(/#{Regexp.escape(compiler_flags)}\s*/, '').strip
      puts "移除后的编译：#{flags}"
      # 设置编译器标志
      if build == "-d"
         # 后添加
         flags = "#{flags} #{compiler_flags}"
         file_to_modify.settings['COMPILER_FLAGS'] = flags
         else
             if flags == ""
                 file_to_modify.settings = nil
            else
                file_to_modify.settings['COMPILER_FLAGS'] = flags
            end
      end
      puts "为 #{file_to_modify.display_name} 添加了编译器标志 (项目: #{project_path})"
    end
  else
    puts "未找到指定的文件：#{files_to_modify.join(', ')} (项目: #{project_path})"
  end

  # 保存项目
  project.save
  puts "编译器标志添加成功 (项目: #{project_path})"
end


# YKApp的加密
def build_App(build:)
    build_ollvm(
      project_path: '../YKApp/YKApp.xcodeproj',
      target_name: 'YKApp',
      files_to_modify: ['YKAppController.m', 'YKAppIPCController.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end


# YKMediaserverdTweak
def build_YKMediaserverdTweak(build:)
    build_ollvm(
      project_path: '../YKMediaserverdTweak/YKMediaserverdTweak.xcodeproj',
      target_name: 'YKMediaserverdTweak',
      files_to_modify: ['YKHookAudio.m', 'YKAudioCore.m', 'YKAudioSocket.m', 'YKAACEncoder.m', 'YKAudioDevice.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end


# YKUITweak
def build_YKUITweak(build:)
    build_ollvm(
      project_path: '../YKUITweak/YKUITweak.xcodeproj',
      target_name: 'YKUITweak',
      files_to_modify: ['YKHookPBAuditTokenInfo.m', 'YKHookTBD.m', 'YKHookSecureTextEntry.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end


# YKSBTweak
def build_YKSBTweak(build:)
    build_ollvm(
      project_path: '../YKSBTweak/YKSBTweak.xcodeproj',
      target_name: 'YKSBTweak',
      files_to_modify: ['YKCommand.m', 'YKHookSpringBoard.m', 'YKSBTweakController.m', 'YKSBIPCController.m', 'YKSBKeyBoardManager.m', 'YKSBAirPlayController.m', 'YKHookSBBannerManager.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end


# YKService
def build_YKService(build:)
    build_ollvm(
      project_path: '../YKService/YKService.xcodeproj',
      target_name: 'YKService',
      files_to_modify: ['YKOrientationObserver.m', 'YKKBDManager.m', 'YKServiceEncrypt.mm', 'YKAppSafeGuard.m', 'YKService.m', 'YKServiceIPCController.m', 'YKServiceVideoController.m', 'YKServiceScreenBufferController.m', 'YKPortScanWIFI.m', 'YKPortScanManager.m', 'YKClientSocket.m', 'YKServiceRemoteController.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end

# YKLaunchd
def build_YKLaunchd(build:)
    build_ollvm(
      project_path: '../YKLaunchd/YKLaunchd.xcodeproj',
      target_name: 'YKLaunchd',
      files_to_modify: ['YKShell.mm', 'YKLaunchd.m', 'YKLaunchdService.m'],
      compiler_flags: "-mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-subobf -mllvm -enable-indibran -mllvm -enable-strcry",
      build: build
    )
end



# 根据传入的参数调用不同的函数
if ARGV[0] == "modify"
    build_App(build: "-d")
    build_YKMediaserverdTweak(build: "-d")
    build_YKUITweak(build: "-d")
    build_YKSBTweak(build: "-d")
    build_YKService(build: "-d")
    build_YKLaunchd(build: "-d")
elsif ARGV[0] == "clean"
    build_App(build: "-f")
    build_YKMediaserverdTweak(build: "-f")
    build_YKUITweak(build: "-f")
    build_YKSBTweak(build: "-f")
    build_YKService(build: "-f")
    build_YKLaunchd(build: "-f")
end



