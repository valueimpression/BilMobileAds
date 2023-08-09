//
//  BilConstants.swift
//  BilMobileAds
//
//  Created by HNL on 22/04/2021.
//  Copyright © 2021 bil. All rights reserved.
//

import PrebidMobile

public enum ADFormat: String {
    case html = "html" // simple
    case vast = "vast" // video
}

public enum ADType: String {
    case Banner = "banner"
    case Interstitial = "interstitial"
    case Rewarded = "rewarded"
}

@objc public enum LogType: Int {
    case debug
    case verbose
    case info
    case warn
    case error
    case severe
    
    public func icon() -> String {
        switch self {
        case .debug: return "[💬]" // debug
        case .verbose: return "[🔬]" // verbose
        case .info: return "[ℹ️]" // info
        case .warn: return "[⚠️]" // warning
        case .error: return "[‼️]" // error
        case .severe: return "[🔥]" // severe
        }
    }
}

struct BilConstants {

    // MARK: - BANNER + INTERSTITIAL
    // AD Simple Test
    static let PB_SERVER_HOST = PrebidHost.Appnexus
    static let PB_SERVER_ACCOUNT_ID = "bfa84af2-bd16-4d35-96ad-31c6bb888df0"
    static let ADUNIT_CONFIG_ID = "625c6125-f19e-4d5b-95c5-55501526b2a4"
    // AD Video Test
    static let V_PB_SERVER_HOST = PrebidHost.Rubicon
    static let V_PB_SERVER_ACCOUNT_ID = "1001"
    static let V_ADUNIT_CONFIG_ID = "1001-1"
    
    static let PB_SERVER_CUSTOM = "https://pb-server.vliplatform.com/openrtb2/auction" // "http://localhost:8000/openrtb2/auction" //
    
    // MARK: - Properties
    static let RECALL_CONFIGID_SERVER: Double = 5 // Sec
    static let BANNER_AUTO_REFRESH_DEFAULT: Double = 30000 // MilliSec
    static let BANNER_RECALL_DEFAULT: Double = 10 // Sec
    static let INTERSTITIAL_RECALL_DEFAULT: Double = 1 // Sec
    
    static let ERROR_NO_FILL: Int = 1 // match kGADErrorNoFill
    
    // MARK: - URL Prefix
    static let URL_PREFIX = "https://app-services.vliplatform.com" // "http://localhost:8000"
    // API
    static let GET_DATA_CONFIG = "/getAdunitConfig?adUnitId="
}
