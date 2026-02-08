Pod::Spec.new do |s|
  s.name             = 'YKLua'
  s.version          = '5.5.0' # 根据你的实际版本填写
  s.summary          = 'Lua Scripting Language'


  s.homepage         = 'https://github.com/YKP-com/YKLua'
  s.license          = { :type => 'MIT' }  # 不指定文件，避免找不到
  s.author           = { 'xiaobin liu' => 'liuxiaomike@gmail.com' }
  s.source           = { :git => 'https://github.com/YKP-com/YKLua.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'

  # --- 核心配置 ---

  # 1. 包含所有头文件和源文件
  s.source_files = 'src/*.{c,h}'

  # 2. 必须排除的文件！解决你之前的 duplicate symbol 错误
  s.exclude_files = [
    'src/lua.c',    # 包含 main 函数，是命令行工具入口
    'src/luac.c',   # 包含 main 函数，是编译器入口
    'src/onelua.c'  # 包含所有文件的 include，会导致重复符号
  ]

  # 3. 指定公开的头文件（供外部调用的）
  s.public_header_files = [
    'src/lua.h',
    'src/lualib.h',
    'src/lauxlib.h',
    'src/luaconf.h',
    'src/lua.hpp'
  ]

  # 4. 编译器设置
  s.pod_target_xcconfig = {
    # 隐藏符号，防止注入到 App 后与 App 自身的 Lua 冲突（越狱环境必做）
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'YES',
    # 允许在 iOS 上使用一些 POSIX 特性
    'GCC_PREPROCESSOR_DEFINITIONS' => 'LUA_COMPAT_5_3 LUA_USE_IOS'
  }

  # 如果你的项目需要作为 C++ 链接
  s.libraries = 'c++'
end