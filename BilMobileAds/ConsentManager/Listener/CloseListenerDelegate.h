//
//  CloseListenerDelegate.h
//  BilMobileAds
//
//  Created by HNL_MAC on 7/15/20.
//  Copyright © 2020 bil. All rights reserved.
//

@protocol CloseListenerDelegate <NSObject>

- (void)onWebViewClosed:(NSString *)consentStr;

@end
