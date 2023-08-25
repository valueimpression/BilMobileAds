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
public class ADInterstitial: NSObject, GADFullScreenContentDelegate, InterstitialAdUnitDelegate  {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADInterstitialDelegate!
    
    // MARK: AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: InterstitialAdUnit!
    private var amInterstitial: GAMInterstitialAd!
    
    private var interstitialAdUnit: InterstitialRenderingAdUnit!
    
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
    
    func resetAD() {
        self.isFetchingAD = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amInterstitial?.fullScreenContentDelegate = nil
        self.amInterstitial = nil
        
        self.interstitialAdUnit?.delegate = nil
        self.interstitialAdUnit = nil
    }
    
    // MARK: - Preload AD
    @objc public func preLoad() {
        PBMobileAds.shared.log(logType: .debug, "ADInterstitial Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) | isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil || self.isReady() {
            if self.adUnitObj == nil {
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
        
        // Get AdInfor
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADInterstitial Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.log(logType: .info, "PreLoad ADInterstitial Placement: '\(String(describing: self.placement))'")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADInterstitial] - configId: '\(adInfor.configId) | adUnitID: \(String(describing: adInfor.adUnitID))'")
        
        if (adInfor.adUnitID != nil && !adInfor.adUnitID!.isEmpty) {
            self.adUnit = InterstitialAdUnit(configId: adInfor.configId, minWidthPerc: 60, minHeightPerc: 70)
            self.adUnit.adFormats = [.banner, .video]
            
            self.isFetchingAD = true
            self.adUnit?.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
                PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADInterstitial placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
                
                GAMInterstitialAd.load(withAdManagerAdUnitID: adInfor.adUnitID!, request: self?.amRequest) { ad, error in
                    self?.isFetchingAD = false
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        PBMobileAds.shared.log(logType: .debug, "Failed to load interstitial ad with error: \(error.localizedDescription)")
                        self.adDelegate?.interstitialLoadFail?(error: "ADInterstitial Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
                    } else if let ad = ad {
                        self.amInterstitial = ad
                        self.amInterstitial.fullScreenContentDelegate = self
                        self.amInterstitial.paidEventHandler = { adValue in
                            PBMobileAds.shared.log(logType: .info, "ADInterstitial placement '\(String(describing: self.placement))'")
                            let adData = AdData(currencyCode: adValue.currencyCode, precision: adValue.precision.rawValue, microsValue: adValue.value)
                            self.adDelegate?.interstitialPaidEvent?(adData: adData)
                        }
                        
                        self.adDelegate?.interstitialDidReceiveAd?()
                        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' Ready")
                    }
                }
            }
        } else {
            self.interstitialAdUnit = InterstitialRenderingAdUnit(configID: adInfor.configId,
                                              minSizePercentage: CGSize(width: 30, height: 30))
            self.interstitialAdUnit.adFormats = [.banner, .video]
            self.interstitialAdUnit.delegate = self
            
            self.isFetchingAD = true
            self.interstitialAdUnit.loadAd()
        }
    }
    
    @objc public func show() {
        if self.isReady() {
            self.amInterstitial?.present(fromRootViewController: self.adUIViewCtr)
            self.interstitialAdUnit?.show(from: self.adUIViewCtr)
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
        if (self.amInterstitial != nil) { return true } // Render ads by GAM
        if (self.self.interstitialAdUnit != nil && self.interstitialAdUnit.isReady) { return true } // Render ads by Prebid Rendering
        return false
    }
    
    @objc public func setListener(_ adDelegate : ADInterstitialDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate Prebid Rendering
    public func interstitialDidReceiveAd(_ interstitial: InterstitialRenderingAdUnit) {
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '\(String(describing: self.placement))' Loaded Success")
        self.adDelegate?.interstitialDidReceiveAd?()
    }
    
    public func interstitial(_ interstitial: InterstitialRenderingAdUnit, didFailToReceiveAdWithError error: (Error)?) {
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '" + placement + "' load fail with error: " + error!.localizedDescription);
        self.adDelegate?.interstitialLoadFail?(error: error!.localizedDescription);
    }
    
    public func interstitialWillPresentAd(_ interstitial: InterstitialRenderingAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '" + placement + "' impression");
        self.adDelegate?.interstitialDidRecordImpression?()
        
        let bidResponse = interstitial.lastBidResponse
        if (bidResponse != nil) {
            PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '" + self.placement + "'");
            let bidWin = bidResponse?.winningBid
            let adData = AdData(currencyCode: "USD", precision: 3, microsValue: NSDecimalNumber(value: bidWin!.price * 1000))
            self.adDelegate?.interstitialPaidEvent?(adData: adData)
        }
    }
    
    public func interstitialDidDismissAd(_ interstitial: InterstitialRenderingAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '" + placement + "' closed");
        self.adDelegate?.interstitialDidDismiss?()
    }
    
    public func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        PBMobileAds.shared.log(logType: .info, "ADInterstitial Placement '" + placement + "' clicked");
        self.adDelegate?.interstitialDidRecordClick?()
    }
    
    public func interstitialWillLeaveApplication(_ interstitial: InterstitialRenderingAdUnit) {
        
    }
    
    // MARK: - Delegate GAM
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
    
    @objc optional func interstitialPaidEvent(adData: AdData)
}
