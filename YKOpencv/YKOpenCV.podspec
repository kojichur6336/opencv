Pod::Spec.new do |s|
  s.name             = 'YKOpenCV'
  s.version          = '4.12.0'
  s.summary          = 'OpenCV (Computer Vision) for iOS - 这个版本对应的是4.12.0'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/YKP-com/MQOpenCV'
  s.license          = { :type => 'MIT' }  # 不指定文件，避免找不到
  s.author           = { 'xiaobin liu' => 'liuxiaomike@gmail.com' }
  s.source           = { :git => 'https://github.com/YKP-com/MQOpenCV.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.requires_arc = false
  s.static_framework = true


  s.vendored_frameworks = 'opencv2.framework'
  s.header_mappings_dir = 'opencv2.framework/Versions/A/Headers/'
  s.public_header_files = 'opencv2.framework/Versions/A/Headers/**/*.{h,hpp}'
  s.source_files = 'opencv2.framework/Versions/A/Headers/**/*.{h,hpp}'

  s.libraries = 'stdc++'
  s.frameworks = [
    'Accelerate',
    'AssetsLibrary',
    'AVFoundation',
    'CoreGraphics',
    'CoreImage',
    'CoreMedia',
    'CoreVideo',
    'Foundation',
    'QuartzCore',
    'UIKit'
  ]


  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  
end
