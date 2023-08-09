//
//  ViewController.swift
//  BilMobileAdsTest
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import UIKit
import BilMobileAds

class ViewController: UIViewController, ADBannerDelegate, ADInterstitialDelegate, ADRewardedDelegate, ADNativeStyleDelegate, NativeAdCustomDelegate, NativeAdVideoDelegate {
    
    @IBOutlet weak var bannerView1: UIView!
    @IBOutlet weak var bannerView2: UIView!
    
    private var banner: ADBanner!
    private var interstitialAD: ADInterstitial!
    private var rewardedAD: ADRewarded!
    private var nativeStyle: ADNativeStyle!
    private var nativeCustom: ADNativeCustom!
    
    var adManager: AdManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView1.backgroundColor = .blue
        bannerView2.backgroundColor = .red
        
//        banner = ADBanner(self, view: bannerView1, placement: "eea66d76-c12c-446b-a9b0-bdb2f39e0dac")
        
        interstitialAD = ADInterstitial(self,  placement: "6e02e904-0306-4efe-90eb-3538ae4b4fc0")
        
//        rewardedAD = ADRewarded(self, placement: "1003")
        
//        nativeStyle = ADNativeStyle(self, view: bannerView2, placement: "1004")
        
//        adManager = AdManager()
//        nativeCustom = ADNativeCustom(self, placement: "1004")
//        nativeCustom.setListener(adManager)
//        adManager.setNativeObj(nativeCus: nativeCustom)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //        banner?.destroy()
        //        interstitialAD?.destroy()
        //        rewardedAD?.destroy()
        //        nativeStyle?.destroy()
        //        nativeCustom?.destroy()
    }
    
    @IBAction func preloadIntersititial(_ sender: Any) {
        interstitialAD?.preLoad()
    }
    
    @IBAction func showIntersitial(_ sender: Any) {
        interstitialAD?.show()
    }
    
    @IBAction func preloadRewarded(_ sender: UIButton) {
        rewardedAD?.preLoad()
    }
    
    @IBAction func showRewarded(_ sender: Any) {
        rewardedAD?.show()
    }
    
    @IBAction func showBannerSimple(_ sender: Any) {
        banner.load()
//        bannerView1.isHidden
//        let frm: CGRect = bannerView1.frame
//        bannerView1.frame = CGRect( x: frm.origin.x + 50, y: frm.origin.y, width: bannerView1.frame.size.width, height: bannerView1.frame .size.height)
    }
    
    @IBAction func stopBanner(_ sender: Any) {
        banner?.destroy()
    }
    
    @IBAction func loadNativeCus(_ sender: Any) {
        adManager.load()
    }
    
    // MARK: - Native Ads
    var nativeAdView: UIView?
    var nativeViewBuilder: ADNativeViewBuilder?
    func setAdView(_ view: UIView) {
        /// Remove the previous ad view.
        nativeAdView?.removeFromSuperview()
        nativeAdView = view
        nativeAdView!.translatesAutoresizingMaskIntoConstraints = false
        bannerView2.addSubview(nativeAdView!)
        
        /// Layout constraints for positioning the native ad view to stretch the entire width and height of the nativeAdPlaceholder.
        let viewDictionary = ["_nativeAdView": nativeAdView!]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
    }
    @IBAction func ShowNativeCus(_ sender: Any) {
        /// Get native asset
        guard let viewBuilder = adManager.getNativeViewBuilder() else {
            print("Native unavailable, load ad before show")
            return
        }
        self.removePreviousAds()
        
        self.nativeViewBuilder = viewBuilder

        /// Create and place ad in view hierarchy.
        let nibView = Bundle.main.loadNibNamed("ADNativeViewCustom", owner: nil, options: nil)?.first
        guard let nativeAdViewCustom = nibView as? ADNativeViewCustom else {
            return
        }
        self.setAdView(nativeAdViewCustom)

        viewBuilder.setVideoDelegate(videoDelegate: self)
        viewBuilder.setNativeAdDelegate(delegate: self)
        viewBuilder.build(nativeView: nativeAdViewCustom)
    }
    func removePreviousAds() {
        if self.nativeViewBuilder != nil {
            self.nativeViewBuilder?.destroy()
            self.nativeViewBuilder = nil
        }
        nativeAdView = nil
    }
    
    // MARK: - Native Custom Delegate
    func nativeAdDidExpire(data: String) {
        print("adDidExpire")
    }
    func nativeAdDidRecordImpression(data: String) {
        print("adDidLogImpression")
    }
    func nativeAdDidRecordClick(data: String) {
        print("adWasClicked")
    }
    
    // MARK: - Rewarded Delegate
    func rewardedUserDidEarn(rewardedItem: ADRewardedItem) {
        print("rewardedUserDidEarn Placement: \(rewardedItem.getAmount().doubleValue)")
    }
    func rewardedDidReceiveAd(data: String) {
        print("rewardedDidReceiveAd Placement: \(data)")
    }
    func rewardedFailToLoad(data: String) {
        print("rewardedFailToLoad: \(data)")
    }
    func rewardedFailToPresent(data: String) {
        print("rewardedFailToPresent: \(data)")
    }
    func rewardedDidPresent(data: String) {
        print("rewardedDidPresent: \(data)")
    }
    func rewardedDidDismiss(data: String) {
        print("rewardedDidDismiss: \(data)")
    }
    
    // MARK: - FullAD Delegate
    func interstitialDidReceiveAd(data: String) {
        print("interstitialDidReceiveAd: \(data)")
    }
    func interstitialWillLeaveApplication(data: String) {
        print("interstitialWillLeaveApplication: \(data)")
    }
    func interstitialDidDismissScreen(data: String) {
        print("rewardedAdFailToPresent: \(data)")
    }
    func interstitialLoadFail(error: String) {
        print("interstitialLoadingFail: \(error)")
    }
    
    // MARK: - Banner Delegate
    func bannerDidReceiveAd(data: String) {
        print("Banner Placement: \(data) with Width:\(banner.getWidthInPixels()) | Height: \(banner.getHeightInPixels())")
    }
    func bannerWillLeaveApplication(data: String) {
        print("bannerWillLeaveApplication: \(data)")
    }
    func bannerWillDismissScreen(data: String) {
        print("bannerWillDismissScreen: \(data)")
    }
}
