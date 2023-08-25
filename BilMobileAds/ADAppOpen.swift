//
//  ADAppOpen.swift
//  BilMobileAds
//
//  Created by HNL on 16/08/2023.
//  Copyright © 2023 bil. All rights reserved.
//

import GoogleMobileAds

public class ADAppOpen: NSObject, GADFullScreenContentDelegate {
    
    // MARK: AD View
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADAppOpenDelegate!
    
    // MARK: AD OBJ
    private let amRequest = GAMRequest()
    private var appOpenAd: GADAppOpenAd!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var adFormatDefault: ADFormat!
    private var isFetchingAD: Bool = false
    private var isLoadingAd: Bool = false
    private var isShowingAd: Bool = false
    
    private var loadTime: Double = 0;
    
    // MARK: - Init + DeInit
    @objc public init(_ adView: UIViewController, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement: \(placement) Init")
        
        self.adUIViewCtr = adView
        self.adDelegate = adView as? ADAppOpenDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' Deinit")
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
                    PBMobileAds.shared.log(logType: .info, "ADAppOpen placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.preLoad()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADAppOpen placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    break
                }
            }
        } else {
            self.preLoad()
        }
    }
    
    func resetAD() {
        if self.appOpenAd == nil { return }
        
        self.loadTime = 0
        
        self.isLoadingAd = false
        self.isShowingAd = false
        self.isFetchingAD = false
        
        self.appOpenAd = nil
    }
    
    // MARK: - Preload AD
    @objc public func preLoad() {
        PBMobileAds.shared.log(logType: .debug, "ADAppOpen Placement '\(String(describing: self.placement))' - isReady: \(self.isReady()) | isFetchingAD: \(self.isFetchingAD)")
        if self.adUnitObj == nil || self.isReady() {
            if self.adUnitObj == nil {
                PBMobileAds.shared.log(logType: .info, "ADAppOpen placement: \(String(describing: self.placement)) is not ready to preLoad.");
                self.getConfigAD();
                return
            }
            return
        }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count == 0 {
            PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' is not active or not exist.");
            return
        }
        
        // Get AdInfor
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADAppOpen Placement '" + self.placement + "' is not exist.");
            return
        }
        
        PBMobileAds.shared.log(logType: .info, "PreLoad ADAppOpen Placement: '\(String(describing: self.placement))'")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADAppOpen] - configId: '\(adInfor.configId) | adUnitID: \(String(describing: adInfor.adUnitID))'")
        
        self.isLoadingAd = true
        GADAppOpenAd.load(withAdUnitID: adInfor.adUnitID!, request: self.amRequest) { ad, error in
            self.isLoadingAd = false
            
            if let error = error {
                self.loadTime = 0;
                self.appOpenAd = nil;
                
                PBMobileAds.shared.log(logType: .debug, "Failed to load ADAppOpen ad with error: \(error.localizedDescription)")
                self.adDelegate?.appOpenAdLoadFail?(error: "ADAppOpen Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
                return
            }
            
            self.loadTime = self.getDateNow()
            self.appOpenAd = ad
            self.appOpenAd.fullScreenContentDelegate = self
            self.appOpenAd.paidEventHandler = { adValue in
                PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '" + self.placement + "'");
                let adData = AdData(currencyCode: adValue.currencyCode, precision: adValue.precision.rawValue, microsValue: adValue.value)
                self.adDelegate?.appOpenOnPaidEvent?(adData: adData)
            }
            
            self.adDelegate?.appOpenAdDidReceiveAd?()
            PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' Ready")
        }
    }
    
    @objc public func show() {
        // If the app open ad is already showing, do not show the ad again.
        if (self.isShowingAd) {
            PBMobileAds.shared.log(logType: .info, "ADAppOpen placement '\(String(describing: self.placement))' is already showing")
            return;
        }

        // If the app open ad is not available yet, invoke the callback then load the ad.
        if (!self.isReady()) {
            PBMobileAds.shared.log(logType: .info, "ADAppOpen placement '\(String(describing: self.placement))' currently unavailable, call preLoad() first")
            return;
        }
        
        self.isShowingAd = true
        self.appOpenAd.present(fromRootViewController: self.adUIViewCtr)
    }
    
    @objc public func destroy() {
        PBMobileAds.shared.log(logType: .info, "Destroy ADAppOpen Placement: \(String(describing: self.placement))")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    @objc public func isReady() -> Bool {
        return self.appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(4) ? true : false
    }
    
    private func wasLoadTimeLessThanNHoursAgo(_ numHours: Int) -> Bool {
        let dateDifference = self.getDateNow() - self.loadTime
        let numMilliSecondsPerHour: Double = 3600000
        return dateDifference < (numMilliSecondsPerHour * Double(numHours))
    }
    
    func getDateNow() -> Double {
        return Double(Int64(Date().timeIntervalSince1970 * 1000))
    }
    
    @objc public func setListener(_ adDelegate : ADAppOpenDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Delegate
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' adDidRecordClick")
        self.adDelegate?.appOpenAdDidRecordClick?()
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' adDidRecordImpression")
        self.adDelegate?.appOpenAdDidRecordImpression?()
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' adDidDismissFullScreenContent")
        self.adDelegate?.appOpenAdDidDismiss?()
        self.appOpenAd = nil
        self.isShowingAd = false
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.appOpenAd = nil
        self.isShowingAd = false
        PBMobileAds.shared.log(logType: .info, "ADAppOpen Placement '\(String(describing: self.placement))' Fail To With Error: \(error.localizedDescription)")
        self.adDelegate?.appOpenAdLoadFail?(error: "ADAppOpen Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
}

@objc public protocol ADAppOpenDelegate {
    
    @objc optional func appOpenAdDidRecordClick()
    
    @objc optional func appOpenAdDidRecordImpression()
    
    @objc optional func appOpenAdDidDismiss()
    
    // Called when an appOpenAd ad request succeeded. Show it at the next transition point in your
    // application such as when transitioning between view controllers.
    @objc optional func appOpenAdDidReceiveAd()
    
    // Called when an appOpenAd ad request fail.
    @objc optional func appOpenAdLoadFail(error: String)
    
    @objc optional func appOpenOnPaidEvent(adData: AdData)
}
