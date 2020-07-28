//
//  CMPConsentToolViewController.h
//  GDPR
//

#import <UIKit/UIKit.h>
#import "CMPConsentToolAPI.h"
#import "CloseListener.h"
#import "NetworkErrorListener.h"
#import "CloseListenerDelegate.h"

@class CMPConsentToolViewController;
@protocol CMPConsentToolViewControllerDelegate <NSObject>
- (void)consentToolViewController:(CMPConsentToolViewController *)consentToolViewController didReceiveConsentString:(NSString*)consentString;
@end

@interface CMPConsentToolViewController : UIViewController

/**
 Listener that should be called, if the Web View is being closed
 */
@property (nonatomic, retain) CloseListener *closeListener;

/**
 Listener that should be called, if a network error occurs
 */
@property (nonatomic, retain) NetworkErrorListener *networkErrorListener;

/**
 Object that provides the API for storing and retrieving GDPR-related information
 */
@property (nonatomic, retain) CMPConsentToolAPI *consentToolAPI;

/**
 Optional delegate to receive callbacks from the CMP web tool
 */
@property (nonatomic, weak) id<CMPConsentToolViewControllerDelegate> delegate;

/**
 Optional delegate to receive callbacks from the CMP web tool
 */
@property (nonatomic, weak) id<CloseListenerDelegate> closeDelegate;

@end
