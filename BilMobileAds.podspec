Pod::Spec.new do |spec|

  spec.name         = "BilMobileAds"
  spec.version      = "1.0.7"
  spec.summary      = "ValueImpression is the trusted platform for premium publishers"
  spec.description  = "ValueImpression is the trusted platform for premium publishers. Our patented proprietary advertising optimization technology has helped hundreds of publishers increase their revenue from 40 to 300%."
  spec.homepage     = "https://valueimpression.com"
  
  spec.license      = "MIT"
  spec.author       = { "valueimpression" => "linhhn@bil.vn" }
  spec.platform     = :ios, "9.0"
  
  spec.swift_version = '5.0'
  spec.source        = { :git => "https://github.com/valueimpression/BilMobileAds.git", :tag => "#{spec.version}" }
  spec.source_files  = "BilMobileAds/**/*.{h,m,swift}"

  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  spec.static_framework = true
  spec.dependency "Google-Mobile-Ads-SDK", '7.60'

end
