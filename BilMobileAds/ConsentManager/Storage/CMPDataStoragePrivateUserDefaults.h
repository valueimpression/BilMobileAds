//
//  CMPDataStoragePrivateUserDefaults.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPDataStoragePrivateProtocol.h"

@interface CMPDataStoragePrivateUserDefaults : NSObject<CMPDataStoragePrivateProtocol>
@property (nonatomic, retain) NSUserDefaults *userDefaults;
@end
