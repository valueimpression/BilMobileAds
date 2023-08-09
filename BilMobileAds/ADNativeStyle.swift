//
//  ADNative.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADNativeStyle : NSObject, GADBannerViewDelegate, GADAdSizeDelegate {
    
    // MARK: - View OBJ
    weak var adView: UIView!
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADNativeStyleDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: NativeRequest!
    private var amNative: GAMBannerView!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    private var defaultAnchor: Anchor!
    private var adFormatDefault: ADFormat!
    private var curNativeSize: MyBannerSize!
    
    private var isDisSetupAnchor: Bool = false
    private var isLoadNativeSucc: Bool = false
    private var setDefaultBidType: Bool = true
    private var isFetchingAD: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, view adView: UIView, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement: \(placement) Init")
        
        self.defaultAnchor = .Center
        
        self.adUIViewCtr = adUIViewCtr
        self.adView = adView
        self.adDelegate = adUIViewCtr as? ADNativeStyleDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    // MARK: - Handler AD
    func getConfigAD() {
        self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement)
        if self.adUnitObj == nil {
            self.isFetchingAD = true
            
            // Setup Application Delegate
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
                                                   name: UIApplication.didEnterBackgroundNotification, object: nil)
            
            // Get AdUnit Info
            PBMobileAds.shared.getADConfig(adUnit: self.placement) { [weak self] (res: Result<AdUnitObj, Error>) in
                switch res{
                case .success(let data):
                    PBMobileAds.shared.log(logType: .info, "ADNativeStyle placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.load()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADNativeStyle placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    self?.destroy()
                    break
                }
            }
        } else {
            self.load()
        }
    }
    
    func processNoBids() -> Bool {
        if self.adUnitObj.adInfor.count >= 2 && self.adFormatDefault == ADFormat(rawValue: self.adUnitObj.defaultType)  {
            self.setDefaultBidType = false
            self.load()
            return true
        } else {
            // Both or .video, .html is no bids -> wait and preload.
            PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' No Bids.")
            return false
        }
    }
    
    func resetAD() {
        if self.adUnit == nil || self.amNative == nil { return }
        
        self.isFetchingAD = false
        self.isLoadNativeSucc = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amNative?.removeFromSuperview()
        self.amNative = nil
    }
    
    // MARK: - Load AD
    @objc public func load() {
        PBMobileAds.shared.log(logType: .debug, "ADNativeStyle Placement '\(String(describing: self.placement))' - isLoaded: \(self.isLoaded()) | isFetchingAD: \(self.isFetchingAD)")
        if self.adView == nil {
            PBMobileAds.shared.log(logType: .error, "ADNativeStyle placement: \(String(describing: self.placement)), AdView Placeholder is nil.");
            return
        }
        
        if self.adUnitObj == nil || self.isLoaded() || self.isFetchingAD {
            if self.adUnitObj == nil && !self.isFetchingAD {
                PBMobileAds.shared.log(logType: .info, "ADNativeStyle placement: \(String(describing: self.placement)) is not ready to load.");
                self.getConfigAD();
                return
            }
            return
        }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))' is not active or not exist.")
            return
        }
        
        // Check and Set Default
        self.adFormatDefault = ADFormat(rawValue: self.adUnitObj.defaultType)
        if !self.setDefaultBidType && self.adUnitObj.adInfor.count >= 2 {
            self.adFormatDefault = self.adFormatDefault == .vast ? .html : .vast
            self.setDefaultBidType = true
        }
        
        // Get AdInfor
        let isVideo = self.adFormatDefault == ADFormat.vast
        guard let adInfor = PBMobileAds.shared.getAdInfor(isVideo: isVideo, adUnitObj: self.adUnitObj) else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADNativeStyle Placement '" + self.placement + "' is not exist.")
            return
        }
        
        PBMobileAds.shared.log(logType: .info, "Load ADNativeStyle Placement: \(String(describing: self.placement))")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADNativeStyle] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
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
        
        // Set auto refresh time | refreshTime is -> sec
        self.startFetchData()
        
        self.amNative = GAMBannerView(adSize: GADAdSizeFluid)
        self.amNative.adUnitID = adInfor.adUnitID
        self.amNative.delegate = self
        self.amNative.adSizeDelegate = self
        self.amNative.rootViewController = self.adUIViewCtr
        self.adView.addSubview(self.amNative)
        
        var frameRect = self.amNative.frame
        frameRect.size.width = self.adView.bounds.width
        self.amNative.frame = frameRect
        
        // Set a multisize fluid request.
        self.amNative.validAdSizes = [NSValueFromGADAdSize(GADAdSizeFluid), NSValueFromGADAdSize(GADAdSizeBanner)]
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADNativeStyle placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            
            if resultCode == .prebidDemandFetchSuccess {
                self?.amNative?.load(self?.amRequest)
            } else {
                self?.isFetchingAD = false
                self?.isLoadNativeSucc = false
                
                if resultCode == .prebidDemandNoBids {
                    let _ = self?.processNoBids()
                } else if resultCode == .prebidDemandTimedOut {
                    PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self?.placement))' Timeout. Please check your internet connect.")
                }
            }
        }
    }
    
    @objc public func destroy() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        if self.adUnit == nil { return }
        PBMobileAds.shared.log(logType: .info, "Destroy ADNativeStyle Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    @objc public func setAnchor(anchor: Anchor){
        self.defaultAnchor = anchor
    }
    
    @objc public func isLoaded() -> Bool {
        return self.isLoadNativeSucc
    }
    
    @objc public func setListener(_ adDelegate : ADNativeStyleDelegate){
        self.adDelegate = adDelegate
    }
    
    @objc public func isDisSetupAnchor(_ isSet: Bool) { // Dis for Unity
        self.isDisSetupAnchor = isSet
    }
    
    @objc public func getWidthInPixels() -> CGFloat {
        if self.amNative == nil { return 0 }
        return self.amNative.frame.standardized.width * UIScreen.main.scale
    }
    
    @objc public func getHeightInPixels() -> CGFloat {
        if self.amNative == nil { return 0 }
        return self.amNative.frame.standardized.height * UIScreen.main.scale
    }
    
    @objc public func startFetchData() {
        if let refreshTime = self.adUnitObj?.refreshTime {
            self.adUnit.setAutoRefreshMillis(time: refreshTime * 1000) // convert sec to milisec
        }
    }
    
    @objc public func stopFetchData() {
        self.adUnit?.stopAutoRefresh()
    }
    
    // MARK: - Private FUNC
    func getAdSize() -> CGSize? {
        return self.amNative?.adSize.size
    }
    
    func setupAnchor(_ view: GADBannerView){
        if isDisSetupAnchor { return; }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        if defaultAnchor == .TopLeft {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .TopCenter {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .TopRight {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .CenterLeft {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .Center {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .CenterRight {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .BottomLeft {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .BottomCenter {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .BottomRight {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
        }
    }
    
    // MARK: - Delegate
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.isFetchingAD = false
        self.isLoadNativeSucc = true
        AdViewUtils.findPrebidCreativeSize(bannerView,
                                           success: { (size) in
            guard let bannerView = bannerView as? GAMBannerView else {
                return
            }
            self.setupAnchor(bannerView)
            bannerView.resize(GADAdSizeFromCGSize(size))
            
            PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))'")
            self.adDelegate?.nativeStyleDidReceiveAd?()
        },
                                           failure: { (error) in
            PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
            self.adDelegate?.nativeStyleDidReceiveAd?()
        })
    }
    
    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        self.isLoadNativeSucc = false
        
        //        if error.code == BilConstants.ERROR_NO_FILL {
        //            if !self.processNoBids() {
        //                self.isFetchingAD = false
        //                self.adDelegate?.nativeStyleFailedToLoad?(error: "nativeFailedToLoad: ADNativeStyle Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        //            }
        //        } else {
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adDelegate?.nativeStyleFailedToLoad?(error: "nativeFailedToLoad: ADNativeStyle Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        //        }
    }
    
    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.nativeStyleWillPresentScreen?()
    }
    
    public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.nativeStyleWillDismissScreen?()
    }
    
    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.nativeStyleDidDismissScreen?()
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADNativeStyle Placement '\(String(describing: self.placement))'")
        self.adDelegate?.nativeStyleWillLeaveApplication?()
    }
    
    /// GADAdSizeDelegate
    public func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {}
    
    // MARK: - Application Delegate
    @objc func appDidBecomeActive(_ application: UIApplication) {
        PBMobileAds.shared.log(logType: .debug, "ADNativeStyle Placement '\(String(describing: self.placement))'")
        self.startFetchData()
    }
    
    @objc func appDidEnterBackground(_ application: UIApplication) {
        PBMobileAds.shared.log(logType: .debug, "ADNativeStyle Placement '\(String(describing: self.placement))'")
        self.stopFetchData()
    }
    
}

@objc public protocol ADNativeStyleDelegate {
    
    // Called when an ad request loaded an ad.
    @objc optional func nativeStyleDidReceiveAd()
    
    // Called when an ad request failed.
    @objc optional func nativeStyleFailedToLoad(error: String)
    
    // Called just before presenting the user a full screen view, such as a browser, in response to
    // clicking on an ad.
    @objc optional func nativeStyleWillPresentScreen()
    
    @objc optional func nativeStyleWillDismissScreen()
    
    @objc optional func nativeStyleDidDismissScreen()
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store).
    @objc optional func nativeStyleWillLeaveApplication()
    
}
