//
//  ADNativeCustom.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 9/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADNativeCustom : NSObject, GADUnifiedNativeAdLoaderDelegate, GADAdLoaderDelegate, GADUnifiedNativeAdDelegate, CloseListenerDelegate {
    
    // MARK: - View OBJ
    weak var adUIViewCtr: UIViewController!
    weak var adNativeDelegate: ADNativeDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = DFPRequest()
    private var adUnit: NativeRequest!
    private var amNativeDFP: GADAdLoader!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    public let MAX_ADS: Int = 5
    private var curNumOfAds: Int = 0
    private var isFetchingAD: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADNativeCustom Init: \(placement)")
        
        self.adUIViewCtr = adUIViewCtr
        self.adNativeDelegate = adUIViewCtr as? ADNativeDelegate
        
        self.placement = placement
        
        // Get AdUnit
        self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement)
        if (self.adUnitObj == nil) {
            PBMobileAds.shared.getADConfig(adUnit: self.placement) { (res: Result<AdUnitObj, Error>) in
                switch res{
                case .success(let data):
                    PBMobileAds.shared.log("Get Config ADNativeCustom placement: '\(String(describing: self.placement))' Success")
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
                    PBMobileAds.shared.log("Get Config ADNativeCustom placement: '\(String(describing: self.placement))' Fail with Error: \(err.localizedDescription)")
                    break
                }
            }
        } else {
            self.load()
        }
    }
    
    deinit {
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' with ConsentStr: \(String(describing: consentStr))")
            self.load()
        }
    }
    
    // MARK: - Preload + Load
    func resetAD() {
        if self.adUnit == nil || self.amNativeDFP == nil { return }
        
        self.isFetchingAD = false
        
        self.adUnit.stopAutoRefresh()
        self.adUnit = nil
        
        self.amNativeDFP = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amNativeDFP?.load(self.amRequest)
        } else {
            self.isFetchingAD = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' No Bids.")
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' Timeout. Please check your internet connect.")
            }
        }
    }
    
    public func load() {
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' - isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil || self.isFetchingAD { return }
        self.resetAD()
        
        // Check store max native ads
        if self.curNumOfAds == MAX_ADS {
            PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' current store \(self.curNumOfAds) ads. (Store max \(MAX_ADS) ads)")
            return
        }

        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' is not active or not exist.")
            return
        }
        
        // Set GDPR
        PBMobileAds.shared.setGDPR()
        
        // Get AdInfor
        let isVideo = ADFormat(rawValue: self.adUnitObj.defaultType) == ADFormat.vast
        guard let adInfor = PBMobileAds.shared.getAdInfor(isVideo: isVideo, adUnitObj: self.adUnitObj) else {
            PBMobileAds.shared.log("AdInfor of ADNativeCustom Placement '" + self.placement + "' is not exist.")
            return
        }
        
        PBMobileAds.shared.log("Load ADNativeCustom Placement: \(String(describing: self.placement))")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log("[ADNativeCustom] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
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
        
        let videoOptions = GADVideoOptions()
        videoOptions.startMuted = true
        self.amNativeDFP = GADAdLoader(adUnitID: adInfor.adUnitID, rootViewController: self.adUIViewCtr, adTypes: [ .unifiedNative ], options: [videoOptions])
        self.amNativeDFP.delegate = self
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADNativeCustom placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            self?.handlerResult(resultCode)
        }
    }
    
    public func destroy() {
        PBMobileAds.shared.log("Destroy ADNativeCustom Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    public func setListener(_ adNativeDelegate : ADNativeDelegate) {
        self.adNativeDelegate = adNativeDelegate
    }
    
    public func numOfAds() -> Int {
        return self.curNumOfAds
    }
    
    // MARK: - Delegate
    public func adLoader(_ adLoader: GADAdLoader, didReceive unifiedNativeAd: GADUnifiedNativeAd) {
        self.curNumOfAds += 1
        self.isFetchingAD = false
        
        /// Set ourselves as the native ad delegate to be notified of native ad events.
        unifiedNativeAd.delegate = self
        
        /// Create ADNativeViewBuilder
        let builder: ADNativeViewBuilder = ADNativeViewBuilder(placement: self.placement, unifiedNativeAd: unifiedNativeAd)
        
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.adNativeDelegate?.nativeViewLoaded?(viewBuilder: builder)
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        self.isFetchingAD = false
        
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adNativeDelegate?.nativeFailedToLoad?(error: "nativeFailedToLoad: ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    public func nativeAdDidRecordImpression(_ nativeAd: GADUnifiedNativeAd) {
        self.curNumOfAds -= 1
        
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.adNativeDelegate?.nativeAdDidRecordImpression?(data: "nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    
    public func nativeAdDidRecordClick(_ nativeAd: GADUnifiedNativeAd) {
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.adNativeDelegate?.nativeAdDidRecordClick?(data: "nativeAdDidRecordClick: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
}

@objc public protocol ADNativeVideoDelegate {
    /// Tells the delegate that the video controller has began or resumed playing a video.
    @objc optional func onVideoPlay(data: String)
    /// Tells the delegate that the video controller has paused video.
    @objc optional func onVideoPause(data: String)
    /// Tells the delegate that the video controller's video playback has ended.
    @objc optional func onVideoEnd(data: String)
    /// Tells the delegate that the video controller has muted video.
    @objc optional func onVideoMute(data: String)
    /// Tells the delegate that the video controller has unmuted video.
    @objc optional func onVideoUnMute(data: String)
}

extension Array where Element: Hashable {
    public func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
