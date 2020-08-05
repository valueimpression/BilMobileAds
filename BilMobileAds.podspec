Pod::Spec.new do |spec|

  spec.name         = "BilMobileAds"
  spec.version      = "1.0.3"
  spec.summary      = "Summary of BilMobileAds."
  spec.description  = "Description of BilMobileAds."
  spec.homepage     = "https://valueimpression.com"
  
  spec.license      = "MIT"
  spec.author       = { "valueimpression" => "linhhn@bil.vn" }
  spec.platform     = :ios, "9.0"
  
  spec.swift_version = '4.2'
  spec.source        = { :git => "https://github.com/valueimpression/BilMobileAds.git", :tag => "#{spec.version}" }
  spec.source_files  = "BilMobileAds/**/*"
  spec.exclude_files  = "BilMobileAds/*.plist"

  spec.static_framework = true
  spec.dependency "Google-Mobile-Ads-SDK", '7.60'

end
