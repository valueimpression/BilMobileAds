//
//  ADRewarded.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADRewarded: NSObject, GADFullScreenContentDelegate, RewardedAdUnitDelegate {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADRewardedDelegate!
    
    // MARK: AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: RewardedVideoAdUnit!
    private var amRewardedAd: GADRewardedAd!
    
    private var rewardedAdUnit: RewardedAdUnit!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var isFetchingAD: Bool = false
    
    // MARK: - Init + DeInit
    @objc public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement: \(placement) Init")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADRewardedDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Deinit")
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
                    PBMobileAds.shared.log(logType: .info, "ADRewarded placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.preLoad()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADRewarded placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    break
                }
            }
        } else {
            self.preLoad()
        }
    }
    
    func resetAD() {
        self.isFetchingAD = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amRewardedAd?.fullScreenContentDelegate = nil
        self.amRewardedAd = nil
        
        self.rewardedAdUnit?.delegate = nil
        self.rewardedAdUnit = nil
    }
    
    // MARK: - Preload AD
    @objc public func preLoad() {
        PBMobileAds.shared.log(logType: .debug, "ADRewarded Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) |  isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil || self.isReady() || self.isFetchingAD {
            if self.adUnitObj == nil && !self.isFetchingAD {
                PBMobileAds.shared.log(logType: .info, "ADInterstitial placement: \(String(describing: self.placement)) is not ready to preLoad.");
                self.getConfigAD();
                return
            }
            return
        }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count == 0 {
            PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' is not active or not exist.");
            return
        }
        
        // Get AdInfor
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADRewarded Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .info, "[ADRewarded] - configId: '\(adInfor.configId)' | adUnitID: '\(String(describing: adInfor.adUnitID))'")
        
        if(adInfor.adUnitID != nil) {
            self.adUnit = RewardedVideoAdUnit(configId: adInfor.configId)
            
            self.isFetchingAD = true
            self.adUnit.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
                PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADRewarded placement '\(String(describing: self.placement))' for DFP: \(resultCode.name())")
                
                GADRewardedAd.load(withAdUnitID: adInfor.adUnitID!, request: self.amRequest) { [weak self] ad, error in
                    self?.isFetchingAD = false
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        PBMobileAds.shared.log(logType: .debug, "Failed to load rewarded ad with error: \(error.localizedDescription)")
                        self.adDelegate?.rewardedFailedToLoad?(error: "ADRewarded Placement '\(String(describing: self.placement))' Loaded Fail with Error: \(error.localizedDescription)")
                    } else {
                        self.amRewardedAd = ad
                        self.amRewardedAd.fullScreenContentDelegate = self
                        
                        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Loaded Success")
                        self.adDelegate?.rewardedDidReceiveAd?()
                    }
                }
            }
        } else {
            self.rewardedAdUnit = RewardedAdUnit(configID: adInfor.configId)
            self.rewardedAdUnit.delegate = self
            
            self.isFetchingAD = true
            self.rewardedAdUnit.loadAd()
        }
    }
    
    @objc public func show() {
        if self.isReady() {
            self.amRewardedAd?.present(fromRootViewController: self.adUIViewCtr) {
                PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' onUserEarnedReward")
                let reward = self.amRewardedAd.adReward;
                let adRewardedItem = ADRewardedItem(type: reward.type, amount: reward.amount)
                self.adDelegate?.rewardedUserDidEarn?() // rewardedItem: adRewardedItem
            }
            self.rewardedAdUnit?.show(from: self.adUIViewCtr)
        } else {
            PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' is not ready to be shown, please call preload() first.")
        }
    }
    
    @objc public func destroy() {
        PBMobileAds.shared.log(logType: .info, "Destroy ADRewarded Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    @objc public func isReady() -> Bool {
        if (self.amRewardedAd != nil) { return true } // Render ads by GAM
        if (self.self.rewardedAdUnit != nil && self.rewardedAdUnit.isReady) { return true } // Render ads by Prebid Rendering
        return false
    }
    
    @objc public func setListener(_ adDelegate : ADRewardedDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate Prebid Rendering
    public func rewardedAdDidReceiveAd(_ rewardedAd: RewardedAdUnit) {
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Loaded Success")
        self.adDelegate?.rewardedDidReceiveAd?()
    }
    
    public func rewardedAdUserDidEarnReward(_ rewardedAd: RewardedAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '" + placement + "' onUserEarnedReward");
        self.adDelegate?.rewardedUserDidEarn?()
    }
    
    public func rewardedAd(_ rewardedAd: RewardedAdUnit, didFailToReceiveAdWithError error: (Error)?) {
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '" + placement + "' load fail with error: " + error!.localizedDescription);
        self.adDelegate?.rewardedFailedToLoad?(error: error!.localizedDescription);
    }
    
    public func rewardedAdWillPresentAd(_ rewardedAd: RewardedAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '" + placement + "' impression");
        self.adDelegate?.rewardedDidRecordImpression?()
    }
    
    public func rewardedAdDidDismissAd(_ rewardedAd: RewardedAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '" + placement + "' closed");
        self.adDelegate?.rewardedDidDismiss?()
    }
    
    public func rewardedAdDidClickAd(_ rewardedAd: RewardedAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '" + placement + "' clicked");
        self.adDelegate?.rewardedDidRecordClick?()
    }
    
    public func rewardedAdWillLeaveApplication(_ rewardedAd: RewardedAdUnit) {
        
    }
    
    // MARK: - Delegate GAM
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidRecordClick")
        self.adDelegate?.rewardedDidRecordClick?()
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidRecordImpression")
        self.adDelegate?.rewardedDidRecordImpression?()
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidDismissFullScreenContent")
        self.adDelegate?.rewardedDidDismiss?()
        self.amRewardedAd = nil
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.isFetchingAD = false
        
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Fail To Present with error: \(error.localizedDescription)");
        self.adDelegate?.rewardedFailedToPresent?(error: "rewardedFailToPresent: ADRewarded Placement '\(String(describing: self.placement))' error: \(error.localizedDescription)")
    }
}

@objc public protocol ADRewardedDelegate {
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedDidReceiveAd()

    /// Called when an rewarded ad request fail.
    @objc optional func rewardedFailedToLoad(error: String)
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedUserDidEarn() // rewardedItem: ADRewardedItem
    
    /// Tells the delegate that the rewarded ad was clicked.
    @objc optional func rewardedDidRecordClick()
    
    /// Tells the delegate that the rewarded ad was presented.
    @objc optional func rewardedDidRecordImpression()
    
    /// Tells the delegate that the rewarded ad was dismissed.
    @objc optional func rewardedDidDismiss()
    
    /// Tells the delegate that the rewarded ad failed to present.
    @objc optional func rewardedFailedToPresent(error: String)
    
}

public class ADRewardedItem: NSObject {
    var type: String
    var amount: NSDecimalNumber
    
    @objc public init(type: String, amount: NSDecimalNumber) {
        self.type = type
        self.amount = amount
    }
    
    @objc public func getType() -> String {
        return self.type
    }
    
    @objc public func getAmount() -> NSDecimalNumber {
        return self.amount
    }
}
