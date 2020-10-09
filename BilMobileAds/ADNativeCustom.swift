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
    private var adFormatDefault: ADFormat!
    private var isRecallingPreload: Bool = false
    private var isLoading: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADNativeCustom Init: \(placement)")
        
        self.adUIViewCtr = adUIViewCtr
        self.adNativeDelegate = adUIViewCtr as? ADNativeDelegate
        
        self.placement = placement
        
        // Get AdUnit
        if (self.adUnitObj == nil) {
            self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement);
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
            }
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
        if self.adUnit == nil || self.amNativeDFP == nil { return }
        
        self.isLoading = false
        self.isRecallingPreload = false

        self.adUnit.stopAutoRefresh()
        self.adUnit = nil
        
        self.amNativeDFP = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amNativeDFP.load(self.amRequest)
        } else {
            self.isLoading = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                self.deplayCallPreload()
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                self.deplayCallPreload()
            }
        }
    }
    
    public func load() {
        PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' - isLoading: \(self.isLoading) | isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isLoading || self.isRecallingPreload { return }
        
        if self.curNumOfAds == MAX_ADS {
            PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' current store \(self.curNumOfAds) ads. (Store max \(MAX_ADS) ads)")
            return
        }
        
        self.resetAD()
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADNativeCustom Placement '\(String(describing: self.placement))' is not active or not exist");
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
            PBMobileAds.shared.log("AdInfor of ADNativeCustom Placement '" + self.placement + "' is not exist");
            return
        }
        
        PBMobileAds.shared.log("Load ADNativeCustom Placement: \(String(describing: self.placement))")
        // Setup PBS
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
        
        self.isLoading = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADNativeCustom placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            self?.handlerResult(resultCode);
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
    // GADUnifiedNativeAdLoaderDelegate - AdLoaded View
    public func adLoader(_ adLoader: GADAdLoader, didReceive unifiedNativeAd: GADUnifiedNativeAd) {
        self.isLoading = false
        
        self.curNumOfAds += 1
        
        /// Set ourselves as the native ad delegate to be notified of native ad events.
        unifiedNativeAd.delegate = self
        
        /// Create ADNativeViewBuilder
        let builder = ADNativeViewBuilder(placement: self.placement, unifiedNativeAd: unifiedNativeAd)

        PBMobileAds.shared.log("nativeViewLoaded: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.adNativeDelegate?.nativeViewLoaded?(viewBuilder: builder)
    }
    
    // GADAdLoaderDelegate - Error
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        self.isLoading = false
        
        PBMobileAds.shared.log("nativeFailedToLoad: ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)");
        self.adNativeDelegate?.nativeFailedToLoad?(error: "nativeFailedToLoad: ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    // GADUnifiedNativeAdDelegate
    public func nativeAdDidRecordImpression(_ nativeAd: GADUnifiedNativeAd) {
        self.curNumOfAds -= 1
        
        PBMobileAds.shared.log("nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.adNativeDelegate?.nativeAdDidRecordImpression?()
    }
    public func nativeAdDidRecordClick(_ nativeAd: GADUnifiedNativeAd) {
        PBMobileAds.shared.log("nativeAdDidRecordClick: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.adNativeDelegate?.nativeAdDidRecordClick?()
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
