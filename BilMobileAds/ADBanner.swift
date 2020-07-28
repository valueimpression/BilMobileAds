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
    private var isLoadBannerSucc: Bool = false; // true => banner đang chạy
    private var isRecallingPreload: Bool = false // Check đang đợi gọi lại preload
    
    // MARK: - Init + DeInit
    public init(_ adUIViewCtr: UIViewController, view adView: UIView, placement: String) {
        super.init()
        PBMobileAds.shared.log("AD Banner Init")
        
        self.defaultAnchor = .Center
        self.setAdSize(size: .Banner320x50)
        
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
                        PBMobileAds.shared.log("getADConfig placement: \(String(describing: self.placement)) Succ")
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
            }
        }
    }
    
    deinit {
        PBMobileAds.shared.log("AD Banner Deinit")
        self.destroy()
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PBMobileAds.shared.log("ConsentStr: \(String(describing: consentStr))")
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
    
    public func load() {
        PBMobileAds.shared.log(" | isRunning: \(self.isLoaded()) |  isRecallingPreload: \(self.isRecallingPreload)")
        if self.adUnitObj == nil || self.isLoaded() == true || self.isRecallingPreload == true { return }
        PBMobileAds.shared.log("Load Banner AD")
        
        // Get Data Config
        if self.adUnitObj == nil {
            guard let adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement) else {
                PBMobileAds.shared.log("Placement is not exist")
                return
            }
            
            self.adUnitObj = adUnitObj
        }
        
        // Check Active
        if !adUnitObj.isActive {
            PBMobileAds.shared.log("Ad is not actived")
            return
        }
        
        // Check and set default
        self.adFormatDefault = self.adFormatDefault == nil ? ADFormat(rawValue: adUnitObj.defaultType) : self.adFormatDefault
        // set adformat theo loại duy nhất có
        if adUnitObj.adInfor.count < 2 {
            self.adFormatDefault = adUnitObj.adInfor[0].isVideo ? .vast : .html
        }
        
        // Remove Ad
        self.destroy()
        
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
            PBMobileAds.shared.log("[Banner Video] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            
            let parameters = VideoBaseAdUnit.Parameters()
            parameters.mimes = ["video/mp4"]
            parameters.protocols = [Signals.Protocols.VAST_2_0]
            parameters.playbackMethod = [Signals.PlaybackMethod.AutoPlaySoundOff]
            parameters.placement = Signals.Placement.InBanner
            
            let vAdUnit = VideoAdUnit(configId: adInfor.configId, size: self.curBannerSize.cgSize)
            vAdUnit.parameters = parameters
            
            self.adUnit = vAdUnit
        } else {
            guard let infor = getAdInfor(isVideo: false) else {
                PBMobileAds.shared.log("AdInfor is not exist")
                return
            }
            adInfor = infor
            
            PBMobileAds.shared.setupPBS(host: adInfor.host)
            PBMobileAds.shared.log("[Banner Simple] - configID: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
            self.adUnit = BannerAdUnit(configId: adInfor.configId, size: self.curBannerSize.cgSize)
        }
        self.adUnit.setAutoRefreshMillis(time: self.timeAutoRefesh)
        
        self.amBanner = DFPBannerView(adSize: self.curBannerSize.gadSize)
        self.amBanner.delegate = self
        self.amBanner.adUnitID = adInfor.adUnitID
        self.amBanner.rootViewController = self.adUIViewCtr
        self.appBannerView.addSubview(self.amBanner)
        
        self.adUnit.fetchDemand(adObject: self.amRequest) { [weak self] (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch for DFP \(resultCode.name()) | placement: \(String(describing: self?.placement))")
            self?.handerResult(resultCode);
        }
    }
    
    public func destroy() {
        if self.isLoaded() == true {
            PBMobileAds.shared.log("Destroy Placement: \(String(describing: self.placement))")
            self.stopAutoRefresh()
            self.isLoadBannerSucc = false
            self.amBanner?.removeFromSuperview()
        }
    }
    
    func handerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            //  self.isLoadBannerSucc = true
            self.amBanner.load(self.amRequest)
        } else {
            self.isLoadBannerSucc = false
            self.stopAutoRefresh()
            
            if resultCode == ResultCode.prebidDemandNoBids {
                self.adFormatDefault = self.adFormatDefault == .html ? .vast : .html
                self.deplayCallPreload()
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                self.deplayCallPreload()
            }
        }
    }
    
    // MARK: - Public FUNC
    public func setAnchor(anchor: Anchor){
        self.defaultAnchor = anchor
    }
    
    public func setAdSize(size: BannerSize){
        let cgSize = self.getBannerSize(typeBanner: size)
        let gadSize = self.getGADBannerSize(typeBanner: size)
        self.curBannerSize = MyBannerSize(cgSize: cgSize, gadSize: gadSize)
    }
    
    public func getAdSize() -> CGSize? {
        return self.curBannerSize?.cgSize
    }
    
    public func setAutoRefreshMillis(timeMillis: Double){
        self.timeAutoRefesh = timeMillis
        self.adUnit?.setAutoRefreshMillis(time: timeMillis)
    }
    
    public func stopAutoRefresh(){
        // run stopAutoRefresh to stop .fetchDemand
        self.adUnit?.stopAutoRefresh()
    }
    
    public func isLoaded() -> Bool {
        return self.isLoadBannerSucc
    }
    
    func addFirstPartyData(adUnit: AdUnit) {
        // Access Control List
        // Targeting.shared.addBidderToAccessControlList(Prebid.bidderNameAppNexus)
        
        //global user data
        // Targeting.shared.addUserData(key: "globalUserDataKey1", value: "globalUserDataValue1")
        
        //global context data
        // Targeting.shared.addContextData(key: "globalContextDataKey1", value: "globalContextDataValue1")
        
        //adunit context data
        // adUnit.addContextData(key: "adunitContextDataKey1", value: "adunitContextDataValue1")
        
        //global context keywords
        // Targeting.shared.addContextKeyword("globalContextKeywordValue1")
        // Targeting.shared.addContextKeyword("globalContextKeywordValue2")
        
        //global user keywords
        // Targeting.shared.addUserKeyword("globalUserKeywordValue1")
        // Targeting.shared.addUserKeyword("globalUserKeywordValue2")
        
        //adunit context keywords
        // adUnit.addContextKeyword("adunitContextKeywordValue1")
        // adUnit.addContextKeyword("adunitContextKeywordValue2")
    }
    
    // MARK: - Private FUNC
    func setRequestTimeoutMillis(time: Int) {
        Prebid.shared.timeoutMillis = time
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
        }
    }
    
    func setupAnchor(_ view: GADBannerView){
        //        view.layer.borderWidth = 5
        //        view.layer.borderColor = UIColor.lightGray.cgColor
        
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
        PBMobileAds.shared.log("AD Banner Received")
        self.adDelegate?.bannerDidReceiveAd?(data: "AD Banner Received")
        
        self.isLoadBannerSucc = true
        AdViewUtils.findPrebidCreativeSize(bannerView,
                                           success: { (size) in
                                            guard let bannerView = bannerView as? DFPBannerView else {
                                                return
                                            }
                                            self.setupAnchor(bannerView)
                                            bannerView.resize(GADAdSizeFromCGSize(size))
        },
                                           failure: { (error) in
                                            PBMobileAds.shared.log("AD Banner Received But Fail: \(error.localizedDescription)")
                                            self.adDelegate?.bannerLoadFail?(data: "AD Banner Received But Fail: \(error.localizedDescription)")
        })
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        self.isLoadBannerSucc = false
        
        PBMobileAds.shared.log("Load Fail: \(error.localizedDescription)")
        self.adDelegate?.bannerLoadFail?(data: "Load Fail: \(error.localizedDescription)")
    }
    
    public func adView(_ bannerView: DFPBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        self.isLoadBannerSucc = false
        
        PBMobileAds.shared.log("Load Fail: \(error.localizedDescription)")
        self.adDelegate?.bannerLoadFail?(data: "Load Fail: \(error.localizedDescription)")
    }
    
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("Ad Banner Will Present")
        self.adDelegate?.bannerWillPresentScreen?(data: "AD Banner Will Present")
    }
    
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("Ad Banner Will Dismiss")
        self.adDelegate?.bannerWillDismissScreen?(data: "AD Banner Will Dismiss")
    }
    
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("Ad Banner Dismissed")
        self.adDelegate?.bannerDidDismissScreen?(data: "Ad Banner Dismissed")
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        PBMobileAds.shared.log("AD Banner Leave Application")
        self.adDelegate?.bannerWillLeaveApplication?(data: "AD Banner Leave Application")
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
