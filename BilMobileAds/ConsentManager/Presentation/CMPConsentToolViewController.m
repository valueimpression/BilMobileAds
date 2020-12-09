//
//  CMPConsentToolViewController.m
//  GDPR
//

#import "CMPDataStoragePrivateUserDefaults.h"
#import "CMPConsentToolViewController.h"
#import "CMPDataStorageV1UserDefaults.h"
#import "CMPDataStorageV2UserDefaults.h"
#import "CMPDataStorageConsentManagerUserDefaults.h"
#import "CMPActivityIndicatorView.h"
#import "CMPConsentToolUtil.h"
#import "CMPConfig.h"
#import "CMPSettings.h"
#import "CMPServerResponse.h"
#import <WebKit/WebKit.h>

NSString *const ConsentStringPrefix = @"consent://";
NSString *const ConsentStringQueryParam = @"code64";

@interface CMPConsentToolViewController ()<WKNavigationDelegate>
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) CMPActivityIndicatorView *activityIndicatorView;
@property (nonatomic, retain) CMPServerResponse *cmpServerResponse;
@end

@implementation CMPConsentToolViewController
static bool error = FALSE;

-(void)viewDidLoad {
    [super viewDidLoad];
    [self initWebView];
    if( ! error ){
        [self initActivityIndicator];
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURLRequest *request = [self requestForConsentTool];
    if (request) {
        [_webView loadRequest:request];
    }
    if( error ){
        [super dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    NSString *consentS = [[CMPConsentToolAPI alloc] consentString];
    if (consentS == nil || [consentS length] == 0) {
        // My CMP: Reject -> set time: Aws 365d
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss.SSSZ"];
        NSDate *add14Day = [[NSDate date] dateByAddingTimeInterval:31536000]; // sec | 24*60*60 * 14 = 1209600
        [[CMPDataStoragePrivateUserDefaults alloc] setLastRequested:[dateFormatter stringFromDate:add14Day]];
        
        [self.closeListener onWebViewClosed];
        [self.closeDelegate onWebViewClosed:consentS];
    }
}

-(void)initWebView {
    if( ![CMPConfig isValid] ){
        [[CMPDataStorageV1UserDefaults alloc] clearContents];
        [[CMPDataStorageV2UserDefaults alloc] clearContents];
        [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
        error = true;
        return;
    }
    
    if( ![CMPSettings consentToolUrl] || [[CMPSettings consentToolUrl] isEqualToString:@""]){
        [[CMPDataStorageV1UserDefaults alloc] clearContents];
        [[CMPDataStorageV2UserDefaults alloc] clearContents];
        [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
        _cmpServerResponse = [CMPConsentToolUtil getAndSaveServerResponse:_networkErrorListener  withConsent:[[CMPDataStorageConsentManagerUserDefaults alloc] consentString]];
        if( !_cmpServerResponse || !_cmpServerResponse.url || [_cmpServerResponse.url isEqualToString:@""]){
            NSLog(@"The Response is not valid. Resetting Settings...");
            [[CMPDataStorageV1UserDefaults alloc] clearContents];
            [[CMPDataStorageV2UserDefaults alloc] clearContents];
            [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
            error = true;
            return;
        }
    } else {
        _cmpServerResponse = [CMPConsentToolUtil getAndSaveServerResponse:_networkErrorListener  withConsent:[[CMPDataStorageConsentManagerUserDefaults alloc] consentString]];
        if( !_cmpServerResponse || !_cmpServerResponse.url || [_cmpServerResponse.url isEqualToString:@""]){
            NSLog(@"The Response is not valid. Resetting Settings...");
            [[CMPDataStorageV1UserDefaults alloc] clearContents];
            [[CMPDataStorageV2UserDefaults alloc] clearContents];
            [[CMPDataStorageConsentManagerUserDefaults alloc] clearContents];
            error = true;
            return;
        }
    }
    
    if( [CMPConsentToolUtil isNetworkAvailable] ){
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.scrollView.scrollEnabled = YES;
        _webView.configuration.preferences.javaScriptEnabled = YES;
        [self.view addSubview:_webView];
        [self layoutWebView];
    } else {
        if( _networkErrorListener != nil){
            [_networkErrorListener onErrorOccur:@"The Network is not reachable to show the WebView"];
            [_activityIndicatorView removeFromSuperview];
            error = true;
        }
    }
    
}

-(void)layoutWebView {
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 11, *)) {
        UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [self.webView.topAnchor constraintEqualToAnchor:guide.topAnchor],
            [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
            [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
            [self.webView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor]
        ]];
    } else {
        id topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_webView, topAnchor);
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[topGuide]-[_webView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:viewsDictionary]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-0-[_webView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:viewsDictionary]];
    }
}

-(void)initActivityIndicator {
    _activityIndicatorView = [[CMPActivityIndicatorView alloc] initWithFrame:self.view.frame];
    _activityIndicatorView.userInteractionEnabled = NO;
    [self.view addSubview:_activityIndicatorView];
    [_activityIndicatorView startAnimating];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    NSURLRequest *request = navigationAction.request;
    
    // new base64-encoded consent string received
    if ([request.URL.absoluteString.lowercaseString hasPrefix:ConsentStringPrefix]) {
        NSString *newConsentString = [self consentStringFromRequest:request];
        
        // My CMP
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss.SSSZ"];
        // Accepte: -> set 365d
        NSDate *add365Day = [[NSDate date] dateByAddingTimeInterval:31536000]; // sec | 24*60*60 * 365 = 31536000
        [[CMPDataStoragePrivateUserDefaults alloc] setLastRequested:[dateFormatter stringFromDate:add365Day]];
        
        if ([self.delegate respondsToSelector:@selector(consentToolViewController:didReceiveConsentString:)]) {
            [self.delegate consentToolViewController:self didReceiveConsentString:newConsentString];
        }
        [self.closeListener onWebViewClosed];
        [self.closeDelegate onWebViewClosed:newConsentString];
    }
    
    decisionHandler(policy);
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_activityIndicatorView stopAnimating];
}

-(NSURLRequest*)requestForConsentTool{
    if (_cmpServerResponse.url) {
        if (self.consentToolAPI.consentString.length > 0) {
            return [NSURLRequest requestWithURL:[self base64URLEncodedWithURL:[NSURL URLWithString:_cmpServerResponse.url]
                                                                   queryValue:_consentToolAPI.consentString]];
        }
        return [NSURLRequest requestWithURL:[NSURL URLWithString:_cmpServerResponse.url]];
    }
    return nil;
}

-(CMPConsentToolAPI*)consentToolAPI  {
    if (!_consentToolAPI) {
        _consentToolAPI = [[CMPConsentToolAPI alloc] init];
    }
    return _consentToolAPI;
}

-(NSString*)consentStringFromRequest:(NSURLRequest *)request {
    NSRange consentStringRange = [request.URL.absoluteString rangeOfString:ConsentStringPrefix options:NSBackwardsSearch];
    if (consentStringRange.location != NSNotFound) {
        NSString *responseString = [request.URL.absoluteString substringFromIndex:consentStringRange.location + consentStringRange.length];
        NSArray *response = [responseString componentsSeparatedByString:@"/"];
        NSString *consentString = response.firstObject;
        return consentString;
    }
    
    return @"";
}

-(NSURL *)base64URLEncodedWithURL:(NSURL *)URL queryValue:(NSString *)queryValue {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:NO];
    NSURLQueryItem * consentStringQueryItem = [[NSURLQueryItem alloc] initWithName:ConsentStringQueryParam value:queryValue];
    NSMutableArray * allQueryItems = [[NSMutableArray alloc] init];
    [allQueryItems addObject:consentStringQueryItem];
    [components setQueryItems:allQueryItems];
    
    return [components URL];
}

@end
