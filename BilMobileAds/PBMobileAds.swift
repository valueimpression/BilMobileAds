//
//  PBMobileAds.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class PBMobileAds: NSObject, CloseListenerDelegate {
    
    @objc public static let shared = PBMobileAds()
    
    // MARK: Config
    private var listAdUnitObj: [AdUnitObj] = []
    
    // MARK: API
    var gdprConfirm: Bool = false
    var nativeTemplateId: String = ""
    private var pbServerEndPoint: String = ""
    // MARK: CMP
    var isShowCMP: Bool = false
    private var closure: (WorkComplete) -> Void
    // MARK: LOG
    private final let DEBUG_MODE: Bool = false
    
    private override init() {
        self.closure = {_ in return}
        super.init()
    }
    
    @objc public func initialize(testMode: Bool = false) {
        self.log(logType: .info, "PBMobileAds Init")
        
        Prebid.shared.logLevel = .severe
        //Declare in init to the user agent could be passed in first call
        Prebid.shared.shareGeoLocation = true
        Prebid.shared.pbsDebug = testMode
        
        GADMobileAds.sharedInstance().start()
    }
    
    @objc public func setTestDeviceIds(testDeviceIds: String) {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [testDeviceIds] // Sample device ID: 2077ef9a63d2b398840261c8221a0c9b
    }
    
    // MARK: - Get Data Config
    func getAdUnitObj(placement: String) -> AdUnitObj? {
        for config in self.listAdUnitObj {
            if config.placement == placement {
                return config
            }
        }
        return nil
    }
    
    func getAdInfor(isVideo: Bool, adUnitObj: AdUnitObj) -> AdInfor? {
        for infor in adUnitObj.adInfor {
            if infor.isVideo == isVideo {
                return infor
            }
        }
        return nil
    }
    
    // MARK: - Setup PBS
    func setupPBS(host: HostAD) {
        PBMobileAds.shared.log(logType: .debug, "Host: \(host.pbHost) | AccountId: \(host.pbAccountId) | storedAuctionResponse: \(host.storedAuctionResponse)")
        
        if host.pbHost == "Appnexus" {
            Prebid.shared.prebidServerHost = PrebidHost.Appnexus
        } else if host.pbHost == "Rubicon" {
            Prebid.shared.prebidServerHost = PrebidHost.Rubicon
        } else if host.pbHost == "Custom" {
            do {
                PBMobileAds.shared.log(logType: .debug, "Custom URL: \(String(describing: self.pbServerEndPoint))")
                try Prebid.shared.setCustomPrebidServer(url: self.pbServerEndPoint)
                Prebid.shared.prebidServerHost = PrebidHost.Custom
            } catch {
                PBMobileAds.shared.log(logType: .debug, "URL server incorrect!")
            }
        }
        
        Prebid.shared.prebidServerAccountId = host.pbAccountId
        Prebid.shared.storedAuctionResponse = host.storedAuctionResponse
    }
    
    // MARK: - Show CMP + Setup GDPR
    func setGDPR() {
        if let consentStr = CMPConsentToolAPI().consentString {
            Targeting.shared.subjectToGDPR = true
            Targeting.shared.gdprConsentString = consentStr
        }
    }
    
    func showCMP(adUIViewCtr: UIViewController, complete: @escaping (WorkComplete) -> Void) {
        if self.isShowCMP {
            complete(.doWork)
            return
        }
        
        if self.gdprConfirm {
            if CMPConsentTool().needShowCMP() {
                self.log(logType: .info, "ConsentString Init");
                
                self.isShowCMP = true
                self.closure = complete
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
                let cmp = ShowCMP()
                cmp.closeDelegate = self
                cmp.open(adUIViewCtr, appName: appName)
            } else {
                self.setGDPR()
                complete(.doWork)
            }
        } else {
            complete(.doWork)
        }
    }
    
    public func onWebViewClosed(_ consentStr: String) {
        self.isShowCMP = false
        self.setGDPR()
        self.closure(.doWork)
    }
    
    // MARK: - Call API AD
    func getADConfig(adUnit: String, complete: @escaping (Result<AdUnitObj,Error>) -> Void) {
        self.log(logType: .debug, "Start Request Config adUnit: \(adUnit)")
        
        Helper.shared.getAPI(api: BilConstants.GET_DATA_CONFIG + adUnit){ (res: Result<DataConfig, Error>) in
            switch res{
            case .success(let dataJSON):
                DispatchQueue.main.async {
                    // Check AdUnitObj Exist if init new Ad > 2
                    if let adUnitCheck = self.getAdUnitObj(placement: adUnit) {
                        complete(.success(adUnitCheck))
                        return
                    }
                    
                    self.gdprConfirm = dataJSON.gdprConfirm ?? false
                    self.nativeTemplateId = dataJSON.nativeTemplateId ?? ""
                    self.pbServerEndPoint = dataJSON.pbServerEndPoint
                    
                    // Validate defaultType Bid type
                    let adUnit: AdUnitObj = dataJSON.adunit
                    if adUnit.adInfor.count < 2  {
                        let bidType = adUnit.adInfor[0].isVideo ? "vast" : "html"
                        adUnit.defaultType = adUnit.defaultType == bidType ? adUnit.defaultType : bidType
                    }
                    
                    self.listAdUnitObj.append(adUnit)
                    complete(.success(adUnit))
                }
                break
            case .failure(let err):
                //  self.timerRecall(adUnit: adUnit, complete: complete)
                complete(.failure(err))
                break
            }
        }
    }
    
    func timerRecall(adUnit: String, complete: @escaping (Result<AdUnitObj,Error>) -> Void){
        self.log(logType: .debug, "Recall Request Config After: \(BilConstants.RECALL_CONFIGID_SERVER)")
        DispatchQueue.main.asyncAfter(deadline: .now() + BilConstants.RECALL_CONFIGID_SERVER, execute: {
            self.getADConfig(adUnit: adUnit, complete: complete)
        })
    }
    
    func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    @objc public func log(logType: LogType, _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        
        // Create Date
        let date = Date()
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        
        // Convert Date to String
        let dateStr = dateFormatter.string(from: date)
        
        if logType == .debug {
            if !DEBUG_MODE { return }
            print("\(dateStr) \(logType.icon())[PBMobileAds]: [\(self.sourceFileName(filePath: filename))]:l-\(line) c-\(column) | \(funcName) -> \(object)")
        } else {
            print("\(dateStr) \(logType.icon())[PBMobileAds]: [\(self.sourceFileName(filePath: filename))]:l-\(line) c-\(column) | \(funcName) -> \(object)")
        }
    }
    
    @objc public func enableCOPPA() {
        Targeting.shared.subjectToCOPPA = true
    }
    
    @objc public func disableCOPPA() {
        Targeting.shared.subjectToCOPPA = false
    }
    
    @objc public func setConsentString(consentString: String) {
        if (consentString.isEmpty) {
            log(logType: .error, "Consent String is empty")
            return
        }
        Targeting.shared.subjectToGDPR = true
        Targeting.shared.gdprConsentString = consentString
    }
    
    @objc public func setPurposeConsents(purposeConsents: String) {
        if (purposeConsents.isEmpty) {
            log(logType: .error, "PurposeConsents is empty")
            return
        }
        Targeting.shared.purposeConsents = purposeConsents
    }
    
    @objc public func setCCPAString(ccpaString: String) {
        if (ccpaString.isEmpty) {
            log(logType: .error, "CCPA is empty")
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(ccpaString, forKey: "IABUSPrivacy_String")
    }
    
    @objc public func setGender(gender: Gender) {
        Targeting.shared.userGender = gender
    }
    
    @objc public func setYearOfBirth(yob: Int) {
        Targeting.shared.setYearOfBirth(yob: yob)
    }
}
