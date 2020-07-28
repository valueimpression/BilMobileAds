//
//  TestShowCMP.m
//  BilMobileAds
//
//  Created by HNL_MAC on 7/14/20.
//  Copyright © 2020 bil. All rights reserved.
//

#import "ShowCMP.h"

@implementation ShowCMP

static CMPConsentTool *cmpConsentTool = nil;

- (void)openCMP:(UIViewController*) uiViewCtr appName:(nonnull NSString *)appName {
    cmpConsentTool = [[CMPConsentTool alloc] init:@"consentmanager.mgr.consensu.org" addId:@"15029" addAppName:appName addLanguage:@"EN" addViewController:uiViewCtr];
    cmpConsentTool.closeDelegate = self.closeDelegate;
    [self showCMP];
}

- (void)showCMP {
    [cmpConsentTool openCmpConsentToolView];
}

@end
