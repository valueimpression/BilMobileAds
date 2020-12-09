//
//  CMPConsentTool.m
//  GDPA
//
//

#import <Foundation/Foundation.h>
#import "CMPConsentTool.h"
#import "CMPDataStorageConsentManagerUserDefaults.h"
#import "CMPDataStorageV1UserDefaults.h"
#import "CMPDataStorageV2UserDefaults.h"
#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPSettings.h"
#import "CMPTypes.h"
#import "CMPConsentToolViewController.h"
#import "CMPConsentToolUtil.h"
#import "CMPConsentV1Parser.h"
#import "CMPConsentV2Parser.h"
#import "CloseListenerDelegate.h"

@interface CMPConsentTool() <CMPConsentToolViewControllerDelegate>
@end

@implementation CMPConsentTool

@synthesize cmpServerResponse;
@synthesize closeListener;
@synthesize openListener;
@synthesize networkErrorListener;
@synthesize serverErrorListener;
@synthesize customOpenListener;

- (CMPConfig *)cmpConfig {
    return _cmpConfig;
}

- (void)closeListener:(CloseListener *)listener {
    closeListener = listener;
}

- (void)openListener:(OpenListener *)listener {
    openListener = listener;
}

- (void)customOpenListener:(CustomOpenListener *)listener {
    customOpenListener = listener;
}

- (void)networkErrorListener:(NetworkErrorListener *)listener {
    networkErrorListener = listener;
}

- (void)serverErrorListener:(ServerErrorListener *)listener {
    serverErrorListener = listener;
}

- (CMPServerResponse *)cmpServerResponse{
    return cmpServerResponse;
}


- (void)openCmpConsentToolView{
    [self openCmpConsentToolView:closeListener];
}


- (void)openCmpConsentToolView:(CloseListener *) closeListener{
    [openListener onWebViewOpened];
    [[CMPDataStorageV1UserDefaults alloc] setCmpPresent:TRUE];
    
    if(customOpenListener){
        [customOpenListener onOpenCMPConsentToolActivity:cmpServerResponse withSettings:[CMPSettings self]];
        return;
    }
    if( [CMPConfig isValid]){
        CMPConsentToolViewController *consentToolVC = [[CMPConsentToolViewController alloc] init];
        consentToolVC.closeListener = closeListener;
        consentToolVC.networkErrorListener = networkErrorListener;
        consentToolVC.consentToolAPI.subjectToGDPR = SubjectToGDPR_Yes;
        consentToolVC.consentToolAPI.cmpPresent = YES;
        consentToolVC.delegate = self;
        consentToolVC.closeDelegate = self.closeDelegate;
        
        [self.viewController presentViewController:consentToolVC animated:YES completion:nil];
    }
}

