Pod::Spec.new do |s|
  s.name             = 'YKHUD'
  s.version          = '1.0.0'
  s.summary          = 'A short description of YKHUD.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/liuxiaobin/YKHUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liuxiaobin' => 'liuxiaomike@gmail.com' }
  s.source           = { :git => 'https://github.com/liuxiaobin/YKHUD.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.static_framework = true
  s.swift_version         = '5.0'
  s.ios.deployment_target = '9.0'
  s.default_subspec = 'Source'
  
  s.subspec 'Source' do |ss|
    ss.source_files = 'YKHUD/Classes/*.{h,m}'
    ss.resources    = 'YKHUD/**/*.bundle'
    ss.framework    = 'QuartzCore'
  end
end
