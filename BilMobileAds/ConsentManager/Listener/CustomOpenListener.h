//
//  CustomOpenListener.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPServerResponse.h"
#import "CMPSettings.h"

/**
 Object that provides the interface for storing and retrieving GDPR-related information
 */
@interface CustomOpenListener : NSObject

/**
 This function is called, when the the user accepted or rejected the Webview and the WebView is closed
 */
- (void)onOpenCMPConsentToolActivity:(CMPServerResponse *)response withSettings:(CMPSettings *)settings;


@end
