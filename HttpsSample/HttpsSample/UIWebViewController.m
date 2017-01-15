//
//  UIWebViewController.m
//  AJAXSample
//
//  Created by aiijim on 2017/1/17.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "UIWebViewController.h"
#import "NSURLConnection/NSURLConnection+Https.h"
#import "UIWebView/SelfSignedHttpsURLProtocol.h"

@interface UIWebViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webContainer;

@end

@implementation UIWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.cacert.org/"]];
//    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"html"];
//    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]
//                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
//                                     timeoutInterval:30.0];
    [self requestFromServer:req];
    self.webContainer.delegate = self;
}

- (void) requestFromServer:(NSURLRequest*)req
{
    switch (self.mode)
    {
        case URLConnectionMode:
        {
            self.title = @"NSURLConnection Sample";
            [NSURLConnection hookApi];
            [NSURLConnection sendAsynchronousRequest:req queue:nil completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                if (!connectionError)
                {
                    [self.webContainer loadHTMLString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                              baseURL:nil];
                }
            }];
            break;
        }
            
        case URLSessionMode:
        {
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.protocolClasses = @[NSClassFromString(@"SelfSignedHttpsURLProtocol")];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
            
            NSURLSessionTask *task = [session dataTaskWithRequest:req
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError* error){
                                                if (!error)
                                                {
                                                    [self.webContainer loadHTMLString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                                                              baseURL:nil];
                                                }
                                            }];
            
            [task resume];
            break;
        }
            
        case WebViewMode:
        {
            [SelfSignedHttpsURLProtocol start];
            [self.webContainer loadRequest:req];
            break;
        }
            
        case CompositeMode:
        {
            [SelfSignedHttpsURLProtocol start];
            NSURLResponse* rsp = nil;
            NSError* error = nil;
            NSData* data =[NSURLConnection sendSynchronousRequest:req returningResponse:&rsp error:&error];
            if (!error)
            {
                [self.webContainer loadHTMLString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                                          baseURL:nil];
            }
            break;
        }
            
        default:
            break;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"url:%@",[request URL]);
    return YES;
}

@end
