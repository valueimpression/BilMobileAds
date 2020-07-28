//
//  CMPDataStoragePrivateUserDefaults.m
//  GDPR
//

#import "CMPDataStoragePrivateUserDefaults.h"

NSString *const CONSENT_TOOL_URL = @"IABConsent_ConsentToolUrl";
NSString *const CMP_REQUEST = @"IABConsent_CMPRequest";

@implementation CMPDataStoragePrivateUserDefaults

@synthesize consentToolUrl;
@synthesize lastRequested;

-(NSString *)consentToolUrl {
    return [self.userDefaults objectForKey:CONSENT_TOOL_URL];
}

-(void)setConsentToolUrl:(NSString *)consentToolUrl{
    [self.userDefaults setObject:consentToolUrl forKey:CONSENT_TOOL_URL];
    [self.userDefaults synchronize];
}

-(NSString *)lastRequested {
    return [self.userDefaults objectForKey:CMP_REQUEST];
}

-(void)setLastRequested:(NSString *)lastRequested{
    [self.userDefaults setObject:lastRequested forKey:CMP_REQUEST];
    [self.userDefaults synchronize];
}

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dataStorageDefaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"", CONSENT_TOOL_URL,
                                                  @"", CMP_REQUEST,
                                                  nil];
        [_userDefaults registerDefaults:dataStorageDefaultValues];
    }
    return _userDefaults;
}

-(void)clearContents{
    [self setConsentToolUrl:@""];
    [self setLastRequested:@""];
}

@end
