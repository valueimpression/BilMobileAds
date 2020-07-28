//
//  PublisherRestriction.m
//  GDPR
//

#import "PublisherRestriction.h"

@implementation PublisherRestriction

@synthesize restrictionType;
@synthesize purposeId;
@synthesize vendorIds;


-(id)init:(NSInteger *)pId type:(NSInteger *)rType vendors:(NSString*)vIds{
    restrictionType = rType;
    purposeId = pId;
    vendorIds = vIds;
    
    return self;
}

- (NSString *)vendorIds{
    return vendorIds;
}

- (NSInteger *)purposeId{
    return purposeId;
}

- (NSInteger *)restrictionType{
    return restrictionType;
}

- (void)setVendorIds:(NSString *)vId{
    vendorIds = vId;
}

- (void)setPurposeId:(NSInteger *)pId{
    purposeId = pId;
}

- (void)setRestrictionType:(NSInteger *)rType{
    restrictionType = rType;
}
@end
