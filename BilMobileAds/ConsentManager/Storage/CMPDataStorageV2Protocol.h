//
//  CMPDataStorageV2Protocol.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "PublisherRestriction.h"

@protocol CMPDataStorageV2Protocol
@required

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *cmpSdkId;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *cmpSdkVersion;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *policyVersion;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *gdprApplies;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *publisherCC;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *tcString;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *vendorConsents;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *vendorLegitimateInterests;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *purposeConsents;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *purposeLegitimateInterests;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *specialFeaturesOptIns;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, assign) NSArray *publisherRestrictions;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *publisherConsent;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *publisherLegitimateInterests;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *publisherCustomPurposesConsent;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSString *publisherCustomPurposesLegitimateInterests;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *purposeOneTreatment;

/**
 The consent string passed as a websafe base64-encoded string.
 */
@property (nonatomic, retain) NSNumber *useNoneStandardStacks;

/**
 Removes all properties form the Storage
 */
-(void)clearContents;

@end