#pragma mark CMPConsentToolViewController delegate
-(void)consentToolViewController:(CMPConsentToolViewController *)consentToolViewController didReceiveConsentString:(NSString *)consentString {
    [consentToolViewController dismissViewControllerAnimated:YES completion:nil];
    
    if(consentString.length > 0){
        // My CMP
        [self proceedConsentString:consentString];
        
        //        [[CMPDataStorageConsentManagerUserDefaults alloc] setConsentString:consentString];
        //        NSString *base64Decoded = [CMPConsentToolUtil binaryStringConsentFrom:consentString];
        //        NSLog(@"%@", base64Decoded);
        //        NSArray *splits = [base64Decoded componentsSeparatedByString:@"#"];
        //        if( splits.count > 3){
        //            NSLog(@"ConsentManager String detected");
        //            [self proceedConsentString:[splits objectAtIndex:0]];
        //            [self proceedConsentManagerValues:splits];
        //        } else {
        //            [[CMPDataStorageV1UserDefaults alloc] clearContents];
        //            [[CMPDataStorageV2UserDefaults alloc] clearContents];
        //            [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
        //        }
    } else {
        [[CMPDataStorageV1UserDefaults alloc] clearContents];
        [[CMPDataStorageV2UserDefaults alloc] clearContents];
        [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
    }
}

-(void)proceedConsentString:(NSString*)consentS{
    [[CMPDataStorageV1UserDefaults alloc] setConsentString:consentS];
    if( [[consentS substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"B"] ){
        NSLog(@"V1 String detected");
        [[CMPDataStorageV1UserDefaults alloc] setParsedVendorConsents:[CMPConsentV1Parser parseVendorConsentsFrom:consentS ]];
        [[CMPDataStorageV1UserDefaults alloc] setParsedPurposeConsents:[CMPConsentV1Parser parsePurposeConsentsFrom:consentS ]];
    } else {
        NSLog(@"V2 String detected");
        CMPConsentV2Parser *v2parser = [[CMPConsentV2Parser alloc] init:consentS];
        [[CMPDataStorageV2UserDefaults alloc] setCmpSdkId:[v2parser cmpSdkId]];
        [[CMPDataStorageV2UserDefaults alloc] setCmpSdkVersion:[v2parser cmpSdkVersion]];
        [[CMPDataStorageV2UserDefaults alloc] setGdprApplies:@0];
        [[CMPDataStorageV2UserDefaults alloc] setPurposeOneTreatment:[v2parser purposeOneTreatment]];
        [[CMPDataStorageV2UserDefaults alloc] setUseNoneStandardStacks:[v2parser useNoneStandardStacks]];
        [[CMPDataStorageV2UserDefaults alloc] setPublisherCC:[v2parser publisherCC]];
        [[CMPDataStorageV2UserDefaults alloc] setVendorConsents:[v2parser vendorConsents]];
        [[CMPDataStorageV2UserDefaults alloc] setVendorLegitimateInterests:[v2parser vendorLegitimateInterests]];
        [[CMPDataStorageV2UserDefaults alloc] setPurposeConsents:[v2parser purposeConsents]];
        [[CMPDataStorageV2UserDefaults alloc] setPurposeLegitimateInterests:[v2parser purposeLegitimateInterests]];
        [[CMPDataStorageV2UserDefaults alloc] setSpecialFeaturesOptIns:[v2parser specialFeaturesOptIns]];
        [[CMPDataStorageV2UserDefaults alloc] setPublisherRestrictions:[v2parser publisherRestrictions]];
        [[CMPDataStorageV2UserDefaults alloc] setPublisherConsent:[v2parser publisherConsent]];
        [[CMPDataStorageV2UserDefaults alloc] setPurposeLegitimateInterests:[v2parser purposeLegitimateInterests]];
        [[CMPDataStorageV2UserDefaults alloc] setPublisherCustomPurposesConsent:[v2parser publisherCustomPurposesConsent]];
        [[CMPDataStorageV2UserDefaults alloc] setPublisherCustomPurposesLegitimateInterests:[v2parser publisherCustomPurposesLegitimateInterests]];
        [[CMPDataStorageV2UserDefaults alloc] setPolicyVersion:[v2parser policyVersion]];
    }
}

-(void)proceedConsentManagerValues:(NSArray*)splits{
    [[CMPDataStorageConsentManagerUserDefaults alloc] setParsedPurposeConsents:[splits objectAtIndex:1]];
    [[CMPDataStorageConsentManagerUserDefaults alloc] setParsedVendorConsents:[splits objectAtIndex:2]];
    [[CMPDataStorageConsentManagerUserDefaults alloc] setUsPrivacyString:[splits objectAtIndex:3]];
}


- (NSString*)getVendorsString{
    return [[CMPDataStorageConsentManagerUserDefaults alloc] parsedVendorConsents];
}

- (NSString*)getPurposesString{
    return [[CMPDataStorageConsentManagerUserDefaults alloc] parsedPurposeConsents];
}

- (NSString*)getUSPrivacyString{
    return [[CMPDataStorageConsentManagerUserDefaults alloc] usPrivacyString];
}


- (BOOL)hasVendorConsent:(NSString *)vendorId vendorIsV1orV2:(BOOL)isIABVendor{
    int vendorIdInt = [vendorId intValue];
    if( isIABVendor ){
        NSString *x = [[CMPDataStorageV1UserDefaults alloc] parsedVendorConsents];
        if( [[x substringWithRange:NSMakeRange(vendorIdInt + 1, 1)] isEqualToString:@"1"]){
            return TRUE;
        }
        x = [[CMPDataStorageV2UserDefaults alloc] vendorConsents];
        if( [[x substringWithRange:NSMakeRange(vendorIdInt + 1, 1)] isEqualToString:@"1"]){
            return TRUE;
        }
        return FALSE;
    } else {
        NSString *x = [[CMPDataStorageConsentManagerUserDefaults alloc] parsedVendorConsents];
        return [x containsString: [NSString stringWithFormat:@"_%@_", vendorId]];
    }
}

- (BOOL)hasPurposeConsent:(NSString *)purposeId purposeIsV1orV2:(BOOL)isIABPurpose{
    int purposeIdInt = [purposeId intValue];
    if( isIABPurpose ){
        NSString *x = [[CMPDataStorageV1UserDefaults alloc] parsedPurposeConsents];
        if( [[x substringWithRange:NSMakeRange(purposeIdInt + 1, 1)] isEqualToString:@"1"]){
            return TRUE;
        }
        x = [[CMPDataStorageV2UserDefaults alloc] purposeConsents];
        if( [[x substringWithRange:NSMakeRange(purposeIdInt + 1, 1)] isEqualToString:@"1"]){
            return TRUE;
        }
        return FALSE;
    } else {
        NSString *x = [[CMPDataStorageConsentManagerUserDefaults alloc] parsedPurposeConsents];
        return [x containsString: [NSString stringWithFormat:@"_%@_", purposeId]];
    }
}



- (id)init:(NSString *)domain addId:(NSString *)userId addAppName:(NSString *)appName addLanguage:(NSString *)language addViewController:(UIViewController *)viewController{
    [CMPConfig setValues:domain addId:userId addAppName:appName addLanguage:language];
    return [self init:[CMPConfig self] withViewController:viewController];
}

- (id)init:(CMPConfig *)config withViewController:(UIViewController *)viewController{
    self.cmpConfig = config;
    self.viewController = viewController;
    [self checkAndProceedConsentUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.viewController
                                             selector:@selector(onApplicationDidBecomeActive:)
                                                 name:@"NSApplicationDidBecomeActiveNotification"
                                               object:nil];
    
    return self;
}

-(void)onApplicationDidBecomeActive:(NSNotification*)notification{
    [self checkAndProceedConsentUpdate];
}

// My CMP
-(void)checkAndProceedConsentUpdate{
    // if([self needsServerUpdate]){
    if([self needShowCMP]){
        cmpServerResponse = [self proceedServerRequest];
        switch ([cmpServerResponse.status intValue]) {
            case 0:
                return;
            case 1:
                [CMPSettings setConsentToolUrl:cmpServerResponse.url];
                if( [cmpServerResponse.regulation  isEqual: @1]){
                    [CMPSettings setSubjectToGdpr:SubjectToGDPR_Yes];
                } else {
                    [CMPSettings setSubjectToGdpr:SubjectToGDPR_No];
                }
                [CMPSettings setConsentString:nil];
//                [self openCmpConsentToolView];
                return;
            default:
                [self showErrorMessage:cmpServerResponse.message];
                break;
        }
    }
}

// My CMP
-(BOOL) compareNowLessFuture:(NSString *)futureDate{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss.SSSZ"];
    
    NSDate *date = [NSDate date];
    NSDate *dateFuture = [dateFormatter dateFromString:futureDate];
    NSComparisonResult result = [date compare:dateFuture];
    // TRUE -> show
    switch (result)
    {
        case NSOrderedAscending:
            // date < dateFuture
            return FALSE;
        case NSOrderedSame:
            // date = dateFuture
            return FALSE;
        case NSOrderedDescending:
            // date > dateFuture
            return TRUE;
        default:
            // Error
            return TRUE;
    }
}
-(BOOL) needShowCMP{
    NSString *consentS = [[CMPConsentToolAPI alloc] consentString];
    NSString *lastDate = [[CMPDataStoragePrivateUserDefaults alloc] lastRequested];
    
    if(consentS == nil || [consentS length] == 0) {
        // Reject -> Answer after 14d
        if (lastDate != nil && [lastDate length] > 0) {
            return [self compareNowLessFuture:lastDate];
        }
        // First Time
        return TRUE;
    } else {
        // Accepted -> Answer after 365d
        return [self compareNowLessFuture:lastDate];
    }
}

-(void)showErrorMessage:(NSString *)message{
    if( serverErrorListener){
        [serverErrorListener onErrorOccur:message];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.viewController presentViewController:alert animated:YES completion:nil];
    }
}

-(BOOL) needsServerUpdate{
    return ![self calledThisDay];
}

-(CMPServerResponse*)proceedServerRequest{
    cmpServerResponse = [CMPConsentToolUtil getAndSaveServerResponse:networkErrorListener withConsent:[[CMPDataStorageConsentManagerUserDefaults alloc] consentString]];
    return cmpServerResponse;
}

-(BOOL)calledThisDay{
    NSString *last = [self getCalledLast];
    if( last ){
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return [now isEqualToString:last];
    }
    return FALSE;
}

-(NSString*)getCalledLast{
    return [[CMPDataStoragePrivateUserDefaults alloc] lastRequested];
}

@end
