//
//  ADInterstitial.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADInterstitial: NSObject, GADInterstitialDelegate, CloseListenerDelegate  {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADInterstitialDelegate!
    
    // MARK: AD OBJ
    private let amRequest = DFPRequest()
    private var adUnit: AdUnit!
    private var amInterstitial: DFPInterstitial!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var adFormatDefault: ADFormat!
    private var isFetchingAD: Bool = false
    private var setDefaultBidType: Bool = true
    
    // MARK: - Init + DeInit
    @objc public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADInterstitial Init: \(placement)")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADInterstitialDelegate
        
        self.placement = placement
        
        // Get AdUnit
        self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement);
        if (self.adUnitObj == nil) {
            PBMobileAds.shared.getADConfig(adUnit: self.placement) { (res: Result<AdUnitObj, Error>) in
                switch res{
                case .success(let data):
                    PBMobileAds.shared.log("Get Config ADInterstitial placement: '\(String(describing: self.placement))' Success")
                    DispatchQueue.main.async{
                        self.adUnitObj = data
                        
                        if PBMobileAds.shared.gdprConfirm && CMPConsentTool().needShowCMP() {
                            let cmp = ShowCMP()
                            cmp.closeDelegate = self
                            cmp.open(self.adUIViewCtr, appName: PBMobileAds.shared.appName)
                        } else {
                            self.preLoad()
                        }
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log("Get Config ADInterstitial placement: '\(String(describing: self.placement))' Fail with Error: \(err.localizedDescription)")
                    break
                }
            }
        } else {
            self.preLoad();
        }
    }
    
    deinit {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' with ConsentStr: \(String(describing: consentStr))")
            self.preLoad()
        }
    }
    
    // MARK: - Preload + Load
    func resetAD() {
        if self.adUnit == nil || self.amInterstitial == nil { return }
        
        self.isFetchingAD = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amInterstitial = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amInterstitial?.load(self.amRequest)
        } else {
            self.isFetchingAD = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                let _ = self.processNoBids()
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' Timeout. Please check your internet connect.")
            }
        }
    }
    
    @objc public func preLoad() {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) | isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil || self.isReady() || self.isFetchingAD { return }
        self.resetAD();
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' is not active or not exist.");
            return
        }
        
        // Check and Set Default
        self.adFormatDefault = ADFormat(rawValue: self.adUnitObj.defaultType)
        if !self.setDefaultBidType && self.adUnitObj.adInfor.count >= 2 {
            self.adFormatDefault = self.adFormatDefault == .vast ? .html : .vast
            self.setDefaultBidType = true
        }
        
        // Set GDPR
        PBMobileAds.shared.setGDPR()
        
        // Get AdInfor
        let isVideo = self.adFormatDefault == ADFormat.vast;
        guard let adInfor = PBMobileAds.shared.getAdInfor(isVideo: isVideo, adUnitObj: self.adUnitObj) else {
            PBMobileAds.shared.log("AdInfor of ADInterstitial Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.log("PreLoad ADInterstitial Placement: '\(String(describing: self.placement))'")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        if isVideo {
            PBMobileAds.shared.log("[ADInterstitial Video] - configId: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            self.adUnit = VideoInterstitialAdUnit(configId: adInfor.configId)
        } else {
            PBMobileAds.shared.log("[ADInterstitial HTML] - configId: '\(adInfor.configId) | adUnitID: \(adInfor.adUnitID)'")
            self.adUnit = InterstitialAdUnit(configId: adInfor.configId)
        }
        
        self.amInterstitial = DFPInterstitial(adUnitID: adInfor.adUnitID)
        self.amInterstitial.delegate = self
        
        self.isFetchingAD = true
        self.adUnit?.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADInterstitial placement '\(String(describing: self.placement))' for DFP: \(resultCode.name())")
            self.handlerResult(resultCode)
        }
    }
    
    @objc public func show() {
        if self.amInterstitial?.isReady == true {
            self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
        } else {
            PBMobileAds.shared.log("ADInterstitial placement '\(String(describing: self.placement))' is not ready to be shown, please call preload() first.")
        }
    }
    
    @objc public func destroy() {
        PBMobileAds.shared.log("Destroy ADInterstitial Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    @objc public func isReady() -> Bool {
        return self.amInterstitial?.isReady == true ? true : false
    }
    
    @objc public func setListener(_ adDelegate : ADInterstitialDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Private FUNC
    func processNoBids() -> Bool {
        if self.adUnitObj.adInfor.count >= 2 && self.adFormatDefault == ADFormat(rawValue: self.adUnitObj.defaultType)  {
            self.setDefaultBidType = false
            self.preLoad()
            
            return true
        } else {
            // Both or .video, .html is no bids -> wait and preload.
            PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' No Bids.")
            return false
        }
    }
    
    // MARK: - Delegate
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        if error.code == Constants.ERROR_NO_FILL {
            if !self.processNoBids() {
                self.isFetchingAD = false
                self.adDelegate?.interstitialLoadFail?(error: "interstitialLoadFail: ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
            }
        } else {
            self.isFetchingAD = false
            PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
            self.adDelegate?.interstitialLoadFail?(error: "interstitialLoadFail: ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        }
    }
    
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        self.isFetchingAD = false
        
        let isReady: String = self.isReady() ? " Ready": " not Ready"
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' \(isReady)")
        self.adDelegate?.interstitialDidReceiveAd?()
    }
    
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillPresentScreen?()
    }
    
    public func interstitialDidFailToPresentScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialDidFailToPresentScreen?()
    }
    
    public func interstitialWillDismissScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillDismissScreen?()
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialDidDismissScreen?()
    }
    
    public func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillDismissScreen?()
    }
}

@objc public protocol ADInterstitialDelegate {
    
    // Called when an interstitial ad request succeeded. Show it at the next transition point in your
    // application such as when transitioning between view controllers.
    @objc optional func interstitialDidReceiveAd()
    
    // Called when an interstitial ad request fail.
    @objc optional func interstitialLoadFail(error: String)
    
    // Called just before presenting an interstitial. After this method finishes the interstitial will
    // animate onto the screen. Use this opportunity to stop animations and save the state of your
    // application in case the user leaves while the interstitial is on screen (e.g. to visit the App
    // Store from a link on the interstitial).
    @objc optional func interstitialWillPresentScreen()
    
    // Called when ad fails to present.
    @objc optional func interstitialDidFailToPresentScreen()
    
    // Called before the interstitial is to be animated off the screen.
    @objc optional func interstitialWillDismissScreen()
    
    // Called just after dismissing an interstitial and it has animated off the screen.
    @objc optional func interstitialDidDismissScreen()
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store). The normal
    // UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately
    // before this.
    @objc optional func interstitialWillLeaveApplication()
    
}
