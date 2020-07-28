//
//  CMPDataStorageConsentManagerUserDefaults.m
//  GDPR
//

#import "CMPDataStorageConsentManagerUserDefaults.h"

NSString *const US_PRIVACY = @"IABUSPrivacy_String";
NSString *const VENDORS = @"CMConsent_ParsedVendorConsents";
NSString *const PURPOSES = @"CMConsent_ParsedPurposeConsents";
NSString *const CONSENT_STRING = @"CMConsent_ConsentString";

@implementation CMPDataStorageConsentManagerUserDefaults

@synthesize consentString;
@synthesize usPrivacyString;
@synthesize parsedVendorConsents;
@synthesize parsedPurposeConsents;

-(NSString *)usPrivacyString {
    return [self.userDefaults objectForKey:US_PRIVACY];
}

-(void)setUsPrivacyString:(NSString *)usPrivacyString{
    [self.userDefaults setObject:usPrivacyString forKey:US_PRIVACY];
    [self.userDefaults synchronize];
}

-(NSString *)consentString {
    return [self.userDefaults objectForKey:CONSENT_STRING];
}

-(void)setConsentString:(NSString *)consentString{
    [self.userDefaults setObject:consentString forKey:CONSENT_STRING];
    [self.userDefaults synchronize];
}

-(NSString *)parsedVendorConsents {
    return [self.userDefaults objectForKey:VENDORS];
}

-(void)setParsedVendorConsents:(NSString *)parsedVendorConsents {
    [self.userDefaults setObject:parsedVendorConsents forKey:VENDORS];
    [self.userDefaults synchronize];
}

-(NSString *)parsedPurposeConsents {
    return [self.userDefaults objectForKey:PURPOSES];
}

-(void)setParsedPurposeConsents:(NSString *)parsedPurposeConsents {
    [self.userDefaults setObject:parsedPurposeConsents forKey:PURPOSES];
    [self.userDefaults synchronize];
}

-(NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dataStorageDefaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"", US_PRIVACY,
                                                  @"", VENDORS,
                                                  @"", PURPOSES,
                                                  @"", CONSENT_STRING,
                                                  nil];
        [_userDefaults registerDefaults:dataStorageDefaultValues];
    }
    return _userDefaults;
}

-(void)clearContents{
    [self setParsedPurposeConsents:@""];
    [self setParsedVendorConsents:@""];
    [self setUsPrivacyString:@""];
    [self setConsentString:@""];
}

@end
