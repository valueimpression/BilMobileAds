//
//  PBMobileAds.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

public class PBMobileAds {
    
    public static let shared = PBMobileAds()
    
    // Log Status
    private var isLog: Bool = true
    
    // MARK: List Config
    private var listAdUnitObj: [AdUnitObj] = []
    
    // MARK: api
    var appName: String = "";
    var gdprConfirm: Bool = false;
    private var pbServerEndPoint: String = ""
    
    private init() {
        log("PBMobileAds Init")
    }
    
    public func initialize(testMode: Bool = false) {
        if !isLog { Prebid.shared.logLevel = .error }
        
        self.appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
        
        //Declare in init to the user agent could be passed in first call
        Prebid.shared.shareGeoLocation = true;
        
        // Setup Test Mode
        if testMode {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers =  [ (kGADSimulatorID as! String), "cc7ca766f86b43ab6cdc92bed424069b"];
        }
        GADMobileAds.sharedInstance().start();
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
    
    // MARK: Setup PBS
    func setupPBS(host: HostAD) {
        PBMobileAds.shared.log("Host: \(host.pbHost) | AccountId: \(host.pbAccountId) | storedAuctionResponse: \(host.storedAuctionResponse)")
        
        if host.pbHost == "Appnexus" {
            Prebid.shared.prebidServerHost = PrebidHost.Appnexus
        } else if host.pbHost == "Rubicon" {
            Prebid.shared.prebidServerHost = PrebidHost.Rubicon
        } else if host.pbHost == "Custom" {
            do {
                PBMobileAds.shared.log("Custom URL: \(String(describing: self.pbServerEndPoint))")
                try Prebid.shared.setCustomPrebidServer(url: self.pbServerEndPoint)
                Prebid.shared.prebidServerHost = PrebidHost.Custom
            } catch {
                PBMobileAds.shared.log("URL server incorrect!")
            }
        }
        
        Prebid.shared.prebidServerAccountId = host.pbAccountId;
        Prebid.shared.storedAuctionResponse = host.storedAuctionResponse;
    }
        
    // MARK: - Call API AD
    func getADConfig(adUnit: String, complete: @escaping (Result<AdUnitObj,Error>) -> Void) {
        self.log("Start Request Config adUnit: \(adUnit)")
        
        Helper.shared.getAPI(api: Constants.GET_DATA_CONFIG + adUnit){ (res: Result<DataConfig, Error>) in
            switch res{
            case .success(let dataJSON):
                self.log("Fetch Data Succ")
                
                DispatchQueue.main.async{
                    self.gdprConfirm = dataJSON.gdprConfirm ?? false
                    self.pbServerEndPoint = dataJSON.pbServerEndPoint
                    
                    self.listAdUnitObj.append(dataJSON.adunit)
                    complete(.success(dataJSON.adunit))
                }

                break
            case .failure(let err):
                self.timerRecall(adUnit: adUnit, complete: complete)
                complete(.failure(err))
                break
            }
        }
    }
    
    func timerRecall(adUnit: String, complete: @escaping (Result<AdUnitObj,Error>) -> Void){
        self.log("Recall Request Config After: \(Constants.RECALL_CONFIGID_SERVER)")
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.RECALL_CONFIGID_SERVER, execute: {
            self.getADConfig(adUnit: adUnit, complete: complete);
        })
    }
    
    func log( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if !isLog { return }
        print("[PBMobileAds] \(Date().toString()) | [\(self.sourceFileName(filePath: filename))]:\(line) \(column) | \(funcName) -> \(object)")
    }
    
    func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    public func enableCOPPA() {
        Targeting.shared.subjectToCOPPA = true
    }
    
    public func disableCOPPA() {
        Targeting.shared.subjectToCOPPA = false
    }

    public func setGender(gender: Gender) {
        Targeting.shared.gender = gender;
    }
    
    public func setYearOfBirth(yob: Int) throws {
        try Targeting.shared.setYearOfBirth(yob: yob);
    }
}

//internal extension Date {
//    func toString() -> String {
//        return Helper.dateFormatter.string(from: self as Date)
//    }
//}
