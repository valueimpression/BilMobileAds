//
//  CMPConsentV2Parser.m
//  GDPR
//

#import "CMPConsentV1Constant.h"

#import "CMPConsentV2Parser.h"
#import "CMPConsentV2Constant.h"
#import "CMPConsentToolUtil.h"


@implementation CMPConsentV2Parser

@synthesize cmpSdkId;
@synthesize cmpSdkVersion;
@synthesize gdprApplies;
@synthesize purposeOneTreatment;
@synthesize useNoneStandardStacks;
@synthesize publisherCC;
@synthesize vendorConsents;
@synthesize vendorLegitimateInterests;
@synthesize purposeConsents;
@synthesize purposeLegitimateInterests;
@synthesize specialFeaturesOptIns;
@synthesize publisherRestrictions;
@synthesize publisherConsent;
@synthesize publisherLegitimateInterests;
@synthesize publisherCustomPurposesConsent;
@synthesize publisherCustomPurposesLegitimateInterests;
@synthesize policyVersion;
@synthesize cmpAllowedVendors;
@synthesize cmpDisclosedVendors;
@synthesize version;
@synthesize created;
@synthesize lastUpdated;
@synthesize consentScreen;
@synthesize consentLanguage;
@synthesize vendorListVersion;
@synthesize isServiceSpecific;

