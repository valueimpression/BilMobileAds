//
//  CMPDataStorageConsentManagerUserDefaults.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPDataStorageConsentManagerProtocol.h"

@interface CMPDataStorageConsentManagerUserDefaults : NSObject<CMPDataStorageConsentManagerProtocol>
@property (nonatomic, retain) NSUserDefaults *userDefaults;
@end
