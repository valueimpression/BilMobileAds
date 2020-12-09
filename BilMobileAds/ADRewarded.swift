//
//  ADRewarded.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADRewarded: NSObject, GADRewardedAdDelegate {
    
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
        if self.adUnit == nil || self.amRewardedAd == nil { return }
        
        self.isFetchingAD = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amRewardedAd = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amRewardedAd?.load(self.amRequest){ error in
                self.isFetchingAD = false

                if let error = error {
                    PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Loaded Fail with Error: \(error.localizedDescription)")
                    self.adDelegate?.rewardedFailedToLoad?(error: "rewardedFailedToLoad: ADRewarded Placement '\(String(describing: self.placement))' Loaded Fail with Error: \(error.localizedDescription)")
                } else {
                    PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Loaded Success")
                    self.adDelegate?.rewardedDidReceiveAd?()
                }
            }
        } else {
            self.isFetchingAD = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' No Bids.")
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Timeout. Please check your internet connect.")
            }
        }
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
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' is not active or not exist.");
            return
        }
        
        // Get AdInfor
        let isVideo = ADFormat(rawValue: self.adUnitObj.defaultType) == ADFormat.vast;
        guard let adInfor = PBMobileAds.shared.getAdInfor(isVideo: isVideo, adUnitObj: self.adUnitObj) else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADRewarded Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADRewarded] - configId: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
        self.adUnit = RewardedVideoAdUnit(configId: adInfor.configId)
        self.amRewardedAd = GADRewardedAd(adUnitID: adInfor.adUnitID)
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADRewarded placement '\(String(describing: self.placement))' for DFP: \(resultCode.name())")
            self.handlerResult(resultCode)
        }
    }
    
    @objc public func show(){
        if self.amRewardedAd?.isReady == true {
            self.amRewardedAd?.present(fromRootViewController: self.adUIViewCtr, delegate: self)
        } else {
            PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' is not ready to be shown, please call preload() first.")
        }
    }
    
    @objc public func destroy(){
        PBMobileAds.shared.log(logType: .info, "Destroy ADRewarded Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    @objc public func isReady() -> Bool {
        return self.amRewardedAd?.isReady == true ? true : false
    }
    
    @objc public func setListener(_ adDelegate : ADRewardedDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    public func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded received with type: \(reward.type), amount \(reward.amount).")
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))'")
        
        let adRewardedItem = ADRewardedItem(type: reward.type, amount: reward.amount)
        self.adDelegate?.rewardedUserDidEarn?(rewardedItem: adRewardedItem)
    }
    
    public func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))'")
        self.adDelegate?.rewardedDidPresent?()
    }
    
    public func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))'")
        self.adDelegate?.rewardedDidDismiss?()
    }
    
    public func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Fail To Present with error: \(error.localizedDescription)");
        self.adDelegate?.rewardedFailedToPresent?(error: "rewardedFailToPresent: ADRewarded Placement '\(String(describing: self.placement))' error: \(error.localizedDescription)")
    }
}

@objc public protocol ADRewardedDelegate {
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedDidReceiveAd()
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedUserDidEarn(rewardedItem: ADRewardedItem)
    
    /// Called when an rewarded ad request fail.
    @objc optional func rewardedFailedToLoad(error: String)
    
    /// Tells the delegate that the rewarded ad failed to present.
    @objc optional func rewardedFailedToPresent(error: String)
    
    /// Tells the delegate that the rewarded ad was presented.
    @objc optional func rewardedDidPresent()
    
    /// Tells the delegate that the rewarded ad was dismissed.
    @objc optional func rewardedDidDismiss()
    
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
