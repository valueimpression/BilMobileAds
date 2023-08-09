//
//  ADRewarded.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADRewarded: NSObject, GADFullScreenContentDelegate {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADRewardedDelegate!
    
    // MARK: AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: RewardedVideoAdUnit!
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
        
        //        let parameters = VideoParameters(mimes: ["video/x-flv", "video/mp4"])
        //        parameters.protocols = [Signals.Protocols.VAST_2_0]
        //        parameters.playbackMethod = [Signals.PlaybackMethod.AutoPlaySoundOff]
        //        self.adUnit.videoParameters = parameters
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADRewarded placement '\(String(describing: self.placement))' for DFP: \(resultCode.name())")
            
            if resultCode == .prebidDemandFetchSuccess {
                GADRewardedAd.load(withAdUnitID: adInfor.adUnitID, request: self.amRequest) { [weak self] ad, error in
                    self?.isFetchingAD = false
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        PBMobileAds.shared.log(logType: .debug, "Failed to load rewarded ad with error: \(error.localizedDescription)")
                        self.adDelegate?.rewardedFailedToLoad?(error: "ADRewarded Placement '\(String(describing: self.placement))' Loaded Fail with Error: \(error.localizedDescription)")
                    } else {
                        self.amRewardedAd = ad
                        self.amRewardedAd.fullScreenContentDelegate = self
                        
                        self.adDelegate?.rewardedDidReceiveAd?()
                        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Loaded Success")
                    }
                }
            } else {
                self.isFetchingAD = false
                
                if resultCode == .prebidDemandNoBids {
                    PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' No Bids.")
                } else if resultCode == .prebidDemandTimedOut {
                    PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' Timeout. Please check your internet connect.")
                }
            }
        }
    }
    
    @objc public func show(){
        if self.amRewardedAd != nil {
            self.amRewardedAd.present(fromRootViewController: self.adUIViewCtr) {
                let reward = self.amRewardedAd.adReward;
                let adRewardedItem = ADRewardedItem(type: reward.type, amount: reward.amount)
                self.adDelegate?.rewardedUserDidEarn?(rewardedItem: adRewardedItem)
            }
        } else {
            PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' is not ready to be shown, please call preload() first.")
        }
    }
    
    @objc public func destroy(){
        PBMobileAds.shared.log(logType: .info, "Destroy ADRewarded Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    @objc public func isReady() -> Bool {
        return self.amRewardedAd != nil ? true : false
    }
    
    @objc public func setListener(_ adDelegate : ADRewardedDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidRecordClick")
        self.adDelegate?.rewardedDidRecordClick?()
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidRecordImpression")
        self.adDelegate?.rewardedDidRecordImpression?()
        self.amRewardedAd = nil
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADRewarded Placement '\(String(describing: self.placement))' adDidDismissFullScreenContent")
        self.adDelegate?.rewardedDidDismiss?()
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
    @objc optional func rewardedUserDidEarn(rewardedItem: ADRewardedItem)
    
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
