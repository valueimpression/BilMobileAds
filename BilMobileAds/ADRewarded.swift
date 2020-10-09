//
//  ADRewarded.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADRewarded: NSObject, GADRewardedAdDelegate, CloseListenerDelegate {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADRewardedDelegate!
    
    // MARK: AD OBJ
    private let amRequest = DFPRequest()
    private var adUnit: AdUnit!
    private var amRewardedAd: GADRewardedAd!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var isLoadAfterPreload: Bool = false
    private var isFetchingAD: Bool = false
    private var isRecallingPreload: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADRewarded Init: \(placement)")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADRewardedDelegate
        
        self.placement = placement
        
        // Get AdUnit
        if (self.adUnitObj == nil) {
            self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement);
            if (self.adUnitObj == nil) {
                PBMobileAds.shared.getADConfig(adUnit: self.placement) { (res: Result<AdUnitObj, Error>) in
                    switch res{
                    case .success(let data):
                        PBMobileAds.shared.log("Get Config ADRewarded placement: '\(String(describing: self.placement))' Success")
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
                        PBMobileAds.shared.log("Get Config ADRewarded placement: '\(String(describing: self.placement))' Fail with Error: \(err.localizedDescription)")
                        break
                    }
                }
            } else {
                self.preLoad();
            }
        }
    }
    
    deinit {
        PBMobileAds.shared.log("ADRewarded Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ADRewarded Placement '\(String(describing: self.placement))' with ConsentStr: \(String(describing: consentStr))")
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
        if self.adUnit == nil || self.amRewardedAd == nil { return }

        self.isFetchingAD = false
        self.isRecallingPreload = false
        self.isLoadAfterPreload = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amRewardedAd = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amRewardedAd.load(self.amRequest){ error in
                self.isFetchingAD = false
                
                if let error = error {
                    PBMobileAds.shared.log("Load ADRewarded Placement: '\(String(describing: self.placement))' Failed with Error: \(error.localizedDescription)")
                    if !self.isLoadAfterPreload { self.deplayCallPreload() }
                } else {
                    PBMobileAds.shared.log("Load ADRewarded Placement: '\(String(describing: self.placement))' Success")
                    if self.isLoadAfterPreload {
                        if self.amRewardedAd?.isReady == true {
                            self.amRewardedAd?.present(fromRootViewController: self.adUIViewCtr, delegate: self)
                        }
                        self.isLoadAfterPreload = false
                    }
                }
            }
        } else {
            self.isFetchingAD = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
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
        PBMobileAds.shared.log("ADRewarded Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) |  isFetchingAD: \(self.isFetchingAD) |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isReady() == true || self.isFetchingAD == true || self.isRecallingPreload == true { return }
        self.resetAD();
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADRewarded Placement '\(String(describing: self.placement))' is not active or not exist");
            return
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
        guard let adInfor = self.getAdInfor(isVideo: true) else {
            PBMobileAds.shared.log("AdInfor of ADRewarded Placement '" + self.placement + "' is not exist");
            return
        }
        
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log("[ADRewarded] - configId: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
        self.adUnit = RewardedVideoAdUnit(configId: adInfor.configId)
        self.amRewardedAd = GADRewardedAd(adUnitID: adInfor.adUnitID)
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADRewarded placement '\(String(describing: self.placement))' for DFP: \(resultCode.name())")
            self.handlerResult(resultCode)
        }
    }
    
    public func load(){
        if self.amRewardedAd?.isReady == true {
            self.amRewardedAd?.present(fromRootViewController: self.adUIViewCtr, delegate: self)
        } else {
            PBMobileAds.shared.log("ADRewarded Placement '\(String(describing: self.placement))' don't have AD")
            self.isLoadAfterPreload = true
            self.preLoad()
        }
    }
    
    public func destroy(){
        PBMobileAds.shared.log("Destroy ADRewarded Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    public func isReady() -> Bool {
        return self.amRewardedAd?.isReady == true ? true : false
    }
    
    public func setListener(_ adDelegate : ADRewardedDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    public func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        PBMobileAds.shared.log("ADRewarded received with currency: \(reward.type), amount \(reward.amount).")
        
        PBMobileAds.shared.log("rewardedDidReceiveAd: ADRewarded Placement '\(String(describing: self.placement))'")
        self.adDelegate?.rewardedDidReceiveAd?(data: "rewardedDidReceiveAd: ADRewarded Placement '\(String(describing: self.placement))'")
    }
    
    public func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log("rewardedAdDidPresent: ADRewarded Placement '\(String(describing: self.placement))'")
        self.adDelegate?.rewardedDidPresent?(data: "rewardedAdDidPresent: ADRewarded Placement '\(String(describing: self.placement))'")
    }
    
    public func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log("rewardedAdDidDismiss: ADRewarded Placement '\(String(describing: self.placement))'")
        self.adDelegate?.rewardedDidDismiss?(data: "rewardedAdDidDismiss: ADRewarded Placement '\(String(describing: self.placement))'")
    }
    
    public func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        // Đã gọi lên ad server nhưng fail
        self.isFetchingAD = false
        // Gọi Load() trước nhưng fail
        self.isLoadAfterPreload = false
        
        PBMobileAds.shared.log("rewardedFailToLoad: ADRewarded Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)");
        self.adDelegate?.rewardedFailToLoad?(data: "rewardedFailToLoad: ADRewarded Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
}

@objc public protocol ADRewardedDelegate {
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedDidReceiveAd(data: String)
    
    // Called when an interstitial ad request fail.
    @objc optional func rewardedFailToLoad(data: String)
    
    /// Tells the delegate that the rewarded ad failed to present.
    @objc optional func rewardedFailToPresent(data: String)
    
    /// Tells the delegate that the rewarded ad was presented.
    @objc optional func rewardedDidPresent(data: String)
    
    /// Tells the delegate that the rewarded ad was dismissed.
    @objc optional func rewardedDidDismiss(data: String)
    
}

