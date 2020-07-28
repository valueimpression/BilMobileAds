//
//  TestShowCMP.h
//  BilMobileAds
//
//  Created by HNL_MAC on 7/14/20.
//  Copyright © 2020 bil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CloseListenerDelegate.h"
#import "CMPConsentTool.h"
#import "CMPConsentToolAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowCMP : NSObject

@property (nonatomic, weak) id<CloseListenerDelegate> closeDelegate;

- (void) openCMP:(UIViewController*) uiViewCtr appName:(NSString*) appName;

@end

NS_ASSUME_NONNULL_END
