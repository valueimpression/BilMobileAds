//
//  CMPConfig.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPTypes.h"

/**
 Object that provides the interface for storing and retrieving GDPR-related information
 */
@interface CMPSettings : NSObject

/**
 NSURL that is used to create and load the request into the WKWebView – it is the request for the consent webpage. This property is mandatory.
 */
@property (class) SubjectToGDPR subjectToGdpr;

/**
 Language that is used to create and load the request into the WKWebView – it is the request for the consent webpage. This property is mandatory.
 */
@property (class) NSString *consentToolUrl;

/**
 AppName that is used to create and load the request into the WKWebView – it is the request for the consent webpage. This property is mandatory.
 */
@property (class) NSString *consentString;

+ (void)setConsentString:(NSString *)consentString;

+(NSString *)consentString;

+ (void)setSubjectToGdpr:(SubjectToGDPR)subjectToGdpr;

+(SubjectToGDPR)subjectToGdpr;

+ (void)setConsentToolUrl:(NSString *)consentToolUrl;

+(NSString *)consentToolUrl;

/**
 Creates a new singleton Instance from the Settings and Returns this
 */
+ (void)setValues:(SubjectToGDPR)subjectToGdpr addConsentToolUrl:(NSString *)consentToolUrl addConsentString:(NSString *)consentString;


@end
