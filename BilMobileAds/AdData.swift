//
//  AdData.swift
//  BilMobileAds
//
//  Created by HNL on 25/08/2023.
//  Copyright © 2023 bil. All rights reserved.
//

public class AdData: NSObject {
    var currencyCode: String
    var precision: Int
    var microsValue: NSDecimalNumber
    
    @objc public init(currencyCode: String, precision: Int, microsValue: NSDecimalNumber) {
        self.currencyCode = currencyCode
        self.precision = precision
        self.microsValue = microsValue
    }
}
