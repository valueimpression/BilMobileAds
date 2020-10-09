//
//  ViewController.swift
//  BilMobileAdsTest
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import UIKit
import BilMobileAds

class ViewController: UIViewController, ADBannerDelegate, ADInterstitialDelegate, ADRewardedDelegate, ADNativeDelegate, ADNativeVideoDelegate {
    
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
        
        // banner = ADBanner(self, view: bannerView1, placement: "1001")
        
        // interstitialAD = ADInterstitial(self, placement: "1002")
        
        // rewardedAD = ADRewarded(self, placement: "1003");
        
        // nativeStyle = ADNativeStyle(self, view: bannerView1, placement: "1004")
        
        nativeCustom = ADNativeCustom(self, placement: "1004")
        adManager = AdManager(nativeCus: nativeCustom)
        nativeCustom.setListener(adManager)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        banner?.destroy()
        interstitialAD?.destroy()
        rewardedAD?.destroy()
        nativeStyle?.destroy()
        nativeCustom?.destroy()
    }
    
    @IBAction func preloadIntersititial(_ sender: Any) {
        interstitialAD?.preLoad()
    }
    
    @IBAction func showIntersitial(_ sender: Any) {
        interstitialAD?.load()
    }
    
    @IBAction func preloadRewarded(_ sender: UIButton) {
        rewardedAD?.preLoad()
    }
    
    @IBAction func showRewarded(_ sender: Any) {
        rewardedAD?.load()
    }
    
    @IBAction func showBannerSimple(_ sender: Any) {
        banner?.load()
    }
    
    @IBAction func stopBanner(_ sender: Any) {
        banner?.destroy()
    }
    
    @IBAction func loadNativeCus(_ sender: Any) {
        adManager.load()
    }
    
    var nativeAdView: UIView?
    func setAdView(_ view: UIView) {
        /// Remove the previous ad view.
        nativeAdView?.removeFromSuperview()
        nativeAdView = view
        bannerView2.addSubview(nativeAdView!)
        nativeAdView!.translatesAutoresizingMaskIntoConstraints = false
        
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
        // Get native asset
        guard let viewBuilder = adManager.getNativeViewBuilder() else {
            print("Native unavailable, load ad before show")
            return
        }
        
        /// Create and place ad in view hierarchy.
        let nibView = Bundle.main.loadNibNamed("ADNativeViewCustom", owner: nil, options: nil)?.first
        guard let nativeAdView = nibView as? ADNativeViewCustom else {
            return
        }
        setAdView(nativeAdView)
        
        viewBuilder.setVideoDelegate(videoDelegate: self)
        viewBuilder.build(nativeView: nativeAdView)
    }
    
    // MARK: - Native Delegate
    func nativeViewLoaded(viewBuilder: ADNativeViewBuilder) {
        print("nativeViewLoaded Placement: \(String(describing: viewBuilder.placement))")
    }
    
    func nativeAdDidRecordImpression(data: String) {
        print("nativeAdDidRecordImpression Placement: \(data)")

    }
    
    func nativeAdDidRecordClick(data: String) {
        print("nativeAdDidRecordImpression Placement: \(data)")
    }
    
    // MARK: - Rewarded Delegate
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
        print("Placement: \(data)")
    }
    func bannerWillLeaveApplication(data: String) {
        print("bannerWillLeaveApplication: \(data)")
    }
    func bannerWillDismissScreen(data: String) {
        print("bannerWillDismissScreen: \(data)")
    }
}

