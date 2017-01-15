//
//  CredentialsManager.h
//  AJAXSample
//
//  Created by aiijim on 2017/1/17.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CredentialsManager : NSObject

+ (instancetype) shareInstance;

//是否只信任信任列表中的证书
@property (atomic, assign) BOOL onlyAnchor;

//信任证书列表
@property (atomic, copy, readonly ) NSArray* trustedAnchors;

//添加一个信任证书
- (void)addTrustedAnchor:(id)newAnchor;

//添加目录下的证书到信任列表
- (void)addTrustedAnchorPath:(NSString*)path;

//使用信任列表评估认证挑战
- (void)evaluateAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;

@end
