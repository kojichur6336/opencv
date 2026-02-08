Pod::Spec.new do |s|
  s.name             = 'YKZipKit'
  s.version          = '1.0.0'
  s.summary          = 'A short description of YKZipRarKit.'
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  
  s.homepage         = 'https://github.com/YKP-com/YKZipKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaobin liu' => 'liuxiaomike@gmail.com' }
  s.source           = { :git => 'https://github.com/YKP-com/YKZipKit.git', :tag => s.version.to_s }
  
  s.static_framework = true
  s.requires_arc = false
  s.ios.deployment_target = '10.0'
  s.source_files = 'YKZipKit/Classes/**/*'
  
  # 指定公开头文件（如果有的话）
  s.public_header_files = [
     'YKZipKit/Classes/Core/*.h',
     'YKZipKit/Classes/SSZipArchive/*.h',
  ]
  
  # 指定私有头文件
   s.private_header_files = [
     'YKZipKit/Classes/minizip/*.h',
   ]
  
  # 设置预处理器宏
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'HAVE_ARC4RANDOM_BUF HAVE_ICONV HAVE_INTTYPES_H HAVE_PKCRYPT HAVE_STDINT_H HAVE_WZAES HAVE_ZLIB ZLIB_COMPAT'
  }

  s.libraries = 'iconv', 'c++'
  s.framework = 'Security'
end
