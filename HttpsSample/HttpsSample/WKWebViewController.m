//
//  WKWebViewController.m
//  HttpsSample
//
//  Created by aiijim on 17/1/15.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "CredentialsManager.h"

@interface WKWebViewController()<WKNavigationDelegate>

@property (strong, nonatomic) WKWebView * webView;

@end

@implementation WKWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
    self.webView = [[WKWebView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                      configuration:configuration];

//    WKPreferences * preferences = [WKPreferences new];
//    preferences.javaScriptEnabled = YES;
    
//    configuration.preferences = preferences;
    
    [self.view addSubview:self.webView];
//    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.cacert.org/"]];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"html"];
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:60.0];
    self.webView.navigationDelegate = self;
    [self.webView loadRequest:req];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"url:%@",navigationAction.request.URL);
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
    CredentialsManager *manager = [CredentialsManager shareInstance];
    SecTrustRef trust = [[challenge protectionSpace] serverTrust];
    int err;
    SecTrustResultType trustResult = 0;
    err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)manager.trustedAnchors);
    if (err == noErr)
    {
        err = SecTrustEvaluate(trust,&trustResult);
    }
    SecTrustSetAnchorCertificatesOnly(trust, manager.onlyAnchor);
    BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    if (trusted)
    {
        completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
    else
    {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
    }
}

@end
