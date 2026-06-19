Pod::Spec.new do |s|
  s.name             = 'WechatOpenSDK-XCFramework'
  s.version          = '2.0.5'
  s.summary          = 'WeChat Open SDK (local vendored XCFramework)'
  s.description      = 'Vendored copy of WechatOpenSDK 2.0.5 to avoid CocoaPods downloading from dldir1.qq.com during pod install.'
  s.homepage         = 'https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html'
  s.license          = { :type => 'Copyright', :text => 'Copyright © Tencent. All rights reserved.' }
  s.author           = { 'Tencent' => 'wechat@tencent.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '12.0'
  s.vendored_frameworks = 'WechatOpenSDK.xcframework'
  s.frameworks       = 'CoreGraphics', 'Security', 'WebKit'
  s.libraries        = 'c++', 'z', 'sqlite3.0'
  s.requires_arc     = true
  s.pod_target_xcconfig = {
    'VALID_ARCHS' => 'arm64 x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
