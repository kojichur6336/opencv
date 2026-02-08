Pod::Spec.new do |spec|

  spec.name         = "YKWebRTC"
  spec.version      = "141.0.0"
  spec.summary      = "Unofficial distribution of WebRTC framework binaries for iOS. "
  spec.description  = <<-DESC
  This pod contains unofficial distribution of WebRTC framework binaries for iOS.
  All binaries in this repository are compiled from the official WebRTC source code without any modifications to the sources code or to the output binaries.
  DESC

  spec.homepage     = "https://github.com/LiuSky/WebRTC"
  spec.license      = { :type => 'BSD', :file => 'WebRTC.xcframework/LICENSE' }
  spec.author       = "LiuSky"
  spec.ios.deployment_target = '12.0'
  spec.osx.deployment_target = '10.11'
  spec.source       = { :local => "Frameworks" }
  spec.vendored_frameworks = "Frameworks/WebRTC.framework"
  spec.public_header_files = "Frameworks/WebRTC.framework/Headers/*.h"
end
