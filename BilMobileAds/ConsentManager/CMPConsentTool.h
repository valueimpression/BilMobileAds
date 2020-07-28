//
//  CMPConsentTool.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPConfig.h"
#import "CloseListener.h"
#import "CloseListenerDelegate.h"
#import "OpenListener.h"
#import "NetworkErrorListener.h"
#import "ServerErrorListener.h"
#import "CustomOpenListener.h"
#import "CMPServerResponse.h"
#import <UIKit/UIKit.h>

/**
 Object that needs to be initalised when starting the App
 */
@interface CMPConsentTool : NSObject

/**
 The singleton CMPConsentToolInstance
 */
extern CMPConsentTool *consentTool;

/**
 Returns the Config set to the CMPConsentTool while initialisation
 */
@property (nonatomic, retain) CMPConfig *cmpConfig;

/**
 The View Controler, the Web View schould shown onto.
 */
@property (nonatomic, retain) UIViewController *viewController;

/**
 This listener will be called, if the View of the consentTool will be closed
 */
@property (nonatomic, retain) CloseListener *closeListener;

/**
This Delegate will be called, if the View of the consentTool will be closed
*/
@property (nonatomic, weak) id<CloseListenerDelegate> closeDelegate;


/**
 This listener will be called, if the View of the consentTool will be opened
 */
@property (nonatomic, retain) OpenListener *openListener;

/**
 If this listener is set, this listener will be called, apart from openening an own View
 */
@property (nonatomic, retain) CustomOpenListener *customOpenListener;

/**
 This listener will be called, if an error occurs while calling the Server or showing the view.
 */
@property (nonatomic, retain) NetworkErrorListener *networkErrorListener;

/**
 The last Response that was send by consentmanager Server
 */
@property (nonatomic, retain) CMPServerResponse *cmpServerResponse;

/**
 This listener will be called, if an error message will be returned from the consentmanager Server
 */
@property (nonatomic, retain) ServerErrorListener *serverErrorListener;

/**
 Displays a modal view with the consent web view. If the Compliance is accepted or rejected,
 a close function will be called. You can overrride this close function with your own. Therefor
 implement the closeListener and add this as a parameter.
 */
- (void)openCmpConsentToolView;

/**
 Displays a modal view with the consent web view. If the Compliance is accepted or rejected,
 a close function will be called. You can overrride this close function with your own. Therefor
 implement the closeListener and give it to this function. This Method will not send a request
 to the ConsentTool Server again. It will use the last state. If you only want to open the consent
 Tool View again, if the server gives a response status ==1 use the checkAndProceedConsentUpdate
 method.
 */
- (void)openCmpConsentToolView:(CloseListener*) closeListener;

/**
 Returns the Vendors String, that was set by consentmanager
 */
- (NSString*)getVendorsString;

/**
 Returns the Purposes String, that was set by consentmanager
 */
- (NSString*)getPurposesString;

/**
 Returns the US Privacy String, that was set by consentmanager
 */
- (NSString*)getUSPrivacyString;

- (BOOL)needShowCMP;

/**
 Returns if a given Vendor has the rights to set cookies
 */
- (BOOL)hasVendorConsent:(NSString *)vendorId vendorIsV1orV2:(BOOL)isIABVendor;

/**
 Returns if under a given Purpose the rights to set cookies are given
 */
- (BOOL)hasPurposeConsent:(NSString *)purposeId purposeIsV1orV2:(BOOL)isIABPurpose;

/**
 Creates a new instance of this CMPConsentTool. This Constructor is initiating the CMPConfig singleton instance with all the required parameters
 */
- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController;

/**
Creates a new instance of this CMPConsentTool. This Constructor is taking the self constructed CMPConfig Singleton instance
*/
- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController;


@end
