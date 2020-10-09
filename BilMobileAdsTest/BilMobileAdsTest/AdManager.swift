//
//  TestAds.swift
//  BilMobileAdsTest
//
//  Created by HNL_MAC on 10/6/20.
//  Copyright © 2020 bil. All rights reserved.
//

import Foundation
import BilMobileAds

class AdManager: ADNativeDelegate {
    
    var listNativeAd: [ADNativeViewBuilder] = []
    var nativeCustom: ADNativeCustom!
    
    init(nativeCus: ADNativeCustom) {
        nativeCustom = nativeCus
    }
    
    func load(){
        nativeCustom.load()
    }
    
    func getNativeViewBuilder() -> ADNativeViewBuilder? {
        if listNativeAd.isEmpty { return nil }
        let viewBuilder = listNativeAd.removeFirst()
        return viewBuilder
    }
    
    func nativeViewLoaded(viewBuilder: ADNativeViewBuilder) {
        listNativeAd.append(viewBuilder)
        
        // Preload native ads (Max 5 request)
        PBMobileAds.shared.log("Total current Ads stored: \(nativeCustom.numOfAds())")
        if nativeCustom.numOfAds() < (nativeCustom.MAX_ADS - 3) {
            nativeCustom.load()
        }
    }
}
