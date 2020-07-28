//
//  CMPDataStorageV1UserDefaults.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPDataStorageV1Protocol.h"

@interface CMPDataStorageV1UserDefaults : NSObject<CMPDataStorageV1Protocol>
@property (nonatomic, retain) NSUserDefaults *userDefaults;
@end
