Pod::Spec.new do |s|
  s.name     = 'iConsole'
  s.version  = '1.5.2'
  s.license  = 'zlib'
  s.summary  = 'In-app console for viewing logs and typing debug commands in iOS apps'
  s.homepage = 'https://github.com/nicklockwood/iConsole'
  s.authors  = 'Nick Lockwood'
  s.source   = { :git => 'https://github.com/nicklockwood/iConsole.git', :tag => '1.5.2' }
  s.source_files = 'iConsole'
  s.requires_arc = true
  s.ios.deployment_target = '4.3'
end