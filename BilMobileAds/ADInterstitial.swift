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
    private var adFormatDefault: ADFormat!;
    private var isLoadAfterPreload: Bool = false
    private var isFetchingAD: Bool = false
    private var isRecallingPreload: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADInterstitial Init: \(placement)")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADInterstitialDelegate
        
        self.placement = placement
        
        // Get AdUnit
        if (self.adUnitObj == nil) {
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
    func deplayCallPreload() {
        self.isRecallingPreload = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.INTERSTITIAL_RECALL_DEFAULT) {
            self.isRecallingPreload = false
            self.preLoad()
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
        if self.adUnit == nil || self.amInterstitial == nil { return }

        self.isFetchingAD = false
        self.isRecallingPreload = false
        self.isLoadAfterPreload = false
        
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
                self.adFormatDefault = self.adFormatDefault == .html ? .vast : .html
                // Ko gọi lại preload nếu user gọi load() đầu tiên
                if !self.isLoadAfterPreload {
                    self.deplayCallPreload()
                }
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                if !self.isLoadAfterPreload {
                    self.deplayCallPreload()
                }
            }
        }
    }
    
    public func preLoad() {
        PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) |  isFetchingAD: \(self.isFetchingAD) |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isReady() == true || self.isFetchingAD == true || self.isRecallingPreload == true { return }
        self.resetAD();
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADInterstitial Placement '\(String(describing: self.placement))' is not active or not exist");
            return
        }
        
        // Check and set default
        self.adFormatDefault = ADFormat(rawValue: adUnitObj.defaultType)
        // set adformat theo loại duy nhất có
        if adUnitObj.adInfor.count < 2 {
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
            PBMobileAds.shared.log("AdInfor of ADInterstitial Placement '" + self.placement + "' is not exist");
            return
        }

        PBMobileAds.shared.log("Load ADInterstitial Placement: '\(String(describing: self.placement))'")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        if self.adFormatDefault == .vast {
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
    
    public func load() {
        if self.amInterstitial?.isReady == true {
            self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
        } else {
            PBMobileAds.shared.log("ADInterstitial placement '\(String(describing: self.placement))' don't have AD")
            self.isLoadAfterPreload = true
            self.preLoad()
        }
    }
    
    public func destroy() {
        PBMobileAds.shared.log("Destroy ADInterstitial Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    public func isReady() -> Bool {
        return self.amInterstitial?.isReady == true ? true : false
    }
    
    public func setListener(_ adDelegate : ADInterstitialDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        // Đã gọi lên ad server nhưng fail
        self.isFetchingAD = false
        // Gọi Load() trước nhưng fail
        self.isLoadAfterPreload = false
        
        PBMobileAds.shared.log("interstitialLoadFail: ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adDelegate?.interstitialLoadFail?(error: "interstitialLoadFail: ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        // Đã gọi lên ad server succ
        self.isFetchingAD = false
        
        if self.amInterstitial?.isReady == true {
            PBMobileAds.shared.log("interstitialDidReceiveAd: ADInterstitial Placement '\(String(describing: self.placement))' Ready")
            self.adDelegate?.interstitialDidReceiveAd?(data: "interstitialDidReceiveAd: ADInterstitial Placement '\(String(describing: self.placement))' Ready")
            
            if self.isLoadAfterPreload {
                self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
                self.isLoadAfterPreload = false
            }
        } else {
            self.isLoadAfterPreload = false
            
            PBMobileAds.shared.log("interstitialDidReceiveAd: ADInterstitial Placement '\(String(describing: self.placement))' not Ready");
            self.adDelegate?.interstitialDidReceiveAd?(data: "interstitialDidReceiveAd: ADInterstitial Placement '\(String(describing: self.placement))' not Ready")
        }
    }
    
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("interstitialWillPresentScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillPresentScreen?(data: "interstitialWillPresentScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
    }
    
    public func interstitialDidFailToPresentScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("interstitialDidFailToPresentScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialDidFailToPresentScreen?(data: "interstitialDidFailToPresentScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
    }
    
    public func interstitialWillDismissScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("interstitialWillDismissScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillDismissScreen?(data: "interstitialWillDismissScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("interstitialDidDismissScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialDidDismissScreen?(data: "interstitialDidDismissScreen: ADInterstitial Placement '\(String(describing: self.placement))'")
    }
    
    public func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("interstitialWillLeaveApplication: ADInterstitial Placement '\(String(describing: self.placement))'")
        self.adDelegate?.interstitialWillDismissScreen?(data: "interstitialWillLeaveApplication: ADInterstitial Placement '\(String(describing: self.placement))'")
    }
}

@objc public protocol ADInterstitialDelegate {
    
    // Called when an interstitial ad request succeeded. Show it at the next transition point in your
    // application such as when transitioning between view controllers.
    @objc optional func interstitialDidReceiveAd(data: String)
    
    // Called when an interstitial ad request fail.
    @objc optional func interstitialLoadFail(error: String)
    
    // Called just before presenting an interstitial. After this method finishes the interstitial will
    // animate onto the screen. Use this opportunity to stop animations and save the state of your
    // application in case the user leaves while the interstitial is on screen (e.g. to visit the App
    // Store from a link on the interstitial).
    @objc optional func interstitialWillPresentScreen(data: String)
    
    // Called when ad fails to present.
    @objc optional func interstitialDidFailToPresentScreen(data: String)
    
    // Called before the interstitial is to be animated off the screen.
    @objc optional func interstitialWillDismissScreen(data: String)
    
    // Called just after dismissing an interstitial and it has animated off the screen.
    @objc optional func interstitialDidDismissScreen(data: String)
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store). The normal
    // UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately
    // before this.
    @objc optional func interstitialWillLeaveApplication(data: String)
    
}
