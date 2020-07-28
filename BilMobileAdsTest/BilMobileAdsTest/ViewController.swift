//
//  ViewController.swift
//  BilMobileAdsTest
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import UIKit
import BilMobileAds

class ViewController: UIViewController, ADBannerDelegate, ADInterstitialDelegate, ADRewardedDelegate {
    
    @IBOutlet weak var bannerView1: UIView!
    @IBOutlet weak var bannerView2: UIView!
    
    private var banner: ADBanner!
    private var interstitialAD: ADInterstitial!
    private var rewardedAD: ADRewarded!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView1.backgroundColor = .blue
        bannerView2.backgroundColor = .red
        
        banner = ADBanner(self, view: bannerView2, placement: "1001")
        banner.setAdSize(size: .Banner300x250)
        banner.setAutoRefreshMillis(timeMillis: 30000)

//        interstitialAD = ADInterstitial(self, placement: "1002")
//        interstitialAD.preLoad()
        
//        rewardedAD = ADRewarded(self, placement: "1003");
//        rewardedAD.preLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        banner?.destroy()
    }
    
    @IBAction func preloadIntersititial(_ sender: Any) {
        interstitialAD = ADInterstitial(self, placement: "1002")
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
    
    // MARK: - Rewarded Listener
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
    
    // MARK: - FullAD Listener
    func interstitialDidReceiveAd(data: String) {
        print("interstitialDidReceiveAd: \(data)")
    }
    func interstitialWillLeaveApplication(data: String) {
        print("interstitialWillLeaveApplication: \(data)")
    }
    func interstitialDidDismissScreen(data: String) {
        print("rewardedAdFailToPresent: \(data)")
    }
    func interstitialLoadFail(data: String) {
        print("interstitialLoadingFail: \(data)")
    }
        
    // MARK: - Banner Listener
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

