//
//  CMPConfig.m
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPSettings.h"
#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPDataStorageV1UserDefaults.h"

@implementation CMPSettings
static NSString *consentString;
static NSString *consentToolUrl;
static SubjectToGDPR subjectToGdpr;

+(void)setValues:(SubjectToGDPR)stg addConsentToolUrl:(NSString *)ctu addConsentString:(NSString *)cs {
    consentString = cs;
    consentToolUrl = ctu;
    subjectToGdpr = stg;
}

+ (void)setConsentString:(NSString *)cs {
    [[CMPDataStorageV1UserDefaults alloc] setConsentString:cs];
    consentString = cs;
}

+(NSString *)consentString {
    return consentString;
}

+ (void)setSubjectToGdpr:(SubjectToGDPR)stg{
    [[CMPDataStorageV1UserDefaults alloc] setSubjectToGDPR:stg];
    subjectToGdpr = stg;
}

+(SubjectToGDPR)subjectToGdpr {
    return subjectToGdpr;
}

+ (void)setConsentToolUrl:(NSString *)ctu{
    [[CMPDataStoragePrivateUserDefaults alloc] setConsentToolUrl:ctu];
    consentToolUrl = ctu;
}

+(NSString *)consentToolUrl {
    return consentToolUrl;
}

@end
