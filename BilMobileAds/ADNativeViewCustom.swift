//
//  ADNativeViewCustom.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 9/23/20.
//  Copyright © 2020 bil. All rights reserved.
//

import UIKit
import GoogleMobileAds

@objc public class ADNativeViewCustom: GADUnifiedNativeAdView {
    
    /// Weak reference to your ad view's headline asset view.
    @IBOutlet public weak var _headlineView: UIView!
    /// Weak reference to your ad view's call to action asset view.
    @IBOutlet public weak var _callToActionView: UIView!
    /// Weak reference to your ad view's icon asset view.
    @IBOutlet public weak var _iconView: UIView!
    /// Weak reference to your ad view's body asset view.
    @IBOutlet public weak var _bodyView: UIView!
    /// Weak reference to your ad view's store asset view.
    @IBOutlet public weak var _storeView: UIView!
    /// Weak reference to your ad view's price asset view.
    @IBOutlet public weak var _priceView: UIView!
    /// Weak reference to your ad view's image asset view.
    @IBOutlet public weak var _imageView: UIView!
    /// Weak reference to your ad view's star rating asset view.
    @IBOutlet public weak var _starRatingView: UIView!
    /// Weak reference to your ad view's advertiser asset view.
    @IBOutlet public weak var _advertiserView: UIView!
    
    /// Weak reference to your ad view's media asset view.
    @IBOutlet public weak var _mediaView: ADMediaView!
    
    /// This property must point to the unified native ad object rendered by this ad view.
    override public var nativeAd: GADUnifiedNativeAd! {
        didSet {
            if let nativeContentAd = nativeAd, let callToActionView = callToActionView {
                nativeContentAd.register(self, clickableAssetViews: [GADUnifiedNativeAssetIdentifier.callToActionAsset: callToActionView], nonclickableAssetViews: [:])
            }
        }
    }
    
    private let adAttribution: UILabel = {
        let adAttribution = UILabel()
        adAttribution.translatesAutoresizingMaskIntoConstraints = false
        adAttribution.text = "Ad"
        adAttribution.textColor = .white
        adAttribution.textAlignment = .center
        adAttribution.backgroundColor = UIColor(red: 1, green: 0.8, blue: 0.4, alpha: 1)
        adAttribution.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold)
        return adAttribution
    }()
    
    private var tappableOverlay: UIView = {
        let tappableOverlay = UIView()
        tappableOverlay.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        tappableOverlay.translatesAutoresizingMaskIntoConstraints = false
        tappableOverlay.isUserInteractionEnabled = true
        tappableOverlay.backgroundColor = .white
        tappableOverlay.alpha = 0.01
        return tappableOverlay
    }()
    
    /// Init by code
    init() {
        super.init(frame: CGRect.zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        callToActionView = tappableOverlay
    }
    
    /// init by xib
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        callToActionView = tappableOverlay
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        addSubview(tappableOverlay)
        addSubview(adAttribution)
    }
    
    override public func updateConstraints() {
        super.updateConstraints()
        
        tappableOverlay.frame = self.superview!.bounds
    }
}

@objc public class ADMediaView: GADMediaView {
    
    init(){
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
