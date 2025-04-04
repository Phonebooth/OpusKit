Pod::Spec.new do |s|
  s.name                  = 'OpusKit'
  s.version               = '1.5.2'
  s.summary               = 'A totally open, royalty-free, highly versatile audio codec.'
  s.homepage              = 'https://github.com/Phonebooth/OpusKit'
  s.author                = 'Trey Ethridge'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.source                = {
    :http => 'https://github.com/Phonebooth/OpusKit/releases/download/' + s.version.to_s + '/OpusKit.xcframework.zip'
  }
  s.swift_version         = '5.0'
  s.ios.deployment_target = '14.0'
  s.vendored_frameworks   = 'OpusKit.xcframework'
end