-(id)init:(NSString *)consentString{
    NSArray *splits = [consentString componentsSeparatedByString:@"."];
    
    NSString *coreString = splits[0];
    NSString *disclosedVendors = nil;
    NSString *allowedVendors = nil;
    NSString *publisherTC = nil;
    
    for(int i = 1; i < splits.count; i++ ){
        unsigned char *buffer = [CMPConsentToolUtil binaryConsentFrom:splits[i]];
        if (!buffer) {
            return self;
        }
        NSInteger segmentType = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:SEGMENT_TYPE_BIT_OFFSET length:SEGMENT_TYPE_BIT_LENGTH];
        switch (segmentType) {
            case 1:
                disclosedVendors = splits[i];
                break;
            case 2:
                allowedVendors = splits[i];
                break;
            case 3:
                publisherTC = splits[i];
                break;
            default:
                NSLog(@"%@", splits[i]);
                break;
        }
    }
    unsigned char *buffer = [CMPConsentToolUtil binaryConsentFrom:coreString];
    
    if (!buffer) {
        return self;
    }
    version = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:VERSION_BIT_OFFSET length:VERSION_BIT_LENGTH];
    created = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:CREATED_BIT_OFFSET length:CREATED_BIT_LENGTH];
    lastUpdated = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:LAST_UPDATED_BIT_OFFSET length:LAST_UPDATED_BIT_LENGTH];
    cmpSdkId = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:CMP_ID_BIT_OFFSET length:CMP_ID_BIT_LENGTH];
    cmpSdkVersion = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:CMP_VERSION_BIT_OFFSET length:CMP_VERSION_BIT_LENGTH];
    consentScreen = [CMPConsentToolUtil BinaryToString:buffer fromIndex:CONSENT_SCREEN_BIT_OFFSET length:CONSENT_SCREEN_BIT_LENGTH];
    consentLanguage = [CMPConsentToolUtil BinaryToString:buffer fromIndex:CONSENT_LANGUAGE_BIT_OFFSET length:CONSENT_LANGUAGE_BIT_LENGTH];
    vendorListVersion = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:VENDOR_LIST_VERSION_BIT_OFFSET length:VENDOR_LIST_VERSION_BIT_LENGTH];
    policyVersion = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:TCF_POLICY_VERSION_BIT_OFFSET length:TCF_POLICY_VERSION_BIT_LENGTH];
    isServiceSpecific = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:IS_SERVICE_SPECIFIC_BIT_OFFSET length:IS_SERVICE_SPECIFIC_BIT_LENGTH];
    useNoneStandardStacks = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:USE_NON_STANDARD_STACK_BIT_OFFSET length:USE_NON_STANDARD_STACK_BIT_LENGTH];
    specialFeaturesOptIns = [CMPConsentToolUtil BinaryToString:buffer fromIndex:SPECIAL_FEATURE_OPT_INS_BIT_OFFSET length:SPECIAL_FEATURE_OPT_INS_BIT_LENGTH];
    purposeConsents = [CMPConsentToolUtil BinaryToString:buffer fromIndex:SPECIAL_FEATURE_OPT_INS_BIT_OFFSET length:SPECIAL_FEATURE_OPT_INS_BIT_LENGTH];
    purposeLegitimateInterests = [CMPConsentToolUtil BinaryToString:buffer fromIndex:PURPOSE_LI_TRANSPARENCY_BIT_OFFSET length:PURPOSE_LI_TRANSPARENCY_BIT_LENGTH];
    purposeOneTreatment = [CMPConsentToolUtil BinaryToNumber:buffer fromIndex:PURPOSE_ONE_TREATMENT_BIT_OFFSET length:PURPOSE_ONE_TREATMENT_BIT_LENGTH];
    publisherCC = [CMPConsentToolUtil BinaryToString:buffer fromIndex:PUPBLISHER_CC_BIT_OFFSET length:PUPBLISHER_CC_BIT_LENGTH];
    
    NSInteger maxVendor = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:MAX_VENDOR_BIT_OFFSET  length:MAX_VENDOR_BIT_LENGTH];
    NSInteger isRangeEncoded = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:MAX_VENDOR_IS_RANGE_ENCODED_BIT_OFFSET length:MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH];
    
    NSInteger offset = MAX_VENDOR_IS_RANGE_ENCODED_BIT_OFFSET + MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH;
    
    if( isRangeEncoded == 0){
        vendorConsents = [CMPConsentToolUtil BinaryToString:buffer fromIndex:(int)offset length:(int)maxVendor];
    } else {
        vendorConsents = [CMPConsentV2Parser extractRangeFieldSection:buffer fromIndex:&offset];
    }
    
    maxVendor = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_BIT_LENGTH];
    offset+= MAX_VENDOR_BIT_LENGTH;
    isRangeEncoded = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH];
    offset += MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH;
    
    if( isRangeEncoded == 0){
        vendorLegitimateInterests = [CMPConsentToolUtil BinaryToString:buffer fromIndex:(int)offset length:(int)maxVendor];
    } else {
        vendorLegitimateInterests = [CMPConsentV2Parser extractRangeFieldSection:buffer fromIndex:&offset];
    }
    
    NSInteger numPubRestrictions = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:NUM_PUB_RESTRICTIONS_BIT_LENGTH];
    offset += NUM_PUB_RESTRICTIONS_BIT_LENGTH;
    
    NSMutableArray<PublisherRestriction *> *pRestrictions = [NSMutableArray array];
    for(int i = 0; i <= numPubRestrictions; i++){
        NSInteger purposeId = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:PURPOSE_ID_BIT_LENGTH];
        offset += PURPOSE_ID_BIT_LENGTH;
        
        NSInteger restrictionType = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:RESTRICTION_TYPE_BIT_LENGTH];
        offset += RESTRICTION_TYPE_BIT_LENGTH;
        
        NSString *vendorIds = [CMPConsentV2Parser extractRangeFieldSection:buffer fromIndex:&offset];
        
        [pRestrictions addObject:[[PublisherRestriction alloc] init:&purposeId type:&restrictionType vendors:vendorIds]];
    }
    
    publisherRestrictions = pRestrictions;
    
    if( allowedVendors != nil){
        unsigned char *buffer = [CMPConsentToolUtil binaryConsentFrom:allowedVendors];
        
        if (!buffer) {
            return self;
        }
        offset = 3;
        maxVendor = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_BIT_LENGTH];
        offset+= MAX_VENDOR_BIT_LENGTH;
        isRangeEncoded = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH];
        offset += MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH;
        
        if( isRangeEncoded == 0){
            cmpAllowedVendors = [CMPConsentToolUtil BinaryToString:buffer fromIndex:(int)offset length:(int)maxVendor];
        } else {
            cmpAllowedVendors = [CMPConsentV2Parser extractRangeFieldSection:buffer fromIndex:&offset];
        }
    }
    
    if( disclosedVendors != nil){
        unsigned char *buffer = [CMPConsentToolUtil binaryConsentFrom:disclosedVendors];
        
        if (!buffer) {
            return self;
        }
        
        offset = 3;
        maxVendor = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_BIT_LENGTH];
        offset+= MAX_VENDOR_BIT_LENGTH;
        isRangeEncoded = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)offset length:MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH];
        offset += MAX_VENDOR_IS_RANGE_ENCODED_BIT_LENGTH;
        
        if( isRangeEncoded == 0){
            cmpDisclosedVendors = [CMPConsentToolUtil BinaryToString:buffer fromIndex:(int)offset length:(int)maxVendor];
        } else {
            cmpDisclosedVendors = [CMPConsentV2Parser extractRangeFieldSection:buffer fromIndex:&offset];
        }
    }
    
    if( publisherTC != nil){
        unsigned char *buffer = [CMPConsentToolUtil binaryConsentFrom:disclosedVendors];
        
        if (!buffer) {
            return self;
        }
        publisherConsent = [CMPConsentToolUtil BinaryToString:buffer fromIndex:PUB_PURPOSE_CONSENTS_BIT_OFFSET length:PUB_PURPOSE_CONSENTS_BIT_LENGTH];
        publisherLegitimateInterests = [CMPConsentToolUtil BinaryToString:buffer fromIndex:PUB_PURPOSE_LI_TRANSPARENCY_BIT_OFFSET length:PUB_PURPOSE_LI_TRANSPARENCY_BIT_LENGTH];
        
        NSInteger numCustomPupose = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:NUM_CUSTOM_PURPOSES_BIT_OFFSET length:NUM_CUSTOM_PURPOSES_BIT_LENGTH];
        
        int offset = NUM_CUSTOM_PURPOSES_BIT_OFFSET + NUM_CUSTOM_PURPOSES_BIT_LENGTH;
        publisherCustomPurposesConsent = [CMPConsentToolUtil BinaryToString:buffer fromIndex:offset length:(int)numCustomPupose];
        
        offset += numCustomPupose;
        publisherCustomPurposesLegitimateInterests = [CMPConsentToolUtil BinaryToString:buffer fromIndex:offset length:(int)numCustomPupose];
    }
    return self;
}

