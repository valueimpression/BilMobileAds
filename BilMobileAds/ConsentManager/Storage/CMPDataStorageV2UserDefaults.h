//
//  CMPDataStorageV2UserDefaults.h
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPDataStorageV2Protocol.h"

@interface CMPDataStorageV2UserDefaults : NSObject<CMPDataStorageV2Protocol>
@property (nonatomic, retain) NSUserDefaults *userDefaults;
@end
