
Pod::Spec.new do |s|

s.name         = "EzImageLoader"
s.version      = "3.0.4"
s.summary      = "image loader"

s.homepage     = "http://nagisaworks.com"
s.license     = { :type => "MIT" }
s.author       = { "asaday" => "" }

s.platform     = :ios, "8.0"
s.source       = { :git=> "https://github.com/asaday/EzImageLoader.git", :tag => s.version }
s.source_files  = "sources/**/*.{swift,h,m}"
s.vendored_frameworks = 'frameworks/WebP.framework'
s.requires_arc = true

s.dependency  'EzHTTP'
s.module_map = 'resources/module.modulemap'
s.private_header_files = 'sources/webp.h','sources/CommonCrypto_re.h'


end