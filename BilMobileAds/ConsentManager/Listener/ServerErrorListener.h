//
//  ServerErrorListener.h
//  GDPR
//

#import <Foundation/Foundation.h>

/**
 Object that provides the interface for storing and retrieving GDPR-related information
 */
@interface ServerErrorListener : NSObject

/**
 This function is called, when the the user accepted or rejected the Webview and the WebView is closed
 */
- (void)onErrorOccur:(NSString *)message;


@end
