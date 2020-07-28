//
//  CMPDataStorageV2UserDefaults.m
//  GDPR
//

#import "CMPDataStorageV2UserDefaults.h"

NSString *const CMP_SDK_ID = @"IABTCF_CmpSdkID";
NSString *const CMP_SDK_VERSION = @"IABTCF_CmpSdkVersion";
NSString *const POLICY_VERSION = @"IABTCF_PolicyVersion";
NSString *const GDPR_APPLIES = @"IABTCF_gdprApplies";
NSString *const PUBLISHER_CC = @"IABTCF_PublisherCC";
NSString *const TC_STRING = @"IABTCF_TCString";
NSString *const VENDOR_CONSENTS = @"IABTCF_VendorConsents";
NSString *const VENDOR_LEGITIMATE_INTERESTS = @"IABTCF_VendorLegitimateInterests";
NSString *const PURPOSE_CONSENTS = @"IABTCF_PurposeConsents";
NSString *const PURPOSE_LEGITIMATE_INTERESTS = @"IABTCF_PurposeLegitimateInterests";
NSString *const SPECIAL_FEATURES_OPT_INS = @"IABTCF_SpecialFeaturesOptIns";
NSString *const PUBLISHER_RESTRICTIONS = @"IABTCF_PublisherRestrictions%d"; // %d = Purpose ID
NSString *const PUBLISHER_CONSENT = @"IABTCF_PublisherConsent";
NSString *const PUBLISHER_LEGITIMATE_INTERESTS = @"IABTCF_PublisherLegitimateInterests";
NSString *const PUBLISHER_CUSTOM_PURPOSES_CONSENTS = @"IABTCF_PublisherCustomPurposesConsents";
NSString *const PUBLISHER_CUSTOM_PURPOSES_LEGITIMATE_INTERESTS = @"IABTCF_PublisherCustomPurposesLegitimateInterests";
NSString *const PURPOSE_ONE_TREATMENT = @"IABTCF_PurposeOneTreatment";
NSString *const USE_NONE_STANDARD_STACKS = @"IABTCF_UseNoneStandardStacks";


@implementation CMPDataStorageV2UserDefaults

@synthesize cmpSdkId;
@synthesize cmpSdkVersion;
@synthesize policyVersion;
@synthesize gdprApplies;
@synthesize publisherCC;
@synthesize tcString;
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
@synthesize purposeOneTreatment;
@synthesize useNoneStandardStacks;


-(NSNumber *)cmpSdkId {
    return [self.userDefaults objectForKey:CMP_SDK_ID];
}

-(void)setCmpSdkId:(NSNumber *)cmpSdkId{
    [self.userDefaults setObject:cmpSdkId forKey:CMP_SDK_ID];
    [self.userDefaults synchronize];
}

-(NSNumber *)cmpSdkVersion {
    return [self.userDefaults objectForKey:CMP_SDK_VERSION];
}

-(void)setCmpSdkVersion:(NSNumber *)cmpSdkVersion{
    [self.userDefaults setObject:cmpSdkVersion forKey:CMP_SDK_VERSION];
    [self.userDefaults synchronize];
}

-(NSNumber *)policyVersion {
    return [self.userDefaults objectForKey:POLICY_VERSION];
}

-(void)setPolicyVersion:(NSNumber *)policyVersion{
    [self.userDefaults setObject:policyVersion forKey:POLICY_VERSION];
    [self.userDefaults synchronize];
}

-(NSNumber *)gdprApplies {
    return [self.userDefaults objectForKey:POLICY_VERSION];
}

-(void)setGdprApplies:(NSNumber *)gdprApplies{
    [self.userDefaults setObject:gdprApplies forKey:GDPR_APPLIES];
    [self.userDefaults synchronize];
}

-(NSString *)publisherCC {
    return [self.userDefaults objectForKey:PUBLISHER_CC];
}

-(void)setPublisherCC:(NSString *)publisherCC{
    [self.userDefaults setObject:publisherCC forKey:PUBLISHER_CC];
    [self.userDefaults synchronize];
}

-(NSString *)tcString {
    return [self.userDefaults objectForKey:TC_STRING];
}

-(void)setTcString:(NSString *)tcString{
    [self.userDefaults setObject:tcString forKey:TC_STRING];
    [self.userDefaults synchronize];
}

-(NSString *)vendorConsents {
    return [self.userDefaults objectForKey:VENDOR_CONSENTS];
}

-(void)setVendorConsents:(NSString *)vendorConsents{
    [self.userDefaults setObject:vendorConsents forKey:VENDOR_CONSENTS];
    [self.userDefaults synchronize];
}

