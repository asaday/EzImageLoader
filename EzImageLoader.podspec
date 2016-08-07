
Pod::Spec.new do |s|

s.name         = "EzImageLoader"
s.version      = "0.0.1"
s.summary      = "image loader"

s.homepage     = "http://nagisaworks.com"
s.license     = { :type => "MIT" }
s.author       = { "asaday" => "" }

s.platform     = :ios, "8.0"
s.source       = { :git=> "https://github.com/asaday/EzImageLoader.git", :tag => s.version }
s.source_files  = "sources/**/*.{swift,h,m}"
s.preserve_paths = "modules/**"
s.vendored_frameworks = 'frameworks/WebP.framework'
s.requires_arc = true

s.dependency  'EzHTTP'


s.xcconfig= {
  "SWIFT_INCLUDE_PATHS" =>    "${PODS_ROOT}/EzImageLoader/modules",
}

end