+ (NSString *)extractRangeFieldSection:(unsigned char*)buffer fromIndex:(NSInteger *)startIndex{
    NSInteger entries = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)startIndex  length:12];
    *startIndex += 12;
    
    NSMutableString *value = [NSMutableString new];
    for( int i = 0; i< entries; i++){
        NSInteger isARange = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)startIndex  length:1];
        *startIndex += 1;
        NSInteger startOrOnlyVendorId = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)startIndex  length:16];
        *startIndex += 16;
        if(isARange == 1){
            NSInteger endVendorId = [CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:(int)startIndex  length:16];
            
            //Its possible to catch Errors in Consent String here
            *startIndex += 16;
            [value appendString:[CMPConsentV2Parser getBitRangeExtension:value fromIndex:(int)startOrOnlyVendorId toIndex:(int)endVendorId]];
            
        } else {
            [value appendString:[CMPConsentV2Parser getBitExtension:value toIndex:(int)startOrOnlyVendorId]];
        }
    }
    
    return value;
}

+ (NSString *)getBitExtension:(NSMutableString *)value toIndex:(int)toIndex{
    NSMutableString *extract = [NSMutableString new];
    int characterCount = (int)[value length];
    for( int i = characterCount; i <= toIndex; i++ ){
        [extract appendString:@"0"];
    }
    [extract appendString:@"1"];
    return extract;
}

+ (NSString *)getBitRangeExtension:(NSMutableString *)value fromIndex:(int)fromIndex toIndex:(int)toIndex{
    NSMutableString *extract = [NSMutableString new];
    [extract appendString:[CMPConsentV2Parser getBitExtension:value toIndex:(int)fromIndex]];
    
    int characterCount = (int)[value length];
    for( int i = characterCount; i <= toIndex + 1; i++ ){
        [extract appendString:@"1"];
    }
    return extract;
}

- (NSNumber *)cmpSdkId{
    return cmpSdkId;
}
- (NSNumber *)cmpSdkVersion{
    return cmpSdkVersion;
}
- (NSNumber *)gdprApplies{
    return gdprApplies;
}
- (NSNumber *)purposeOneTreatment{
    return purposeOneTreatment;
}
- (NSNumber *)useNoneStandardStacks{
    return useNoneStandardStacks;
}
- (NSString *)publisherCC{
    return publisherCC;
}
- (NSString *)vendorConsents{
    return vendorConsents;
}
- (NSString *)vendorLegitimateInterests{
    return vendorLegitimateInterests;
}
- (NSString *)purposeConsents{
    return purposeConsents;
}
- (NSString *)purposeLegitimateInterests{
    return purposeLegitimateInterests;
}
- (NSString *)specialFeaturesOptIns{
    return specialFeaturesOptIns;
}
- (NSArray<PublisherRestriction *> *)publisherRestrictions{
    return publisherRestrictions;
}
- (NSString *)publisherConsent{
    return publisherConsent;
}
- (NSString *)puplisherLegitimateInterests{
    return publisherLegitimateInterests;
}
- (NSString *)publisherCustomPurposesConsent{
    return publisherCustomPurposesConsent;
}
- (NSString *)publisherCustomPurposesLegitimateInterests{
    return publisherCustomPurposesLegitimateInterests;
}
- (NSNumber *)policyVersion{
    return policyVersion;
}
- (NSString *)cmpAllowedVendors{
    return cmpAllowedVendors;
}
- (NSString *)cmpDisclosedVendors{
    return cmpDisclosedVendors;
}

- (NSNumber *)version{
    return version;
}
- (NSNumber *)created{
    return created;
}
- (NSNumber *)lastUpdated{
    return lastUpdated;
}
- (NSString *)consentScreen{
    return consentScreen;
}
- (NSString *)consentLanguage{
    return consentLanguage;
}
- (NSNumber *)vendorListVersion{
    return vendorListVersion;
}
- (NSNumber *)isServiceSpecific{
    return isServiceSpecific;
}


@end
