//
//  PublisherRestriction.h
//  GDPR
//

#import <Foundation/Foundation.h>

/**
 Object that provides the interface for storing and retrieving GDPR-related information
 */
@interface PublisherRestriction : NSObject

/**
 The purposeID of the restriction
 */
@property (nonatomic, assign) NSInteger *purposeId;

/**
 The restrictionType set to this restriction
 */
@property (nonatomic, assign)  NSInteger *restrictionType;

/**
 The Vendors which needs a consent for this restriction
 */
@property (nonatomic, retain)  NSString *vendorIds;

-(id)init:(NSInteger *)pId type:(NSInteger *)rType vendors:(NSString*)vIds;

- (NSString *)vendorIds;

- (NSInteger *)purposeId;

- (NSInteger *)restrictionType;

- (void)setVendorIds:(NSString *)vId;

- (void)setPurposeId:(NSInteger *)pId;

- (void)setRestrictionType:(NSInteger *)rType;
@end