-(NSString *)vendorLegitimateInterests {
    return [self.userDefaults objectForKey:VENDOR_LEGITIMATE_INTERESTS];
}

-(void)setVendorLegitimateInterests:(NSString *)vendorLegitimateInterests{
    [self.userDefaults setObject:vendorLegitimateInterests forKey:VENDOR_LEGITIMATE_INTERESTS];
    [self.userDefaults synchronize];
}

-(NSString *)purposeConsents {
    return [self.userDefaults objectForKey:PURPOSE_CONSENTS];
}

-(void)setPurposeConsents:(NSString *)purposeConsents{
    [self.userDefaults setObject:purposeConsents forKey:PURPOSE_CONSENTS];
    [self.userDefaults synchronize];
}

-(NSString *)purposeLegitimateInterests {
    return [self.userDefaults objectForKey:PURPOSE_LEGITIMATE_INTERESTS];
}

-(void)setPurposeLegitimateInterests:(NSString *)purposeLegitimateInterests{
    [self.userDefaults setObject:purposeLegitimateInterests forKey:PURPOSE_LEGITIMATE_INTERESTS];
    [self.userDefaults synchronize];
}

-(NSString *)specialFeaturesOptIns {
    return [self.userDefaults objectForKey:SPECIAL_FEATURES_OPT_INS];
}

-(void)setSpecialFeaturesOptIns:(NSString *)specialFeaturesOptIns{
    [self.userDefaults setObject:specialFeaturesOptIns forKey:SPECIAL_FEATURES_OPT_INS];
    [self.userDefaults synchronize];
}

-(NSArray<PublisherRestriction *> *)publisherRestrictions {
    int i = 0;
    NSMutableArray *pRestrictions = [NSMutableArray array];
    
    while( [self publisherRestriction:[NSNumber numberWithInt:i]] ){
        
        [pRestrictions addObject:[[CMPDataStorageV2UserDefaults alloc] publisherRestriction:[NSNumber numberWithInt:i]]];
        i++;
    }
    return pRestrictions;
}

-(void)setPublisherRestrictions:(NSArray<PublisherRestriction *> *)publisherRestrictions{
    for( int i = 0; i < publisherRestrictions.count; i++){
        [self setPublisherRestriction:publisherRestrictions[i]];
    }
}

-(PublisherRestriction *)publisherRestriction:(NSNumber *)purposeId {
    NSString *cmpString = [self.userDefaults objectForKey:[NSString stringWithFormat:PUBLISHER_RESTRICTIONS, (int)purposeId]];
    return [self getRestrictionForCMPString:cmpString forPurpose:[purposeId integerValue]];
}

-(void)setPublisherRestriction:(PublisherRestriction *)publisherRestriction{
    NSString *value = [[CMPDataStorageV2UserDefaults alloc] getCMPStringForPubRestriction:publisherRestriction];
    [self.userDefaults setObject:value forKey:[NSString stringWithFormat:PUBLISHER_RESTRICTIONS, (int)[publisherRestriction purposeId]]];
    [self.userDefaults synchronize];
}

-(NSString *)getCMPStringForPubRestriction:(PublisherRestriction *)publisherRestriction{
    NSString *vendorString = [publisherRestriction vendorIds];
    NSString *restrictionType = [NSString stringWithFormat: @"%ld", (long)[publisherRestriction restrictionType]];
    
    return [vendorString stringByReplacingOccurrencesOfString:@"1"
    withString:restrictionType];
}

-(PublisherRestriction *)getRestrictionForCMPString:(NSString *)cmpString forPurpose:(NSInteger)purposeId{
    NSInteger restrictionType = [self getRestrictionTypeForCMPString:cmpString];
    NSString *restrictionTypeString = [NSString stringWithFormat: @"%ld", (long)restrictionType];
    NSString *vendorString = [cmpString stringByReplacingOccurrencesOfString:restrictionTypeString
    withString:@"1"];
    return [[PublisherRestriction alloc] init:&purposeId type:&restrictionType vendors:vendorString];
}

-(NSInteger)getRestrictionTypeForCMPString:(NSString*)cmpString{
    for (NSUInteger i = 0; i < [cmpString length]; i++){
        switch ([cmpString characterAtIndex:i]) {
            case '1':
                return 1;
                break;
            case '2':
                return 2;
                break;
            case '3':
                return 3;
                break;
        }
    }
    return 0;
}

-(NSString *)publisherConsent {
    return [self.userDefaults objectForKey:PUBLISHER_CONSENT];
}

