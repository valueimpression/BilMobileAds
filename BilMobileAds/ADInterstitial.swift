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
    private var isLoadAfterPreload: Bool = false // Check user gọi load() chưa có AD -> preload và show AD luôn
    private var isFetchingAD: Bool = false // Check có phải đang lấy AD ko
    private var isRecallingPreload: Bool = false // Check đang đợi gọi lại preload
    
    // MARK: - Init + DeInit
    public init(_ adView: UIViewController, placement: String) {
        super.init()
        
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
                        PBMobileAds.shared.log("getADConfig Fail placement: \(String(describing: self.placement))")
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
                        PBMobileAds.shared.log("getADConfig placement: \(String(describing: self.placement)) Fail \(err.localizedDescription)")
                        break
                    }
                }
            } else {
                self.preLoad();
            }
        }
    }
    
    deinit {
        PBMobileAds.shared.log("AD Interstitial Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ConsentStr: \(String(describing: consentStr))")
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
    
    func handerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amInterstitial?.load(self.amRequest)
        } else {
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
            
            self.isFetchingAD = false
        }
    }
    
    public func preLoad() {
        PBMobileAds.shared.log(" | isReady: \(self.isReady()) |  isFetchingAD: \(self.isFetchingAD) | |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isReady() == true || self.isFetchingAD == true || self.isRecallingPreload == true { return }
        
        PBMobileAds.shared.log("Preload Interstitial AD")
        
        // Get Data Config
        if self.adUnitObj == nil {
            guard let adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement) else {
                PBMobileAds.shared.log("Placement is not exist")
                return
            }
            
            self.adUnitObj = adUnitObj
        }
        
        // Check Active
        if !self.adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("Ad is not actived")
            return
        }
        
        // Check and set default
        self.adFormatDefault = self.adFormatDefault == nil ? ADFormat(rawValue: self.adUnitObj.defaultType) : self.adFormatDefault
        // set adformat theo loại duy nhất có
        if self.adUnitObj.adInfor.count < 2 {
            self.adFormatDefault = self.adUnitObj.adInfor[0].isVideo ? .vast : .html
        }
        
        // Set GDPR
        if PBMobileAds.shared.gdprConfirm {
            Targeting.shared.subjectToGDPR = true
            Targeting.shared.gdprConsentString = CMPConsentToolAPI().consentString
        }
        
        let adInfor: AdInfor
        if self.adFormatDefault == .vast {
            guard let infor = self.getAdInfor(isVideo: true) else {
                PBMobileAds.shared.log("AdInfor is not exist")
                return
            }
            adInfor = infor
            
            PBMobileAds.shared.setupPBS(host: adInfor.host)
            PBMobileAds.shared.log("[Full Video] - configId: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            
            let parameters = VideoBaseAdUnit.Parameters()
            parameters.mimes = ["video/mp4"]
            parameters.protocols = [Signals.Protocols.VAST_2_0]
            parameters.playbackMethod = [Signals.PlaybackMethod.AutoPlaySoundOn]
            parameters.placement = Signals.Placement.Interstitial // Signals.Placement.InBanner
            
            let vAdUnit = VideoInterstitialAdUnit(configId: adInfor.configId)
            vAdUnit.parameters = parameters
            
            self.adUnit = vAdUnit
        } else {
            guard let infor = self.getAdInfor(isVideo: false) else {
                PBMobileAds.shared.log("AdInfor is not exist")
                return
            }
            adInfor = infor
            
            PBMobileAds.shared.setupPBS(host: adInfor.host)
            PBMobileAds.shared.log("[Full Simple] - configId: '\(adInfor.configId) | adUnitID: \(adInfor.adUnitID)'")
            self.adUnit = InterstitialAdUnit(configId: adInfor.configId)
        }
        
        self.amInterstitial = DFPInterstitial(adUnitID: adInfor.adUnitID)
        self.amInterstitial.delegate = self
        
        self.isFetchingAD = true
        self.adUnit?.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch for DFP \(resultCode.name()) | placement: \(String(describing: self.placement))")
            self.handerResult(resultCode)
        }
    }
    
    public func load() {
        if self.amInterstitial?.isReady == true {
            self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
        } else {
            PBMobileAds.shared.log("Don't have AD")
            self.isLoadAfterPreload = true
            self.preLoad()
        }
    }
    
    public func destroy() {
        // if self.isLoadBannerSucc {
        PBMobileAds.shared.log("Destroy Placement: \(String(describing: self.placement))")
        self.isLoadAfterPreload = false
        self.adUnit?.stopAutoRefresh()
        // }
    }
    
    public func isReady() -> Bool {
        return self.amInterstitial?.isReady == true ? true : false
    }
    
    // MARK: - Delegate
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        // Đã gọi lên ad server nhưng fail
        self.isFetchingAD = false
        // Gọi Load() trước nhưng fail
        self.isLoadAfterPreload = false
        
        PBMobileAds.shared.log(error.localizedDescription)
        self.adDelegate?.interstitialLoadFail?(data: error.localizedDescription)
    }
    
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        // Đã gọi lên ad server succ
        self.isFetchingAD = false
        
        if self.amInterstitial?.isReady == true {
            PBMobileAds.shared.log("Ad Interstitial Ready with placement \(String(describing: self.placement))")
            self.adDelegate?.interstitialDidReceiveAd?(data: self.placement)
            
            if self.isLoadAfterPreload {
                self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
                self.isLoadAfterPreload = false
            }
        } else {
            self.isLoadAfterPreload = false
            
            PBMobileAds.shared.log("Ad Interstitial Not Ready")
            self.adDelegate?.interstitialDidReceiveAd?(data: "Ad Interstitial Not Ready")
        }
    }
    
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("Ad Interstitial Will Present")
        self.adDelegate?.interstitialWillPresentScreen?(data: "AD Interstitial Will Present")
    }
    
    public func interstitialDidFailToPresentScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("Ad Interstitial Show Fail")
        self.adDelegate?.interstitialDidFailToPresentScreen?(data: "AD Interstitial Show Fail")
    }
    
    public func interstitialWillDismissScreen(toPresentScreen ad: GADInterstitial) {
        PBMobileAds.shared.log("Ad Interstitial Will Dismiss")
        self.adDelegate?.interstitialWillDismissScreen?(data: "AD Interstitial Will Dismiss")
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("Ad Interstitial Dismissed")
        self.adDelegate?.interstitialDidDismissScreen?(data: "AD Interstitial Dismissed")
    }
    
    public func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        PBMobileAds.shared.log("Ad Interstitial Leave Application")
        self.adDelegate?.interstitialWillLeaveApplication?(data: "AD Interstitial Leave Application")
    }
}

@objc public protocol ADInterstitialDelegate {
    
    // Called when an interstitial ad request succeeded. Show it at the next transition point in your
    // application such as when transitioning between view controllers.
    @objc optional func interstitialDidReceiveAd(data: String)
    
    // Called when an interstitial ad request fail.
    @objc optional func interstitialLoadFail(data: String)
    
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
