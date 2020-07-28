//
//  CMPDataStorageProtocol.h
//  GDPR
//

#import <Foundation/Foundation.h>

@protocol CMPDataStorageConsentManagerProtocol
@required

/**
 The consent string passed as a websafe base64-encoded string given by consentmanager.
 */
@property (nonatomic, retain) NSString *consentString;

/**
 String that contains the consent information for all vendors set by consentmanager
 */
@property (nonatomic, retain) NSString *parsedVendorConsents;

/**
 String that contains the consent information for all purposes set by consentmanager
 */
@property (nonatomic, retain) NSString *parsedPurposeConsents;

/**
 String that contains the US_Privacy as a String content
 */
@property (nonatomic, retain) NSString *usPrivacyString;

/**
 Removes all properties form the Storage
 */
-(void)clearContents;

@end
