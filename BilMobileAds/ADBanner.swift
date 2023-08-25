//
//  ADBanner.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADBanner : NSObject, GADBannerViewDelegate, BannerViewDelegate {
    
    // MARK: - View OBJ
    weak var adView: UIView!
    weak var adUIViewCtr: UIViewController!
    weak var adDelegate: ADBannerDelegate!
    
    // MARK: - AD OBJ
    private let amRequest = GAMRequest()
    private var adUnit: BannerAdUnit!
    private var amBanner: GAMBannerView!
    
    private var bannerView: BannerView!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: - Properties
    private var defaultAnchor: Anchor!
    private var adFormatDefault: ADFormat!
    private var curBannerSize: MyBannerSize!
    
    private var isDisSetupAnchor: Bool = false // Use for UnitySDK
    private var isLoadBannerSucc: Bool = false
    private var setDefaultBidType: Bool = true
    private var isFetchingAD: Bool = false
    
    // MARK: - Init + DeInit
    @objc public init(_ adUIViewCtr: UIViewController, view adView: UIView, placement: String) {
        super.init()
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement: \(placement) Init")
        
        self.defaultAnchor = .Center
        
        self.adUIViewCtr = adUIViewCtr
        self.adView = adView
        self.adDelegate = adUIViewCtr as? ADBannerDelegate
        
        self.placement = placement
        
        self.getConfigAD()
    }
    
    deinit {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' Deinit")
        self.destroy()
    }
    
    // MARK: - Handler AD
    func getConfigAD() {
        self.adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement)
        if self.adUnitObj == nil {
            self.isFetchingAD = true
            
            // Setup Application Delegate
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
                                                   name: UIApplication.didEnterBackgroundNotification, object: nil)
            
            // Get AdUnit Info
            PBMobileAds.shared.getADConfig(adUnit: self.placement) { [weak self] (res: Result<AdUnitObj, Error>) in
                switch res{
                case .success(let data):
                    PBMobileAds.shared.log(logType: .info, "ADBanner placement: \(String(describing: self?.placement)) Init Success")
                    self?.isFetchingAD = false
                    self?.adUnitObj = data
                    
                    PBMobileAds.shared.showCMP(adUIViewCtr: (self?.adUIViewCtr)!) { [weak self] (resultCode: WorkComplete) in
                        self?.load()
                    }
                    break
                case .failure(let err):
                    PBMobileAds.shared.log(logType: .info, "ADBanner placement: \(String(describing: self?.placement)) Init Failed with Error: \(err.localizedDescription). Please check your internet connect")
                    self?.isFetchingAD = false
                    self?.destroy()
                    break
                }
            }
        } else {
            self.load()
        }
    }
    
    func resetAD() {
        if self.adUnit == nil || self.amBanner == nil { return }
        
        self.isFetchingAD = false
        self.isLoadBannerSucc = false
        
        self.adUnit?.stopAutoRefresh()
        self.adUnit = nil
        
        self.amBanner?.removeFromSuperview()
        self.amBanner = nil
    }
    
    // MARK: - Load AD
    @objc public func load() {
        PBMobileAds.shared.log(logType: .debug, "ADBanner Placement '\(String(describing: self.placement))' - isLoaded: \(self.isLoaded()) | isFetchingAD: \(self.isFetchingAD)")
        if self.adView == nil {
            PBMobileAds.shared.log(logType: .error, "ADBanner placement: \(String(describing: self.placement)), AdView Placeholder is nil.");
            return
        }
        
        if self.adUnitObj == nil || self.isLoaded() {
            if self.adUnitObj == nil {
                PBMobileAds.shared.log(logType: .info, "ADBanner placement: \(String(describing: self.placement)) is not ready to load.");
                self.getConfigAD();
                return
            }
            return
        }
        self.resetAD()
        
        // Check Active
        if !adUnitObj.isActive || self.adUnitObj.adInfor.count == 0 {
            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' is not active or not exist.")
            return
        }
        
        // Get AdInfor
        guard let adInfor = self.adUnitObj.adInfor.first else {
            PBMobileAds.shared.log(logType: .info, "AdInfor of ADBanner Placement '" + self.placement + "' is not exist.")
            return
        }
        
        // Setup ad size
        let bannerSize: BannerSize = self.getBannerType(w: self.adUnitObj.width!, h: self.adUnitObj.height!)
        self.setAdSize(size: bannerSize)
        
        PBMobileAds.shared.log(logType: .info, "Load ADBanner Placement: \(String(describing: self.placement))")
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log(logType: .debug, "[ADBanner] - configID: '\(adInfor.configId)' | adUnitID: '\(String(describing: adInfor.adUnitID))'")
        
        if (adInfor.adUnitID != nil && !adInfor.adUnitID!.isEmpty) {
            self.adUnit = BannerAdUnit(configId: adInfor.configId, size: self.curBannerSize.cgSize)
            self.adUnit.adFormats = [.banner, .video]
            
            let bannerParameters = BannerParameters()
            bannerParameters.api = [Signals.Api.MRAID_3, Signals.Api.OMID_1]
            self.adUnit.bannerParameters = bannerParameters
            
            let videoParameters = VideoParameters(mimes: ["video/x-flv","video/mp4"])
            videoParameters.placement = Signals.Placement.InBanner
            self.adUnit.videoParameters = videoParameters
            
            // Set auto refresh time | refreshTime is -> sec
            self.startFetchData()
            
            self.amBanner = GAMBannerView(adSize: self.curBannerSize.gadSize)
            self.amBanner.adUnitID = adInfor.adUnitID
            self.amBanner.delegate = self
            self.amBanner.rootViewController = self.adUIViewCtr
            self.adView.addSubview(self.amBanner)
            
            self.amBanner.paidEventHandler = { adValue in
                PBMobileAds.shared.log(logType: .info, "ADBanner placement '\(String(describing: self.placement))'")
                let adData = AdData(currencyCode: adValue.currencyCode, precision: adValue.precision.rawValue, microsValue: adValue.value)
                self.adDelegate?.bannerOnPaidEvent?(adData: adData)
            }
            
            self.isFetchingAD = true
            self.adUnit?.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
                PBMobileAds.shared.log(logType: .debug, "Prebid demand fetch ADBanner placement '\(String(describing: self?.placement))' for DFP: \(resultCode.name())")
                
                self?.amBanner?.load(self?.amRequest)
            }
        } else {
            self.bannerView = BannerView(frame: CGRect(origin: .zero, size: self.curBannerSize.cgSize),
                                         configID: adInfor.configId,
                                         adSize: self.curBannerSize.cgSize)
            self.startFetchData()
            
            self.bannerView.delegate = self
            self.adView.addSubview(self.bannerView)
            
            self.isFetchingAD = true
            self.bannerView.loadAd()
        }
    }
    
    @objc public func destroy() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        PBMobileAds.shared.log(logType: .info, "Destroy ADBanner Placement: '\(String(describing: self.placement))'")
        self.resetAD()
    }
    
    // MARK: - Public FUNC
    @objc public func setAnchor(anchor: Anchor){
        self.defaultAnchor = anchor
    }
    
    @objc public func isLoaded() -> Bool {
        return self.isLoadBannerSucc
    }
    
    @objc public func setListener(_ adDelegate: ADBannerDelegate){
        self.adDelegate = adDelegate
    }
    
    @objc public func getADView() -> UIView {
        return self.amBanner!
    }
    
    @objc public func isDisSetupAnchor(_ isSet: Bool) { // Dis for Unity
        self.isDisSetupAnchor = isSet
    }
    
    @objc public func getWidthInPixels() -> CGFloat {
        if self.amBanner == nil { return 0 }
        return self.amBanner.frame.standardized.width * UIScreen.main.scale
    }
    
    @objc public func getHeightInPixels() -> CGFloat {
        if self.amBanner == nil { return 0 }
        return self.amBanner.frame.standardized.height * UIScreen.main.scale
    }
    
    @objc public func startFetchData() {
        if let refreshTime = self.adUnitObj?.refreshTime {
            self.adUnit?.setAutoRefreshMillis(time: refreshTime * 1000 ) // convert sec to milisec
        }
    }
    
    @objc public func stopFetchData() {
        self.adUnit?.stopAutoRefresh()
        self.bannerView?.stopRefresh()
    }
    
    // MARK: - Private FUNC
    func getAdSize() -> CGSize {
        if self.amBanner == nil { return CGSize() }
        return self.amBanner.adSize.size
    }
    
    func setAdSize(size: BannerSize) {
        let cgSize = self.getBannerSize(typeBanner: size)
        let gadSize = self.getGADBannerSize(typeBanner: size)
        self.curBannerSize = MyBannerSize(cgSize: cgSize, gadSize: gadSize)
    }
    
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
            return GADAdSizeBanner
        case .Banner320x100:
            return GADAdSizeLargeBanner
        case .Banner300x250:
            return GADAdSizeMediumRectangle
        case .Banner468x60:
            return GADAdSizeFullBanner
        case .Banner728x90:
            return GADAdSizeLeaderboard
        case .SmartBanner:
            return GADAdSizeFluid
            //            if UIApplication.shared.statusBarOrientation.isPortrait {
            //                return GADAdSizeSmartBannerPortrait
            //            } else {
            //                return GADAdSizeSmartBannerLandscape
            //            }
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
        if isDisSetupAnchor { return; }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        if defaultAnchor == .TopLeft {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .TopCenter {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .TopRight {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .CenterLeft {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .Center {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .CenterRight {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .BottomLeft {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .BottomCenter {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .BottomRight {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
        }
    }
    
    func setupAnchorPrebidRendering(_ view: BannerView){
        if isDisSetupAnchor { return; }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        if defaultAnchor == .TopLeft {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .TopCenter {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .TopRight {
            view.topAnchor.constraint(equalTo: self.adView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .CenterLeft {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .Center {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .CenterRight {
            view.centerYAnchor.constraint(equalTo: self.adView.centerYAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
            
        } else if defaultAnchor == .BottomLeft {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.leftAnchor.constraint(equalTo: self.adView.leftAnchor, constant: 0).isActive = true
        } else if defaultAnchor == .BottomCenter {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.centerXAnchor.constraint(equalTo: self.adView.centerXAnchor).isActive = true
        } else if defaultAnchor == .BottomRight {
            view.bottomAnchor.constraint(equalTo: self.adView.bottomAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: self.adView.rightAnchor, constant: 0).isActive = true
        }
    }
    
    // MARK: - AD Delegate Prebid Rendering
    public func bannerViewPresentationController() -> UIViewController? {
        return self.adUIViewCtr
    }
    
    public func bannerView(_ bannerView: BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        self.isFetchingAD = false
        self.isLoadBannerSucc = true

        AdViewUtils.findPrebidCreativeSize(self.bannerView, success: { (size) in
            self.setupAnchorPrebidRendering(bannerView)
            bannerView.sizeThatFits(size)

            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' ")
            self.adDelegate?.bannerDidReceiveAd?()
        }, failure: { (error) in
            self.self.setupAnchorPrebidRendering(bannerView)

            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
            self.adDelegate?.bannerDidReceiveAd?()
        })
    }
    
    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWith error: Error) {
        self.isLoadBannerSucc = false
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adDelegate?.bannerLoadFail?(error: "ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    public func bannerViewDidDismissModal(_ bannerView: BannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidDismissScreen?()
    }
    
    public func bannerViewWillPresentModal(_ bannerView: BannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidRecordImpression?()
        
        let bidResponse = bannerView.lastBidResponse
        if (bidResponse != nil) {
            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '" + self.placement + "'");
            let bidWin = bidResponse?.winningBid
            let adData = AdData(currencyCode: "USD", precision: 3, microsValue: NSDecimalNumber(value: bidWin!.price * 1000))
            self.adDelegate?.bannerOnPaidEvent?(adData: adData)    
        }
    }
    
    public func bannerViewWillLeaveApplication(_ bannerView: BannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillLeaveApplication?()
    }
    
    // MARK: - AD Delegate GAM
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.isFetchingAD = false
        self.isLoadBannerSucc = true
        
        AdViewUtils.findPrebidCreativeSize(bannerView, success: { (size) in
            guard let bannerView = bannerView as? GAMBannerView else {
                return
            }
            self.setupAnchor(bannerView)
            bannerView.resize(GADAdSizeFromCGSize(size))
            
            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' ")
            self.adDelegate?.bannerDidReceiveAd?()
        }, failure: { (error) in
            self.setupAnchor(bannerView)
            
            PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' - \(error.localizedDescription)")
            self.adDelegate?.bannerDidReceiveAd?()
        })
    }
    
    public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidRecordClick?()
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidRecordImpression?()
    }
    
    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        self.isLoadBannerSucc = false
        self.isFetchingAD = false
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
        self.adDelegate?.bannerLoadFail?(error: "ADBanner Placement '\(String(describing: self.placement))' with error: \(error.localizedDescription)")
    }
    
    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillPresentScreen?()
    }
    
    public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillDismissScreen?()
    }
    
    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerDidDismissScreen?()
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log(logType: .info, "ADBanner Placement '\(String(describing: self.placement))'")
        self.adDelegate?.bannerWillLeaveApplication?()
    }
    
    // MARK: - Application Delegate
    @objc func appDidBecomeActive(_ application: UIApplication) {
        PBMobileAds.shared.log(logType: .debug, "ADBanner Placement '\(String(describing: self.placement))'")
        self.startFetchData()
    }
    
    @objc func appDidEnterBackground(_ application: UIApplication) {
        PBMobileAds.shared.log(logType: .debug, "ADBanner Placement '\(String(describing: self.placement))'")
        self.stopFetchData()
    }
    
}

@objc public protocol ADBannerDelegate {
    
    // Called when an ad request loaded an ad.
    @objc optional func bannerDidReceiveAd()
    
    // Called when an ad request failed.
    @objc optional func bannerLoadFail(error: String)
    
    @objc optional func bannerDidRecordImpression()
    
    @objc optional func bannerDidRecordClick()
    
    // Called just before presenting the user a full screen view, such as a browser, in response to
    // clicking on an ad.
    @objc optional func bannerWillPresentScreen()
    
    // Called just before dismissing a full screen view.
    @objc optional func bannerWillDismissScreen()
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store).
    @objc optional func bannerDidDismissScreen()
    
    // Called just before the application will background or terminate because the user clicked on an
    // ad that will launch another application (such as the App Store).
    @objc optional func bannerWillLeaveApplication()
    
    @objc optional func bannerOnPaidEvent(adData: AdData)
    
}

@objc public enum BannerSize: Int {
    case Banner320x50
    case Banner320x100
    case Banner300x250
    case Banner468x60
    case Banner728x90
    case SmartBanner
}

@objc public enum Anchor: Int {
    case TopCenter
    case TopLeft
    case TopRight
    case BottomCenter
    case BottomLeft
    case BottomRight
    case Center
    case CenterLeft
    case CenterRight
}

class MyBannerSize {
    var cgSize: CGSize
    var gadSize: GADAdSize
    
    init(cgSize: CGSize, gadSize: GADAdSize) {
        self.cgSize = cgSize
        self.gadSize = gadSize
    }
}
