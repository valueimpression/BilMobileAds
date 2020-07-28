//
//  CMPServerResponse.m
//  GDPR
//

#import <Foundation/Foundation.h>
#import "CMPServerResponse.h"

@implementation CMPServerResponse

@synthesize message;
@synthesize regulation;
@synthesize url;
@synthesize status;

- (void)setStatus:(NSNumber *)s {
    status = s;
}

-(NSNumber *)status {
    return status;
}

- (void)setMessage:(NSString *)m {
    message = m;
}

-(NSString *)message {
    return message;
}

- (void)setRegulation:(NSNumber *)r {
    regulation = r;
}

-(NSNumber *)regulation {
    return regulation;
}

- (void)setUrl:(NSString *)u {
    url = u;
}

-(NSString *)url {
    return url;
}

@end
