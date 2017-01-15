//
//  MainViewController.m
//  HttpsSample
//
//  Created by aiijim on 17/1/15.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "MainViewController.h"
#import "UIWebViewController.h"
#import "WKWebViewController.h"

@interface MainViewController()

@property (assign, nonatomic) DemoMode mode;

@end

@implementation MainViewController

- (IBAction)clickConnectionBtn:(id)sender
{
    self.mode = URLConnectionMode;
    [self performSegueWithIdentifier:@"preview" sender:self];
}

- (IBAction)clickSessionBtn:(id)sender
{
    self.mode = URLSessionMode;
    [self performSegueWithIdentifier:@"preview" sender:self];
}

- (IBAction)clickWebviewBtn:(id)sender
{
    self.mode = WebViewMode;
    [self performSegueWithIdentifier:@"preview" sender:self];
}

- (IBAction)clickWKWebViewBtn:(id)sender
{
    WKWebViewController* controller = [WKWebViewController new];
    [self.navigationController pushViewController:controller animated:YES];
}
- (IBAction)clickComposeBtn:(id)sender
{
    self.mode = CompositeMode;
    [self performSegueWithIdentifier:@"preview" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIWebViewController* controller = (UIWebViewController*)segue.destinationViewController;
    controller.mode = self.mode;
}

@end
