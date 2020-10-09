//
//  ADBanner.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class ADBanner : NSObject, GADBannerViewDelegate, CloseListenerDelegate {
    
    // MARK: - View OBJ
    weak var appBannerView: UIView!
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADBannerDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = DFPRequest()
    private var adUnit: AdUnit!
    private var amBanner: DFPBannerView!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    private var defaultAnchor: Anchor!
    private var adFormatDefault: ADFormat!
    private var curBannerSize: MyBannerSize!
    private var timeAutoRefesh: Double = Constants.BANNER_AUTO_REFRESH_DEFAULT
    private var isLoadBannerSucc: Bool = false
    private var isRecallingPreload: Bool = false
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, view adView: UIView, placement: String) {
        super.init()
        PBMobileAds.shared.log("ADBanner Init: \(placement)")
        
        self.defaultAnchor = .Center
        
        self.adUIViewCtr = adUIViewCtr
        self.appBannerView = adView
        self.adDelegate = adUIViewCtr as? ADBannerDelegate
        
        self.placement = placement
        
        // Get AdUnit
        if (self.adUnitObj == nil) {
            self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement);
            if (self.adUnitObj == nil) {
                PBMobileAds.shared.getADConfig(adUnit: self.placement) { (res: Result<AdUnitObj, Error>) in
                    switch res{
                    case .success(let data):
                        PBMobileAds.shared.log("Get Config ADBanner placement: '\(String(describing: self.placement))' Success")
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
                        PBMobileAds.shared.log("Get Config ADBanner placement: '\(String(describing: self.placement))' Fail with Error: \(err.localizedDescription)")
                        break
                    }
                }
            }
        }
    }
    
    deinit {
        PBMobileAds.shared.log("ADBanner Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ADBanner Placement '\(String(describing: self.placement))' with ConsentStr: \(String(describing: consentStr))")
            self.load()
        }
    }
    
    // MARK: - Preload + Load
    func deplayCallPreload() {
        self.isRecallingPreload = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.BANNER_RECALL_DEFAULT) {
            self.isRecallingPreload = false
            self.load()
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
        if self.adUnit == nil || self.amBanner == nil { return }
        
        self.isRecallingPreload = false
        self.isLoadBannerSucc = false
        self.appBannerView?.removeFromSuperview()
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amBanner?.removeFromSuperview()
        self.amBanner = nil
    }
    
    func handlerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amBanner.load(self.amRequest)
        } else {
            self.isLoadBannerSucc = false
            
            if resultCode == ResultCode.prebidDemandNoBids {
                self.deplayCallPreload()
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                self.deplayCallPreload()
            }
        }
    }
    
    public func load() {
        PBMobileAds.shared.log("ADBanner Placement '\(String(describing: self.placement))' - isLoaded: \(self.isLoaded()) |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isLoaded() == true || self.isRecallingPreload == true { return }
        self.resetAD();
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count <= 0 {
            PBMobileAds.shared.log("ADBanner Placement '\(String(describing: self.placement))' is not active or not exist");
            return
        }
        
        // Check and set default
        self.adFormatDefault = ADFormat(rawValue: adUnitObj.defaultType)
        if adUnitObj.adInfor.count < 2 {
            // set adformat theo loại duy nhất có
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
            PBMobileAds.shared.log("AdInfor of ADBanner Placement '" + self.placement + "' is not exist");
            return
        }
        
        // Setup ad size
        let bannerSize: BannerSize = self.getBannerType(w: self.adUnitObj.width!, h: self.adUnitObj.height!)
        self.setAdSize(size: bannerSize)

        PBMobileAds.shared.log("Load ADBanner Placement: \(String(describing: self.placement))")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        if isVideo {
            PBMobileAds.shared.log("[ADBanner Video] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            self.adUnit = VideoAdUnit(configId: adInfor.configId, size: self.curBannerSize.cgSize)
        } else {
            PBMobileAds.shared.log("[ADBanner HTML] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            self.adUnit = BannerAdUnit(configId: adInfor.configId, size: self.curBannerSize.cgSize)
        }
        self.adUnit.setAutoRefreshMillis(time: self.timeAutoRefesh)
        
        self.amBanner = DFPBannerView(adSize: self.curBannerSize.gadSize)
        self.amBanner.adUnitID = adInfor.adUnitID
        self.amBanner.delegate = self
        self.amBanner.rootViewController = self.adUIViewCtr
        self.appBannerView.addSubview(self.amBanner)
        
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch ADBanner placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
            self?.handlerResult(resultCode);
        }
    }
    
    public func destroy() {
        PBMobileAds.shared.log("Destroy ADBanner Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    private func setAnchor(anchor: Anchor){
        self.defaultAnchor = anchor
    }
    
    private func setAdSize(size: BannerSize){
        let cgSize = self.getBannerSize(typeBanner: size)
        let gadSize = self.getGADBannerSize(typeBanner: size)
        self.curBannerSize = MyBannerSize(cgSize: cgSize, gadSize: gadSize)
    }
    
    public func getAdSize() -> CGSize? {
        return self.amBanner?.adSize.size
    }
    
    public func setAutoRefreshMillis(timeMillis: Double){
        self.timeAutoRefesh = timeMillis
        self.adUnit?.setAutoRefreshMillis(time: timeMillis)
    }
    
    public func isLoaded() -> Bool {
        return self.isLoadBannerSucc
    }
    
    public func setListener(_ adDelegate : ADBannerDelegate){
        self.adDelegate = adDelegate
    }
    
    // MARK: - Private FUNC
    func getBannerSize(typeBanner: BannerSize) -> CGSize {
        switch typeBanner {
        case .Banner320x50:
            return CGSize(width: 320, height: 50)
        case .Banner320x100:
            return CGSize(width: 320, height: 100)
        case .Banner300x250:
            return CGSize(width: 300, height: 250)
        case .Banner468x60:
            return CGSize(width: 468, height: 60)
        case .Banner728x90:
            return CGSize(width: 728, height: 90)
        case .SmartBanner:
            return CGSize(width: 1, height: 1)
        }
    }
    
    func getGADBannerSize(typeBanner: BannerSize) -> GADAdSize {
        switch typeBanner {
        case .Banner320x50:
            return kGADAdSizeBanner
        case .Banner320x100:
            return kGADAdSizeLargeBanner
        case .Banner300x250:
            return kGADAdSizeMediumRectangle
        case .Banner468x60:
            return kGADAdSizeFullBanner
        case .Banner728x90:
            return kGADAdSizeLeaderboard
        case .SmartBanner:
            if UIApplication.shared.statusBarOrientation.isPortrait {
                return kGADAdSizeSmartBannerPortrait
            } else {
                return kGADAdSizeSmartBannerLandscape
            }
        }
    }
    
    func getBannerType(w: String, h: String) -> BannerSize {
        let bannerType = "\(w)x\(h)"
        
        switch bannerType {
        case "320x50":
            return .Banner320x50
        case "320x100":
            return .Banner320x100
        case "300x250":
            return .Banner300x250
        case "468x60":
            return .Banner468x60
        case "728x90":
            return .Banner728x90
        case "1x1":
            return .SmartBanner
        default:
            return .SmartBanner
        }
    }
    
    func setupAnchor(_ view: GADBannerView){
        view.translatesAutoresizingMaskIntoConstraints = false
        if defaultAnchor == .TopLeft {
            view.topAnchor.constraint(equalTo: self.appBannerView.topAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.appBannerView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .TopCenter {
            view.topAnchor.constraint(equalTo: self.appBannerView.topAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appBannerView.centerXAnchor).isActive = true
        } else if defaultAnchor == .TopRight {
            view.topAnchor.constraint(equalTo: self.appBannerView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.appBannerView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .CenterLeft {
            view.centerYAnchor.constraint(equalTo: self.appBannerView.centerYAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: self.appBannerView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .Center {
            view.centerYAnchor.constraint(equalTo: self.appBannerView.centerYAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appBannerView.centerXAnchor).isActive = true
        } else if defaultAnchor == .CenterRight {
            view.centerYAnchor.constraint(equalTo: self.appBannerView.centerYAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.appBannerView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .BottomLeft {
            view.bottomAnchor.constraint(equalTo: self.appBannerView.bottomAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.appBannerView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .BottomCenter {
            view.bottomAnchor.constraint(equalTo: self.appBannerView.bottomAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.appBannerView.centerXAnchor).isActive = true
        } else if defaultAnchor == .BottomRight {
            view.bottomAnchor.constraint(equalTo: self.appBannerView.bottomAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.appBannerView.rightAnchor, constant: 0).isActive = true
        }
    }
    
    // MARK: - Delegate
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.isLoadBannerSucc = true
        AdViewUtils.findPrebidCreativeSize(bannerView,
                                           success: { (size) in
                                            guard let bannerView = bannerView as? DFPBannerView else {
                                                return
                                            }
                                            self.setupAnchor(bannerView)
                                            bannerView.resize(GADAdSizeFromCGSize(size))
                                            
                                            PBMobileAds.shared.log("bannerDidReceiveAd: ADBanner Placement '\(String(describing: self.placement))'");
                                            self.adDelegate?.bannerDidReceiveAd?(data: "bannerDidReceiveAd: ADBanner Placement '\(String(describing: self.placement))'")
        },
                                           failure: { (error) in
                                            self.setupAnchor(bannerView)
                                            
                                            PBMobileAds.shared.log("bannerDidReceiveAd: ADBanner Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
                                            self.adDelegate?.bannerDidReceiveAd?(data: "bannerDidReceiveAd: ADBanner Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
        })
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        self.isLoadBannerSucc = false
        
        PBMobileAds.shared.log("bannerLoadFail: ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)");
        self.adDelegate?.bannerLoadFail?(data: "bannerLoadFail: ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("bannerWillPresentScreen: ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillPresentScreen?(data: "bannerWillPresentScreen: ADBanner Placement '\(String(describing: self.placement))'")
    }
    
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("bannerWillDismissScreen: ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillDismissScreen?(data: "bannerWillDismissScreen: ADBanner Placement '\(String(describing: self.placement))'")
    }
    
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("bannerDidDismissScreen: ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidDismissScreen?(data: "bannerDidDismissScreen: ADBanner Placement '\(String(describing: self.placement))'")
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("bannerWillLeaveApplication: ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillLeaveApplication?(data: "bannerWillLeaveApplication: ADBanner Placement '\(String(describing: self.placement))'")
    }
}

@objc public protocol ADBannerDelegate {
    
    // Called when an ad request loaded an ad.
    @objc optional func bannerDidReceiveAd(data: String)
    
    // Called when an ad request failed.
    @objc optional func bannerLoadFail(data: String)
    
    // Called just before presenting the user a full screen view, such as a browser, in response to
    // clicking on an ad.
    @objc optional func bannerWillPresentScreen(data: String)
    
    // Called just before dismissing a full screen view.
    @objc optional func bannerWillDismissScreen(data: String)
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store).
    @objc optional func bannerDidDismissScreen(data: String)
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store).
    @objc optional func bannerWillLeaveApplication(data: String)
    
}

public enum BannerSize {
    case Banner320x50
    case Banner320x100
    case Banner300x250
    case Banner468x60
    case Banner728x90
    case SmartBanner
}

public enum Anchor {
    case TopLeft
    case TopCenter
    case TopRight
    case CenterLeft
    case Center
    case CenterRight
    case BottomLeft
    case BottomCenter
    case BottomRight
}

class MyBannerSize {
    var cgSize: CGSize
    var gadSize: GADAdSize
    
    init(cgSize: CGSize, gadSize: GADAdSize) {
        self.cgSize = cgSize
        self.gadSize = gadSize
    }
}
