# BilMobileAds IOS

#### Step 1: Add to Podfile
```gradle
  pod 'BilMobileAds', '1.2.1'
```
##### Note:
If you dont have Podfile. Run command below in terminal at your project folder
```gradle
  pod init
```
#### Step 2: Run in terminal
```gradle
  pod update
  
  or pod install --repo-update
```

#### Step 3: Add to Info.plist
```gradle
  GADIsAdManagerApp YES (Type: Boolean)
```
