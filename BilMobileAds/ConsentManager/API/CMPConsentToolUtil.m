//
//  CMPConsentToolUtil.m
//  GDPR
//

#import "CMPConsentToolUtil.h"
#import "Reachability.h"
#import "CMPDataStoragePrivateUserDefaults.h"

NSString *const RESPONSE_MESSAGE_KEY = @"message";
NSString *const RESPONSE_STATUS_KEY = @"status";
NSString *const RESPONSE_REGULATION_KEY = @"regulation";
NSString *const RESPONSE_URL_KEY = @"url";


@implementation CMPConsentToolUtil

+(unsigned char*)NSDataToBinary:(NSData *)decodedData {
    const char *byte = [decodedData bytes];
    NSUInteger length = [decodedData length];
    unsigned long bufferLength = decodedData.length*8 - 1;
    unsigned char *buffer = (unsigned char *)calloc(bufferLength, sizeof(unsigned char));
    int prevIndex = 0;
    
    for (int byteIndex=0; byteIndex<length; byteIndex++) {
        char currentByte = byte[byteIndex];
        int bufferIndex = 8*(byteIndex+1);
        
        while(bufferIndex > prevIndex) {
            if(currentByte & 0x01) {
                buffer[--bufferIndex] = '1';
            } else {
                buffer[--bufferIndex] = '0';
            }
            currentByte >>= 1;
        }
        
        prevIndex = 8*(byteIndex+1);
    }
    
    return buffer;
}

+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex toIndex:(int)endIndex {
    size_t length =  (int)strlen((const char *)buffer);

    if (length <= startIndex || length <= endIndex) {
        return 0;
    }
    
    int bit = 1;
    NSInteger total = 0;
    
    for (int i=endIndex; i>=startIndex; i--) {
        if (buffer[i] == '1') {
            total += bit;
        }
        
        bit *= 2;
    }
    
    return total;
}

+(NSString*)BinaryToString:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    size_t length =  (int)strlen((const char *)buffer);

    if (length <= startIndex || length <= startIndex + totalOffset - 1) {
        return 0;
    }
    
    NSMutableString *total = [NSMutableString new];
    
    for (int i=startIndex + totalOffset - 1; i>=startIndex; i--) {
        [total appendString:[NSString stringWithFormat:@"%c",buffer[i]]];
    }
    
    return total;
}

+(NSNumber*)BinaryToNumber:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    return [NSNumber numberWithInteger:[CMPConsentToolUtil BinaryToDecimal:buffer fromIndex:startIndex length:totalOffset]];
}



+(NSInteger)BinaryToDecimal:(unsigned char*)buffer fromIndex:(int)startIndex length:(int)totalOffset {
    size_t length =  (int)strlen((const char *)buffer);
    
    if (length <= startIndex || length <= startIndex + totalOffset - 1) {
        return 0;
    }
    
    int bit = 1;
    NSInteger total = 0;
    
    for (int i=startIndex + totalOffset - 1; i>=startIndex; i--) {
        if (buffer[i] == '1') {
            total += bit;
        }
        
        bit *= 2;
    }
    
    return total;
}

+(NSString*)addPaddingIfNeeded:(NSString*)base64String {
    int padLenght = (4 - (base64String.length % 4)) % 4;
    NSString *paddedBase64 = [NSString stringWithFormat:@"%s%.*s", [base64String UTF8String], padLenght, "=="];
    return paddedBase64;
}

+(NSString*)replaceSafeCharacters:(NSString*)consentString {
    NSString *stringreplace = [consentString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    NSString *finalString = [stringreplace stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    return finalString;
}

+(NSString*)safeBase64ConsentString:(NSString*)consentString {
    NSString *safeString = [CMPConsentToolUtil replaceSafeCharacters:consentString];
    NSString *base64String = [CMPConsentToolUtil addPaddingIfNeeded:safeString];
    return base64String;
}

+(BOOL)isNetworkAvailable{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return FALSE;
    } else {
        return TRUE;
    }
}

+(CMPServerResponse*)getAndSaveServerResponse:(NetworkErrorListener *)networkErrorListener withConsent:(NSString*)consent{
    if([self isNetworkAvailable]){
        // My CMP
        NSDictionary *responseDictionary = @{
            @"message":@"",
            @"status": @1,
            @"regulation":@1,
            @"url":@"https://static.vliplatform.com/plugins/appCMP/#cmpscreen",
        };
        // NSDictionary *responseDictionary = [self requestSynchronousJSONWithURLString:[CMPConfig getConsentToolURLString:consent]];
        
        CMPServerResponse *response = [[CMPServerResponse alloc] init];
        response.message = [responseDictionary objectForKey:RESPONSE_MESSAGE_KEY];
        response.status = [NSNumber numberWithInt:[[responseDictionary objectForKey:RESPONSE_STATUS_KEY] intValue]];
        response.regulation = [NSNumber numberWithInt:[[responseDictionary objectForKey:RESPONSE_REGULATION_KEY] intValue]];
        response.url = [responseDictionary objectForKey:RESPONSE_URL_KEY];
        
        [[CMPDataStoragePrivateUserDefaults alloc] setConsentToolUrl:response.url];
        //        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        //        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        //        [[CMPDataStoragePrivateUserDefaults alloc] setLastRequested:[dateFormatter stringFromDate:[NSDate date]]];
        return response;
    } else {
        if(networkErrorListener){
            [networkErrorListener onErrorOccur:@"The Server coudn't be contacted, because no Network Connection was found"];
        }
        return nil;
    }}


+ (NSData *)requestSynchronousData:(NSURLRequest *)request
{
    __block NSData *data = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *response, NSError *error) {
        data = taskData;
        if (!data) {
            NSLog(@"%@", error);
        }
        dispatch_semaphore_signal(semaphore);
        
    }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return data;
}

+ (NSData *)requestSynchronousDataWithURLString:(NSString *)requestString
{
    NSURL *url = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return [self requestSynchronousData:request];
}

+ (NSDictionary *)requestSynchronousJSON:(NSURLRequest *)request
{
    NSData *data = [self requestSynchronousData:request];
    NSError *e = nil;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    return jsonData;
}

+ (NSDictionary *)requestSynchronousJSONWithURLString:(NSString *)requestString
{
    NSURL *url = [NSURL URLWithString:requestString];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:50];
    theRequest.HTTPMethod = @"GET";
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return [self requestSynchronousJSON:theRequest];
}

+(unsigned char*)binaryConsentFrom:(NSString *)consentString {
    NSString* safeString = [CMPConsentToolUtil safeBase64ConsentString:consentString];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:safeString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    if (!decodedData) {
        return nil;
    }
    
    return [CMPConsentToolUtil NSDataToBinary:decodedData];
}

+(NSString *)binaryStringConsentFrom:(NSString *)consentString {
    NSString* safeString = [CMPConsentToolUtil safeBase64ConsentString:consentString];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:safeString options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}




@end
