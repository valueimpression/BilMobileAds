//
//  ADNativeView.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 9/22/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

@objc public class ADNativeViewBuilder: NSObject, GADUnifiedNativeAdDelegate, NativeAdEventDelegate, GADVideoControllerDelegate {
    
    let placement: String!
    var nativeAd: NativeAd!
    var gadNativeAd: GADUnifiedNativeAd!
    
    var videoDelegate: NativeAdVideoDelegate!
    var nativeAdDelegate: NativeAdCustomDelegate!
    
    init(placement: String, unifiedNativeAd: GADUnifiedNativeAd) {
        self.placement = placement
        self.gadNativeAd = unifiedNativeAd
    }
    
    init(placement: String, nativeAd: NativeAd) {
        self.placement = placement
        self.nativeAd = nativeAd
    }
    
    /// Returns a `UIImage` representing the number of stars from the given star rating.  returns `nil`
    /// if the star rating is less than 3.5 stars.
    func imageOfStars(fromStarRating starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
    public func build(nativeView: ADNativeViewCustom) {
        if gadNativeAd != nil {
            self.fillContentGAD(nativeView: nativeView)
        } else {
            self.fillContentCustom(nativeView: nativeView)
        }
    }
    public func fillContentGAD(nativeView: ADNativeViewCustom) {
        /// Populate the native ad view with the native ad assets. The headline and mediaContent are guaranteed to be present in every native ad.
        (nativeView._headlineView as? UILabel)?.text = gadNativeAd.headline
        
        nativeView._mediaView?.mediaContent = gadNativeAd.mediaContent
        if (gadNativeAd.mediaContent.hasVideoContent) {
            /// By acting as the delegate to the GADVideoController, this ViewController receives message about events in the video lifecycle.
            gadNativeAd.mediaContent.videoController.delegate = self
        }
        /// This app uses a fixed width for the GADMediaView and changes its height to match the aspect ratio of the media it displays.
        if let mediaView = nativeView.mediaView, gadNativeAd.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(item: mediaView,
                                                      attribute: .height,
                                                      relatedBy: .equal,
                                                      toItem: mediaView,
                                                      attribute: .width,
                                                      multiplier: CGFloat(1 / gadNativeAd.mediaContent.aspectRatio),
                                                      constant: 0)
            heightConstraint.isActive = true
        }
        
        /// These assets are not guaranteed to be present. Check that they are before showing or hiding them.
        (nativeView._bodyView as? UILabel)?.text = gadNativeAd.body
        nativeView._bodyView?.isHidden = gadNativeAd.body == nil
        
        let isCallActionBTN = (nativeView._callToActionView as? UIButton) != nil ? true : false
        if isCallActionBTN {
            (nativeView._callToActionView as? UIButton)?.setTitle(gadNativeAd.callToAction, for: .normal)
        } else {
            (nativeView._callToActionView as? UILabel)?.text = gadNativeAd.callToAction
        }
        nativeView._callToActionView?.isHidden = gadNativeAd.callToAction == nil
        /// In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeView._callToActionView?.isUserInteractionEnabled = false
        
        (nativeView._iconView as? UIImageView)?.image = gadNativeAd.icon?.image
        nativeView._iconView?.isHidden = gadNativeAd.icon == nil
        
        let isStarIMG = (nativeView._starRatingView as? UIImageView) != nil ? true : false
        if isStarIMG {
            (nativeView._starRatingView as? UIImageView)?.image = imageOfStars(fromStarRating: gadNativeAd.starRating)
        } else {
            (nativeView._starRatingView as? UILabel)?.text = "\(String(describing: gadNativeAd.starRating)) ✭"
        }
        nativeView._starRatingView?.isHidden = gadNativeAd.starRating == nil
        
        (nativeView._storeView as? UILabel)?.text = gadNativeAd.store
        nativeView._storeView?.isHidden = gadNativeAd.store == nil
        
        (nativeView._priceView as? UILabel)?.text = gadNativeAd.price
        nativeView._priceView?.isHidden = gadNativeAd.price == nil
        
        (nativeView._advertiserView as? UILabel)?.text = gadNativeAd.advertiser
        nativeView._advertiserView?.isHidden = gadNativeAd.advertiser == nil
        
        gadNativeAd.delegate = self
        
        /// Associate the native ad view with the native ad object. This is required to make the ad clickable.
        /// Note: this should always be done after populating the ad views.
        nativeView.nativeAd = gadNativeAd
    }
    public func fillContentCustom(nativeView: ADNativeViewCustom) {
        if nativeAd == nil { return }
        
        nativeAd.delegate = self
        nativeAd.registerView(view: nativeView, clickableViews: [nativeView._callToActionView])
        
        // Title
        (nativeView._headlineView as? UILabel)?.text = nativeAd.title
        nativeView._headlineView?.isHidden = nativeAd.title == nil
        // SponsoredBy
        (nativeView._advertiserView as? UILabel)?.text = nativeAd.sponsoredBy
        nativeView._advertiserView?.isHidden = nativeAd.sponsoredBy == nil
        // Body
        (nativeView._bodyView as? UILabel)?.text = nativeAd.text
        nativeView._bodyView?.isHidden = nativeAd.text == nil
        // Icon IMG
        if let iconString = nativeAd.iconUrl, let iconUrl = URL(string: iconString) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: iconUrl)
                DispatchQueue.main.async {
                    if data != nil {
                        (nativeView._iconView as? UIImageView)?.image = UIImage(data: data!)
                        nativeView._iconView?.isHidden = self.nativeAd.iconUrl == nil
                    }
                }
            }
        }
        // Main IMG
        if let imageMainString = nativeAd.imageUrl,let imageUrl = URL(string: imageMainString) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: imageUrl)
                DispatchQueue.main.async {
                    if data != nil {
                        (nativeView._imageMainView as? UIImageView)?.image = UIImage(data: data!)
                        nativeView._imageMainView?.isHidden = self.nativeAd.imageUrl == nil
                    }
                }
            }
        }
        
        let isCallActionBTN = (nativeView._callToActionView as? UIButton) != nil ? true : false
        if isCallActionBTN {
            (nativeView._callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        } else {
            (nativeView._callToActionView as? UILabel)?.text = nativeAd.callToAction
        }
        nativeView._callToActionView?.isHidden = nativeAd.callToAction == nil
        
        nativeView._starRatingView?.isHidden = true
        nativeView._storeView?.isHidden = true
        nativeView._priceView?.isHidden = true
    }
    
    public func setVideoDelegate(videoDelegate: NativeAdVideoDelegate){
        self.videoDelegate = videoDelegate
    }
    public func setNativeAdDelegate(delegate: NativeAdCustomDelegate){
        self.nativeAdDelegate = delegate
    }
    
    public func destroy(){
        if (self.gadNativeAd != nil) {
            self.gadNativeAd.delegate = nil
            self.gadNativeAd = nil
        }
        if (self.nativeAd != nil) {
            self.nativeAd.delegate = nil
            self.nativeAd = nil
        }
        self.videoDelegate = nil
        self.nativeAdDelegate = nil
    }
    
    // MARK: - Template NativeAd Delegate
    public func adDidExpire(ad: NativeAd) {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' did Expire")
        self.nativeAdDelegate?.nativeAdDidExpire?(data: "ADNativeCustom Placement '\(String(describing: self.placement))' did Expire")
    }
    public func adWasClicked(ad: NativeAd) {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' did record Click")
        self.nativeAdDelegate?.nativeAdDidRecordClick?(data: "ADNativeCustom Placement '\(String(describing: self.placement))' did record Click")
    }
    public func adDidLogImpression(ad: NativeAd) {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' did record Impression")
        self.nativeAdDelegate?.nativeAdDidRecordImpression?(data: "ADNativeCustom Placement '\(String(describing: self.placement))' did record Impression")
    }
    
    // MARK: - UnifiedNativeAd Delegate
    public func nativeAdDidRecordClick(_ nativeAd: GADUnifiedNativeAd) {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' did record Click")
        self.nativeAdDelegate?.nativeAdDidRecordClick?(data: "ADNativeCustom Placement '\(String(describing: self.placement))' did record Click")
    }
    public func nativeAdDidRecordImpression(_ nativeAd: GADUnifiedNativeAd) {
        PBMobileAds.shared.log(logType: .info, "ADNativeCustom Placement '\(String(describing: self.placement))' did record Impression")
        self.nativeAdDelegate?.nativeAdDidRecordImpression?(data: "ADNativeCustom Placement '\(String(describing: self.placement))' did record Impression")
    }
    
    // MARK: - Video Delegate
    /// Tells the delegate that the video controller has began or resumed playing a video.
    public func videoControllerDidPlayVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log(logType: .info, "onVideoPlay: ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.videoDelegate?.onVideoPlay?(data: "onVideoPlay: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has paused video.
    public func videoControllerDidPauseVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log(logType: .info, "onVideoPause: ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.videoDelegate?.onVideoPause?(data: "onVideoPause: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller's video playback has ended.
    public func videoControllerDidEndVideoPlayback(_ videoController: GADVideoController) {
        PBMobileAds.shared.log(logType: .info, "onVideoEnd: ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.videoDelegate?.onVideoEnd?(data: "onVideoEnd: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has muted video.
    public func videoControllerDidMuteVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log(logType: .info, "onVideoMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.videoDelegate?.onVideoMute?(data: "onVideoMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has unmuted video.
    public func videoControllerDidUnmuteVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log(logType: .info, "onVideoUnMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
        self.videoDelegate?.onVideoUnMute?(data: "onVideoUnMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    
}
