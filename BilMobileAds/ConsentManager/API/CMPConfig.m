//
//  CMPConfig.m
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPConfig.h"
#import <AdSupport/ASIdentifierManager.h>

NSString *const ConsentToolURLUnformatted = @"https://%@/delivery/appjson.php?id=%@&name=%@&consent=%@&idfa=%@&l=%@";

@implementation CMPConfig
static NSString *consentToolId = nil;
static NSString *consentToolAppName = nil;
static NSString *consentToolDomain = nil;
static NSString *consentToolLanguage = nil;

+ (void)setValues:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString*)language {
    consentToolId = userId;
    consentToolAppName = appName;
    consentToolDomain = domain;
    consentToolLanguage = language;
}

+ (void)setConsentToolDomain:(NSString *)ctd {
    consentToolDomain = ctd;
}

+(NSString *)consentToolDomain {
    return consentToolDomain;
}

+(void)setConsentToolId:(NSString *)cti {
    consentToolId = cti;
}

+(NSString *)consentToolId {
    return consentToolId;
}

+ (void)setConsentToolAppName:(NSString *)ctan{
    consentToolAppName = ctan;
}

+(NSString *)consentToolAppName {
    return consentToolAppName;
}

+ (void)setConsentToolLanguage:(NSString *)ctl{
    consentToolLanguage = ctl;
}

+(NSString *)consentToolLanguage {
    return consentToolLanguage;
}

+(BOOL)isValid{
    return consentToolDomain && consentToolAppName && consentToolId && consentToolLanguage;
}

+(NSString *)idfa {
    NSUUID *adId = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    return [adId UUIDString];
}

+(NSString*)getConsentToolURLString:(NSString*)consent{
    return [NSString stringWithFormat:ConsentToolURLUnformatted, consentToolDomain, consentToolId, consentToolAppName, consent, [CMPConfig idfa], consentToolLanguage];
}

@end
