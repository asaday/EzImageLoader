
Pod::Spec.new do |s|

s.name         = "EzImageLoader"
s.version      = "3.6.0"
s.summary      = "image loader"

s.homepage     = "http://nagisaworks.com"
s.license     = { :type => "MIT" }
s.author       = { "asaday" => "" }

s.ios.deployment_target = '9.0'
s.ios.deployment_target = '9.0'
s.osx.deployment_target = '10.11'
s.tvos.deployment_target = '9.0'
s.watchos.deployment_target = '2.0'

s.source       = { :git=> "https://github.com/asaday/EzImageLoader.git", :tag => s.version }
s.source_files  = "Sources/**/*", "webp/*"

s.dependency 'EzHTTP'
s.dependency 'libwebp', '~> 1.0'

end
