//
//  UIWebViewController.h
//  AJAXSample
//
//  Created by aiijim on 2017/1/17.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DemoMode) {
    URLConnectionMode,
    URLSessionMode,
    WebViewMode,
    WKWebViewMode,
    CompositeMode,
};

@interface UIWebViewController : UIViewController

@property (assign, nonatomic) DemoMode mode;

@end

