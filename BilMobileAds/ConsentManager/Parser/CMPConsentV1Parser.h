//
//  CMPConsentV1Parser.h
//  GDPR
//

#import <Foundation/Foundation.h>

@interface CMPConsentV1Parser : NSObject
+ (NSString *)parseVendorConsentsFrom:(NSString *)consentString;
+ (NSString *)parsePurposeConsentsFrom:(NSString *)consentString;
@end