-(void)setPublisherConsent:(NSString *)publisherConsent{
    [self.userDefaults setObject:publisherConsent forKey:PUBLISHER_CONSENT];
    [self.userDefaults synchronize];
}

-(NSString *)publisherLegitimateInterests {
    return [self.userDefaults objectForKey:PUBLISHER_LEGITIMATE_INTERESTS];
}

-(void)setPublisherLegitimateInterests:(NSString *)publisherLegitimateInterests{
    [self.userDefaults setObject:publisherLegitimateInterests forKey:PUBLISHER_LEGITIMATE_INTERESTS];
    [self.userDefaults synchronize];
}

-(NSString *)publisherCustomPurposesConsent {
    return [self.userDefaults objectForKey:PUBLISHER_CUSTOM_PURPOSES_CONSENTS];
}

-(void)setPublisherCustomPurposesConsent:(NSString *)publisherCustomPurposesConsent{
    [self.userDefaults setObject:publisherCustomPurposesConsent forKey:PUBLISHER_CUSTOM_PURPOSES_CONSENTS];
    [self.userDefaults synchronize];
}

-(NSString *)publisherCustomPurposesLegitimateInterests {
    return [self.userDefaults objectForKey:PUBLISHER_CUSTOM_PURPOSES_LEGITIMATE_INTERESTS];
}

-(void)setPublisherCustomPurposesLegitimateInterests:(NSString *)publisherCustomPurposesLegitimateInterests{
    [self.userDefaults setObject:publisherCustomPurposesLegitimateInterests forKey:PUBLISHER_CUSTOM_PURPOSES_LEGITIMATE_INTERESTS];
    [self.userDefaults synchronize];
}

-(NSNumber *)purposeOneTreatment {
    return [self.userDefaults objectForKey:PURPOSE_ONE_TREATMENT];
}

-(void)setPurposeOneTreatment:(NSNumber *)purposeOneTreatment{
    [self.userDefaults setObject:purposeOneTreatment forKey:PURPOSE_ONE_TREATMENT];
    [self.userDefaults synchronize];
}

-(NSNumber *)useNoneStandardStacks {
    return [self.userDefaults objectForKey:USE_NONE_STANDARD_STACKS];
}

-(void)setUseNoneStandardStacks:(NSNumber *)useNoneStandardStacks{
    [self.userDefaults setObject:useNoneStandardStacks forKey:USE_NONE_STANDARD_STACKS];
    [self.userDefaults synchronize];
}


- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dataStorageDefaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  @0, CMP_SDK_ID,
                                                  @0, CMP_SDK_VERSION,
                                                  @0, POLICY_VERSION,
                                                  @0, GDPR_APPLIES,
                                                  @"", PUBLISHER_CC,
                                                  @"", TC_STRING,
                                                  @"", VENDOR_CONSENTS,
                                                  @"", VENDOR_LEGITIMATE_INTERESTS,
                                                  @"", PURPOSE_CONSENTS,
                                                  @"", PURPOSE_LEGITIMATE_INTERESTS,
                                                  @"", SPECIAL_FEATURES_OPT_INS,
                                                  @"", PUBLISHER_RESTRICTIONS,
                                                  @"", PUBLISHER_CONSENT,
                                                  @"", PUBLISHER_LEGITIMATE_INTERESTS,
                                                  @"", PUBLISHER_CUSTOM_PURPOSES_CONSENTS,
                                                  @"", PUBLISHER_CUSTOM_PURPOSES_LEGITIMATE_INTERESTS,
                                                  @0, PURPOSE_ONE_TREATMENT,
                                                  @0, USE_NONE_STANDARD_STACKS,
                                                  nil];
        [_userDefaults registerDefaults:dataStorageDefaultValues];
    }
    return _userDefaults;
}

-(void)clearContents{
    [self setCmpSdkId:@0];
    [self setCmpSdkVersion:@0];
    [self setPolicyVersion:@0];
    [self setGdprApplies:@0];
    [self setPublisherCC:@""];
    [self setTcString:@""];
    [self setVendorConsents:@""];
    [self setVendorLegitimateInterests:@""];
    [self setPurposeConsents:@""];
    [self setPurposeLegitimateInterests:@""];
    [self setSpecialFeaturesOptIns:@""];
    [self setPublisherRestrictions:[NSArray array]];
    [self setPublisherConsent:@""];
    [self setPublisherLegitimateInterests:@""];
    [self setPublisherCustomPurposesConsent:@""];
    [self setPublisherCustomPurposesLegitimateInterests:@""];
    [self setPurposeOneTreatment:@0];
    [self setUseNoneStandardStacks:@0];
}

@end
