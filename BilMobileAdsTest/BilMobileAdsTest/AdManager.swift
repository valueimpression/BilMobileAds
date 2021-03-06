//
//  TestAds.swift
//  BilMobileAdsTest
//
//  Created by HNL_MAC on 10/6/20.
//  Copyright © 2020 bil. All rights reserved.
//

import Foundation
import BilMobileAds

class AdManager: NativeAdLoaderCustomDelegate {
    
    var listNativeAd: [ADNativeViewBuilder] = []
    var nativeCustom: ADNativeCustom!
    
    init() {
        
    }
    
    func setNativeObj(nativeCus: ADNativeCustom) {
        nativeCustom = nativeCus
    }
    
    func load(){
        nativeCustom.preLoad()
    }
    
    func getNativeViewBuilder() -> ADNativeViewBuilder? {
        if listNativeAd.isEmpty { return nil }
        return listNativeAd.removeFirst()
    }
    func nativeAdViewLoaded(viewBuilder: ADNativeViewBuilder) {
        listNativeAd.append(viewBuilder)
        
//        // Preload native ads (Max 5 request)
//        PBMobileAds.shared.log(logType: .info, "Total current Ads stored: \(nativeCustom.numOfAds())")
//        if nativeCustom.numOfAds() < (nativeCustom.MAX_ADS - 3) {
//            nativeCustom.preLoad()
//        }
    }
    func nativeAdFailedToLoad(error: String) {
        print("Native Ad Custom Loaded Fail")
    }
    
    
}
