//
//  ADNativeView.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 9/22/20.
//  Copyright © 2020 bil. All rights reserved.
//

import GoogleMobileAds

@objc public class ADNativeViewBuilder: NSObject, GADVideoControllerDelegate {
    
    public let placement: String!
    var nativeAd: GADUnifiedNativeAd!
    var videoDelegate: ADNativeVideoDelegate!
    
    init(placement: String, unifiedNativeAd: GADUnifiedNativeAd) {
        self.placement = placement
        self.nativeAd = unifiedNativeAd
    }
    
    /// Returns a `UIImage` representing the number of stars from the given star rating; returns `nil`
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
        /// Populate the native ad view with the native ad assets. The headline and mediaContent are guaranteed to be present in every native ad.
        (nativeView._headlineView as? UILabel)?.text = nativeAd.headline
        
        nativeView._mediaView?.mediaContent = nativeAd.mediaContent
        if (nativeAd.mediaContent.hasVideoContent) {
            /// By acting as the delegate to the GADVideoController, this ViewController receives message about events in the video lifecycle.
            nativeAd.mediaContent.videoController.delegate = self
        }
        /// This app uses a fixed width for the GADMediaView and changes its height to match the aspect ratio of the media it displays.
        if let mediaView = nativeView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(item: mediaView,
                                                      attribute: .height,
                                                      relatedBy: .equal,
                                                      toItem: mediaView,
                                                      attribute: .width,
                                                      multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
                                                      constant: 0)
            heightConstraint.isActive = true
        }
        
        /// These assets are not guaranteed to be present. Check that they are before showing or hiding them.
        (nativeView._bodyView as? UILabel)?.text = nativeAd.body
        nativeView._bodyView?.isHidden = nativeAd.body == nil
        
        (nativeView._callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        let isCallActionBTN = (nativeView._callToActionView as? UIButton) != nil ? true : false
        if isCallActionBTN {
            (nativeView._callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        } else {
            (nativeView._callToActionView as? UILabel)?.text = nativeAd.callToAction
        }
        nativeView._callToActionView?.isHidden = nativeAd.callToAction == nil
        /// In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeView._callToActionView?.isUserInteractionEnabled = false
        
        (nativeView._iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeView._iconView?.isHidden = nativeAd.icon == nil
        
        let isStarIMG = (nativeView._starRatingView as? UIImageView) != nil ? true : false
        if isStarIMG {
            (nativeView._starRatingView as? UIImageView)?.image = imageOfStars(fromStarRating: nativeAd.starRating)
        } else {
            (nativeView._starRatingView as? UILabel)?.text = "\(String(describing: nativeAd.starRating)) ✭"
        }
        nativeView._starRatingView?.isHidden = nativeAd.starRating == nil
        
        (nativeView._storeView as? UILabel)?.text = nativeAd.store
        nativeView._storeView?.isHidden = nativeAd.store == nil
        
        (nativeView._priceView as? UILabel)?.text = nativeAd.price
        nativeView._priceView?.isHidden = nativeAd.price == nil
        
        (nativeView._advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeView._advertiserView?.isHidden = nativeAd.advertiser == nil
        
        /// Associate the native ad view with the native ad object. This is required to make the ad clickable.
        /// Note: this should always be done after populating the ad views.
        nativeView.nativeAd = nativeAd
    }
    
    public func setVideoDelegate(videoDelegate: ADNativeVideoDelegate){
        self.videoDelegate = videoDelegate
    }
    
    public func destroy(){
        if (self.nativeAd != nil) { self.nativeAd = nil }
        self.videoDelegate = nil
    }
    
    // MARK: - Delegate
    /// Tells the delegate that the video controller has began or resumed playing a video.
    public func videoControllerDidPlayVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log("nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.videoDelegate?.onVideoPlay?(data: "nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has paused video.
    public func videoControllerDidPauseVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log("nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.videoDelegate?.onVideoPause?(data: "nativeAdDidRecordImpression: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller's video playback has ended.
    public func videoControllerDidEndVideoPlayback(_ videoController: GADVideoController) {
        PBMobileAds.shared.log("onVideoEnd: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.videoDelegate?.onVideoEnd?(data: "onVideoEnd: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has muted video.
    public func videoControllerDidMuteVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log("onVideoMute: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.videoDelegate?.onVideoMute?(data: "onVideoMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    /// Tells the delegate that the video controller has unmuted video.
    public func videoControllerDidUnmuteVideo(_ videoController: GADVideoController) {
        PBMobileAds.shared.log("onVideoUnMute: ADNativeCustom Placement '\(String(describing: self.placement))'");
        self.videoDelegate?.onVideoUnMute?(data: "onVideoUnMute: ADNativeCustom Placement '\(String(describing: self.placement))'")
    }
    
}
