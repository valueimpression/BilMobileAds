//
//  ADInterstitial.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

//GADInterstitialDelegate
public class ADInterstitial: NSObject, GADFullScreenContentDelegate  {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADInterstitialDelegate!
    
    // MARK: AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: InterstitialAdUnit!
    private var amInterstitial: GAMInterstitialAd!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var adFormatDefault: ADFormat!
    private var isFetchingAD: Bool = false
    private var setDefaultBidType: Bool = true
    
    // MARK: - Init + DeInit
    @objc public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement: \(placement) Init")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADInterstitialDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' Deinit")
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
                    PBMobileAds.shared.log(logType: .info, "ADInterstitial placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.preLoad()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADInterstitial placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    break
                }
            }
        } else {
            self.preLoad()
        }
    }
    
    func processNoBids() -> Bool {
        if self.adUnitObj.adInfor.count >= 2 && self.adFormatDefault == ADFormat(rawValue: self.adUnitObj.defaultType) {
            self.setDefaultBidType = false
            self.preLoad()
            return true
        } else {
            // Both or .video, .html is no bids -> wait and preload.
            PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' No Bids.")
            return false
        }
    }
    
    func resetAD() {
        if self.adUnit == nil || self.amInterstitial == nil { return }
        
        self.isFetchingAD = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amInterstitial = nil
    }
    
    // MARK: - Preload AD
    @objc public func preLoad() {
        PBMobileAds.shared.log(logType: .debug, "ADInterstitial Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) | isFetchingAD: \(self.isFetchingAD)")
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
            PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' is not active or not exist.");
            return
        }
        
//        // Check and Set Default
//        self.adFormatDefault = ADFormat(rawValue: self.adUnitObj.defaultType)
//        if !self.setDefaultBidType && self.adUnitObj.adInfor.count >= 2 {
//            self.adFormatDefault = self.adFormatDefault == .vast ? .html : .vast
//            self.setDefaultBidType = true
//        }
        
        // Get AdInfor
//        let isVideo = self.adFormatDefault == ADFormat.vast;
//        guard let adInfor = PBMobileAds.shared.getAdInfor(isVideo: isVideo, adUnitObj: self.adUnitObj) else {
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADInterstitial Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.log(logType: .info, "PreLoad ADInterstitial Placement: '\(String(describing: self.placement))'")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        
        PBMobileAds.shared.log(logType: .debug, "[ADInterstitial] - configId: '\(adInfor.configId) | adUnitID: \(adInfor.adUnitID)'")
        self.adUnit = InterstitialAdUnit(configId: adInfor.configId, minWidthPerc: 60, minHeightPerc: 70)
        self.adUnit.adFormats = [.banner, .video]
        
//        let parameters = VideoParameters(mimes: ["video/x-flv", "video/mp4"])
//        parameters.protocols = [Signals.Protocols.VAST_2_0]
//        parameters.playbackMethod = [Signals.PlaybackMethod.AutoPlaySoundOff]
//        self.adUnit.videoParameters = parameters

        self.isFetchingAD = true
        self.adUnit?.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADInterstitial placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            
            GAMInterstitialAd.load(withAdManagerAdUnitID: adInfor.adUnitID, request: self?.amRequest) { ad, error in
                self?.isFetchingAD = false
                
                guard let self = self else { return }
                
                if let error = error {
                    PBMobileAds.shared.log(logType: .debug, "Failed to load interstitial ad with error: \(error.localizedDescription)")
                    self.adDelegate?.interstitialLoadFail?(error: "ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
                } else if let ad = ad {
                    self.amInterstitial = ad
                    self.amInterstitial.fullScreenContentDelegate = self
                    
                    self.adDelegate?.interstitialDidReceiveAd?()
                    PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' Ready")
                }
            }
            
//            if resultCode == .prebidDemandFetchSuccess {
//
//            } else {
//                self?.isFetchingAD = false
//
//                if resultCode == .prebidDemandNoBids {
//                    let _ = self?.processNoBids()
//                } else if resultCode == .prebidDemandTimedOut {
//                    PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self?.placement))' Timeout. Please check your internet connect.")
//                }
//            }
        }
    }
    
    @objc public func show() {
        if self.amInterstitial != nil {
            self.amInterstitial.present(fromRootViewController: self.adUIViewCtr)
        } else {
            PBMobileAds.shared.log(logType: .info, "ADInterstitial placement '\(String(describing: self.placement))' is not ready to be shown, please call preload() first.")
        }
    }
    
    @objc public func destroy() {
        PBMobileAds.shared.log(logType: .info, "Destroy ADInterstitial Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    @objc public func isReady() -> Bool {
        return self.amInterstitial != nil ? true : false
    }
    
    @objc public func setListener(_ adDelegate : ADInterstitialDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' adDidRecordClick")
        self.adDelegate?.interstitialDidRecordClick?()
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' adDidRecordImpression")
        self.adDelegate?.interstitialDidRecordImpression?()
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' adDidDismissFullScreenContent")
        self.adDelegate?.interstitialDidDismiss?()
        self.amInterstitial = nil
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.isFetchingAD = false
        
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' Fail To With Error: \(error.localizedDescription)")
        self.adDelegate?.interstitialLoadFail?(error: "ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
}

@objc public protocol ADInterstitialDelegate {
    
    @objc optional func interstitialDidRecordClick()
    
    @objc optional func interstitialDidRecordImpression()
    
    @objc optional func interstitialDidDismiss()
    
    // Called when an interstitial ad request succeeded. Show it at the next transition point in your
    // application such as when transitioning between view controllers.
    @objc optional func interstitialDidReceiveAd()
    
    // Called when an interstitial ad request fail.
    @objc optional func interstitialLoadFail(error: String)
}
