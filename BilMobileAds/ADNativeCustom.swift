//
//  ADNativeCustom.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 9/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADNativeCustom : NSObject,
                              GADNativeAdDelegate, GADAdLoaderDelegate,
                              GADCustomNativeAdLoaderDelegate, NativeAdDelegate {
    public func customNativeAdFormatIDs(for adLoader: GADAdLoader) -> [String] {
        return ["12009691"]
    }
    
    
    // MARK: - View OBJ
    weak var adUIViewCtr: UIViewController!
    weak var adNativeDelegate: NativeAdLoaderCustomDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: NativeRequest!
    private var amNativeDFP: GADAdLoader!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    private var isFetchingAD: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement: \(placement) Init")
        
        self.adUIViewCtr = adUIViewCtr
        self.adNativeDelegate = adUIViewCtr as? NativeAdLoaderCustomDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    // MARK: - Handler AD
    func getConfigAD() {
        self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement)
        if self.adUnitObj == nil {
            self.isFetchingAD = true
            
            // Get AdUnit Info
            PBMobileAds.shared.getADConfig(adUnit: self.placement) { [weak self] (res: Result<AdUnitObj, Error>) in
                switch res{
                case .success(let data):
                    PBMobileAds.shared.log(logType: .info, "ADNativeCustom placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.preLoad()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADNativeCustom placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    break
                }
            }
        } else {
            self.preLoad()
        }
    }
    
    func resetAD() {
        if self.adUnit == nil || self.amNativeDFP == nil { return }
        
        self.isFetchingAD = false
        
        self.adUnit.stopAutoRefresh()
        self.adUnit = nil
        
        self.amNativeDFP = nil
    }
    
    // MARK: - Load AD
    public func preLoad() {
        PBMobileAds.shared.log(logType: .debug, "ADNativeCustom Placement '\(String(describing: self.placement))' - isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil {
            PBMobileAds.shared.log(logType: .info, "ADNativeCustom placement: \(String(describing: self.placement)) is not ready to load.");
            self.getConfigAD();
            return
        }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count == 0 {
            PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' is not active or not exist.")
            return
        }
        
        // Get AdInfor
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADNativeCustom Placement '" + self.placement + "' is not exist.")
            return
        }
        
        PBMobileAds.shared.log(logType: .info, "Load ADNativeCustom Placement: \(String(describing: self.placement))")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADNativeCustom] - configID: '\(adInfor.configId)' | adUnitID: '\(String(describing: adInfor.adUnitID))'")
        
        // Setup Native Asset
        let icon = NativeAssetImage(minimumWidth: 20, minimumHeight: 20, required: true)
        icon.type = ImageAsset.Icon
        let image = NativeAssetImage(minimumWidth: 200, minimumHeight: 200, required: true)
        image.type = ImageAsset.Main
        let title = NativeAssetTitle(length: 90, required: true)
        let sponsored = NativeAssetData(type: DataAsset.sponsored, required: false)
        let body = NativeAssetData(type: DataAsset.description, required: true)
        let cta = NativeAssetData(type: DataAsset.ctatext, required: true)
        let eventTrackers: NativeEventTracker = NativeEventTracker(event: EventType.Impression, methods: [EventTracking.Image,EventTracking.js])
        
        // Create AdUnit
        self.adUnit = NativeRequest(configId: adInfor.configId, assets: [icon,title,image,body,cta,sponsored])
        self.adUnit.context = ContextType.Social
        self.adUnit.placementType = PlacementType.FeedContent
        self.adUnit.contextSubType = ContextSubType.Social
        self.adUnit.eventtrackers = [eventTrackers]
        
        let videoOptions = GADVideoOptions()
        videoOptions.startMuted = true
        self.amNativeDFP = GADAdLoader(adUnitID: adInfor.adUnitID!, rootViewController: self.adUIViewCtr, adTypes: [ .native, .customNative, .gamBanner], options: [videoOptions])
        self.amNativeDFP.delegate = self
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADNativeCustom placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            
            self?.amNativeDFP?.load(self?.amRequest)
        }
    }
    
    public func destroy() {
        PBMobileAds.shared.log(logType: .info, "Destroy ADNativeCustom Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    public func setListener(_ adNativeDelegate : NativeAdLoaderCustomDelegate) {
        self.adNativeDelegate = adNativeDelegate
    }
    
    // MARK: - Delegate
    /// Native Custom Template:
    /// GADNativeCustomTemplateAdLoaderDelegate
    public func nativeCustomTemplateIDs(for adLoader: GADAdLoader) -> [String] {
        return [PBMobileAds.shared.nativeTemplateId]
    }
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeCustomTemplateAd: GADCustomNativeAd) {
        Utils.shared.delegate = self
        Utils.shared.findNative(adObject: nativeCustomTemplateAd)
    }
    /// NativeAdDelegate
    public func nativeAdLoaded(ad: NativeAd) {
        self.isFetchingAD = false
        
        /// Create ADNativeViewBuilder
        let builder: ADNativeViewBuilder = ADNativeViewBuilder(placement: self.placement, nativeAd: ad)
        self.adNativeDelegate?.nativeAdViewLoaded?(viewBuilder: builder)
        
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Template Placement '\(String(describing: self.placement))' Loaded")
    }
    public func nativeAdNotFound() {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Template Placement '\(String(describing: self.placement))' Not Found")
    }
    public func nativeAdNotValid() {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Template Placement '\(String(describing: self.placement))' Not Valid")
    }
    /// GADUnifiedNative
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.isFetchingAD = false
        
        /// Create ADNativeViewBuilder
        let builder: ADNativeViewBuilder = ADNativeViewBuilder(placement: self.placement, unifiedNativeAd: nativeAd)
        self.adNativeDelegate?.nativeAdViewLoaded?(viewBuilder: builder)
        
        nativeAd.paidEventHandler = { adValue in
            PBMobileAds.shared.log(logType: .info, "ADNativeCustom Template placement '\(String(describing: self.placement))'")
            let adData = AdData(currencyCode: adValue.currencyCode, precision: adValue.precision.rawValue, microsValue: adValue.value)
            self.adNativeDelegate?.nativeAdPaidEvent?(adData: adData)
        }
        
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom unifiedNativeAd Placement '\(String(describing: self.placement))' loaded")
    }
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        self.isFetchingAD = false
        
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adNativeDelegate?.nativeAdFailedToLoad?(error: "nativeFailedToLoad: ADNativeCustom Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    public func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {}
}

@objc public protocol NativeAdLoaderCustomDelegate {
    /*
     * Called when a request native ad is loaded.
     * */
    @objc optional func nativeAdViewLoaded(viewBuilder: ADNativeViewBuilder)
    
    /*
     * Called when a request native ad is loaded fail.
     * */
    @objc optional func nativeAdFailedToLoad(error: String)
    
    @objc optional func nativeAdPaidEvent(adData: AdData)
}

@objc public protocol NativeAdCustomDelegate {
    /*
     * Called when an ad native did record Impression.
     * */
    @objc optional func nativeAdDidRecordImpression(data: String)
    
    /*
     * Called just before the application will background or terminate because the user clicked on an
     * ad that will launch another application (such as the App Store).
     * The normal UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately before this.
     */
    @objc optional func nativeAdDidRecordClick(data: String)
    
    /*
     * Called when an ad native did Expire.
     * */
    @objc optional func nativeAdDidExpire(data: String)
}

@objc public protocol NativeAdVideoDelegate {
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
