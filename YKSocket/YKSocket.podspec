

Pod::Spec.new do |s|
  s.name             = 'YKSocket'
  s.version          = '1.0.0'
  s.summary          = 'A short description of YKSocket.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/YKP-com/YKSocket'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaobin liu' => 'liuxiaomike@gmail.com' }
  s.source           = { :git => 'https://github.com/YKP-com/YKSocket.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'Classes/**/*'

  s.requires_arc = true
  s.static_framework = true
  s.ios.deployment_target = '10.0'
  s.pod_target_xcconfig = { "DEFINES_MODULE" => 'YES' }
  s.default_subspec = "Core"

  s.subspec 'Core' do |ss|
    ss.source_files = 'Classes/**.{h,m,c,cpp}'
  end

  s.frameworks = 'CFNetwork', 'Security'
end
