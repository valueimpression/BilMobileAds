# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

workspace 'BilMobileAds.xcworkspace'

def pbm_pods
  use_frameworks!

  pod 'Google-Mobile-Ads-SDK', '7.68.0'
end


target 'BilMobileAds' do
   project 'BilMobileAds.xcodeproj'

   pbm_pods
end

target 'BilMobileAdsTest' do
   project './BilMobileAdsTest/BilMobileAdsTest.xcodeproj'

   pbm_pods
end
