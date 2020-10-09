//
//  ADNative.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADNativeStyle : NSObject, GADBannerViewDelegate, GADAdSizeDelegate, CloseListenerDelegate {
    
    // MARK: - View OBJ
    weak var appNativeView: UIView!
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADNativeDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = DFPRequest()
    private var adUnit: NativeRequest!
    private var amNative: DFPBannerView!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    private var defaultAnchor: Anchor!
    private var adFormatDefault: ADFormat!
    private var curNativeSize: MyBannerSize!
    private var timeAutoRefesh: Double = Constants.BANNER_AUTO_REFRESH_DEFAULT
    private var isLoadNativeSucc: Bool = false
    private var isRecallingPreload: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, view adView: UIView, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADNativeStyle Init: \(placement)")
        
        self.defaultAnchor = .Center
        
        self.adUIViewCtr = adUIViewCtr
        self.appNativeView = adView
        self.adDelegate = adUIViewCtr as? ADNativeDelegate
        
        self.placement = placement
        
        // Get AdUnit
        if (self.adUnitObj == nil) {
            self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement);
            if (self.adUnitObj == nil) {
                PBMobileAds.shared.getADConfig(adUnit: self.placement) { (res: Result<AdUnitObj, Error>) in
                    switch res{
                    case .success(let data):
                        PBMobileAds.shared.log("Get Config ADNativeStyle placement: '\(String(describing: self.placement))' Success")
                        DispatchQueue.main.async{
                            self.adUnitObj = data
                            
                            if PBMobileAds.shared.gdprConfirm && CMPConsentTool().needShowCMP() {
                                let cmp = ShowCMP()
                                cmp.closeDelegate = self
                                cmp.open(self.adUIViewCtr, appName: PBMobileAds.shared.appName)
                            } else {
                                self.load()
                            }
                        }
                        break
                    case .failure(let err):
                        PBMobileAds.shared.log("Get Config ADNativeStyle placement: '\(String(describing: self.placement))' Fail with Error: \(err.localizedDescription)")
                        break
                    }
                }
            }
        }
    }
    
    deinit {
        PBMobileAds.shared.log("ADNativeStyle Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ADNativeStyle Placement '\(String(describing: self.placement))' with ConsentStr: \(String(describing: consentStr))")
            self.load()
        }
    }
    
    // MARK: - Preload + Load
    func deplayCallPreload() {
        self.isRecallingPreload = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.BANNER_RECALL_DEFAULT) {
            self.isRecallingPreload = false
            self.load()
        }
    }
    
    func getAdInfor(isVideo: Bool) -> AdInfor? {
        for infor in self.adUnitObj.adInfor {
            if infor.isVideo == isVideo {
                return infor
            }
        }
        return nil
    }
    
    func resetAD() {
        if self.adUnit == nil || self.amNative == nil { return }
        
        self.isRecallingPreload = false
        self.isLoadNativeSucc = false
        self.appNativeView?.removeFromSuperview()
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amNative?.removeFromSuperview()
        self.amNative = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amNative.load(self.amRequest)
        } else {
            self.isLoadNativeSucc = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                self.deplayCallPreload()
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                self.deplayCallPreload()
            }
        }
    }
    
    public func load() {
        PBMobileAds.shared.log("ADNativeStyle Placement '\(String(describing: self.placement))' - isLoaded: \(self.isLoaded()) |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isLoaded() == true || self.isRecallingPreload == true { return }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADNativeStyle Placement '\(String(describing: self.placement))' is not active or not exist");
            return
        }
        
        // Check and set default
        self.adFormatDefault = ADFormat(rawValue: adUnitObj.defaultType)
        if adUnitObj.adInfor.count < 2 {
            // set adformat theo loại duy nhất có
            self.adFormatDefault = adUnitObj.adInfor[0].isVideo ? .vast : .html
        }
        
        // Set GDPR
        if PBMobileAds.shared.gdprConfirm {
            let consentStr = CMPConsentToolAPI().consentString
            if consentStr != nil && consentStr != "" {
                Targeting.shared.subjectToGDPR = true
                Targeting.shared.gdprConsentString = consentStr
            }
        }
        
        // Get AdInfor
        let isVideo = self.adFormatDefault == ADFormat.vast;
        guard let adInfor = self.getAdInfor(isVideo: isVideo) else {
            PBMobileAds.shared.log("AdInfor of ADNativeStyle Placement '" + self.placement + "' is not exist");
            return
        }
        
        PBMobileAds.shared.log("Load ADNativeStyle Placement: \(String(describing: self.placement))")
        // Setup PBS
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log("[ADNativeStyle] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
        // Setup Native Asset
        let image = NativeAssetImage(minimumWidth: 200, minimumHeight: 200, required: true)
        image.type = ImageAsset.Main
        let icon = NativeAssetImage(minimumWidth: 20, minimumHeight: 20, required: true)
        icon.type = ImageAsset.Icon
        let title = NativeAssetTitle(length: 90, required: true)
        let body = NativeAssetData(type: DataAsset.description, required: true)
        let cta = NativeAssetData(type: DataAsset.ctatext, required: true)
        let sponsored = NativeAssetData(type: DataAsset.sponsored, required: true)
        let eventTrackers: NativeEventTracker = NativeEventTracker(event: EventType.Impression, methods: [EventTracking.Image,EventTracking.js])
        
        // Create AdUnit
        self.adUnit = NativeRequest(configId: adInfor.configId, assets: [icon,title,image,body,cta,sponsored])
        self.adUnit.context = ContextType.Social
        self.adUnit.placementType = PlacementType.FeedContent
        self.adUnit.contextSubType = ContextSubType.Social
        self.adUnit.eventtrackers = [eventTrackers]
        self.adUnit.setAutoRefreshMillis(time: self.timeAutoRefesh)
        
        self.amNative = DFPBannerView(adSize: kGADAdSizeFluid)
        self.amNative.adUnitID = adInfor.adUnitID
        self.amNative.delegate = self
        self.amNative.adSizeDelegate = self
        self.amNative.rootViewController = self.adUIViewCtr
        self.appNativeView.addSubview(self.amNative)
        
        var frameRect = self.amNative.frame
        frameRect.size.width = self.appNativeView.bounds.width
        self.amNative.frame = frameRect
        
        // set a multisize fluid request.
        self.amNative.validAdSizes = [NSValueFromGADAdSize(kGADAdSizeFluid), NSValueFromGADAdSize(kGADAdSizeBanner)]
        
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADNativeStyle placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            self?.handlerResult(resultCode)
        }
    }
    
    public func destroy() {
        PBMobileAds.shared.log("Destroy ADNativeStyle Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    private func setAnchor(anchor: Anchor){
        self.defaultAnchor = anchor
    }
    
    public func getAdSize() -> CGSize? {
        return self.amNative?.adSize.size
    }
    
    public func setAutoRefreshMillis(timeMillis: Double){
        self.timeAutoRefesh = timeMillis
        self.adUnit?.setAutoRefreshMillis(time: timeMillis)
    }
    
    public func isLoaded() -> Bool {
        return self.isLoadNativeSucc
    }
    
    public func setListener(_ adDelegate : ADNativeDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Private FUNC
    func getBannerSize(typeBanner: BannerSize) -> CGSize {
        switch typeBanner {
        case .Banner320x50:
            return CGSize(width: 320, height: 50)
        case .Banner320x100:
            return CGSize(width: 320, height: 100)
        case .Banner300x250:
            return CGSize(width: 300, height: 250)
        case .Banner468x60:
            return CGSize(width: 468, height: 60)
        case .Banner728x90:
            return CGSize(width: 728, height: 90)
        case .SmartBanner:
            return CGSize(width: 1, height: 1)
        }
    }
    
    func getGADBannerSize(typeBanner: BannerSize) -> GADAdSize {
        switch typeBanner {
        case .Banner320x50:
            return kGADAdSizeBanner
        case .Banner320x100:
            return kGADAdSizeLargeBanner
        case .Banner300x250:
            return kGADAdSizeMediumRectangle
        case .Banner468x60:
            return kGADAdSizeFullBanner
        case .Banner728x90:
            return kGADAdSizeLeaderboard
        case .SmartBanner:
            if UIApplication.shared.statusBarOrientation.isPortrait {
                return kGADAdSizeSmartBannerPortrait
            } else {
                return kGADAdSizeSmartBannerLandscape
            }
        }
    }
    
    func getBannerSize(w: String, h: String) -> BannerSize {
        let typeBanner = "\(w)x\(h)"
        
        if typeBanner == "320x50" {
            return .Banner320x50
        } else if typeBanner == "320x100" {
            return .Banner320x100
        } else if typeBanner ==  "300x250" {
            return .Banner300x250
        } else if typeBanner ==  "468x60"{
            return .Banner468x60
        } else if typeBanner ==  "728x90"{
            return .Banner728x90
        }
        
        return .Banner320x50
    }
    
    func setupAnchor(_ view: GADBannerView){
        view.translatesAutoresizingMaskIntoConstraints = false
        if defaultAnchor == .TopLeft {
            view.topAnchor.constraint(equalTo: self.appNativeView.topAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.appNativeView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .TopCenter {
            view.topAnchor.constraint(equalTo: self.appNativeView.topAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appNativeView.centerXAnchor).isActive = true
        } else if defaultAnchor == .TopRight {
            view.topAnchor.constraint(equalTo: self.appNativeView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.appNativeView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .CenterLeft {
            view.centerYAnchor.constraint(equalTo: self.appNativeView.centerYAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: self.appNativeView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .Center {
            view.centerYAnchor.constraint(equalTo: self.appNativeView.centerYAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appNativeView.centerXAnchor).isActive = true
        } else if defaultAnchor == .CenterRight {
            view.centerYAnchor.constraint(equalTo: self.appNativeView.centerYAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.appNativeView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .BottomLeft {
            view.bottomAnchor.constraint(equalTo: self.appNativeView.bottomAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.appNativeView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .BottomCenter {
            view.bottomAnchor.constraint(equalTo: self.appNativeView.bottomAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appNativeView.centerXAnchor).isActive = true
        } else if defaultAnchor == .BottomRight {
            view.bottomAnchor.constraint(equalTo: self.appNativeView.bottomAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.appNativeView.rightAnchor, constant: 0).isActive = true
        }
    }
    
    // MARK: - Delegate
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.isLoadNativeSucc = true
        AdViewUtils.findPrebidCreativeSize(bannerView,
                                           success: { (size) in
                                            guard let bannerView = bannerView as? DFPBannerView else {
                                                return
                                            }
                                            self.setupAnchor(bannerView)
                                            bannerView.resize(GADAdSizeFromCGSize(size))

                                            PBMobileAds.shared.log("nativeAdDidRecordImpression: ADNativeStyle Placement '\(String(describing: self.placement))'");
                                            self.adDelegate?.nativeAdDidRecordImpression?()
        },
                                           failure: { (error) in
                                            PBMobileAds.shared.log("nativeAdDidRecordImpression: ADNativeStyle Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
                                            self.adDelegate?.nativeAdDidRecordImpression?()
        })
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("nativeWillLeaveApplication: ADNativeStyle Placement '\(String(describing: self.placement))'");
//        self.adDelegate?.nativeWillLeaveApplication?(data: "nativeWillLeaveApplication: ADNativeStyle Placement '\(String(describing: self.placement))'")
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        self.isLoadNativeSucc = false
        
        PBMobileAds.shared.log("nativeFailedToLoad: ADNativeStyle Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)");
        self.adDelegate?.nativeFailedToLoad?(error: "nativeFailedToLoad: ADNativeStyle Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    // GADAdSizeDelegate
    public func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
        
    }
}

@objc public protocol ADNativeDelegate {
    
    /*
     * Called when an ad native custom view loaded. (Only work with ADNativeCustom)
     * */
    @objc optional func nativeViewLoaded(viewBuilder: ADNativeViewBuilder)
    
    /*
     * Called when an ad native request loaded complete an ad.
     * */
    @objc optional func nativeAdDidRecordImpression()
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store). The normal
    // UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately
    // before this.
    @objc optional func nativeAdDidRecordClick()
    
    /*
     * Called when an ad request loaded fail.
     * */
    @objc optional func nativeFailedToLoad(error: String)
    
}
