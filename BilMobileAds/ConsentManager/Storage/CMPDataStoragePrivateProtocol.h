//
//  CMPDataStoragePrivateProtocol.h
//  GDPR
//

#import <Foundation/Foundation.h>

@protocol CMPDataStoragePrivateProtocol
@required

/**
 The consent string passed as a websafe base64-encoded string given by consentmanager.
 */
@property (nonatomic, retain) NSString *consentToolUrl;

/**
 String that contains when the consentmanager Server was last Requested
 */
@property (nonatomic, retain) NSString *lastRequested;


/**
 Removes all properties form the Storage
 */
-(void)clearContents;

@end
