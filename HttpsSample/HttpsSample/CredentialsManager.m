//
//  CredentialsManager.m
//  AJAXSample
//
//  Created by aiijim on 2017/1/13.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "CredentialsManager.h"

@interface CredentialsManager()

@property (atomic, strong, readonly ) NSMutableArray* mutableTrustedAnchors;

@end

@implementation CredentialsManager

- (instancetype) init
{
    self = [super init];
    if (self != nil)
    {
        _mutableTrustedAnchors = [NSMutableArray array];
    }
    return self;
}

+ (instancetype) shareInstance
{
    static dispatch_once_t onceToken;
    static CredentialsManager* _instance;
    dispatch_once(&onceToken, ^{
        _instance = [CredentialsManager new];
    });
    return _instance;
}

- (NSArray*) trustedAnchors
{
    NSArray* result = nil;
    
    @synchronized (self)
    {
        result = [self.mutableTrustedAnchors copy];
    }
    
    return result;
}

//添加一个信任证书
- (void)addTrustedAnchor:(id)newAnchor
{
    if (newAnchor == NULL)
    {
        return;
    }
    
    BOOL isFound;
    @synchronized (self)
    {
        isFound = [self->_mutableTrustedAnchors indexOfObject:newAnchor] != NSNotFound;
        if (!isFound)
        {
            [self->_mutableTrustedAnchors addObject:newAnchor];
        }
    }
}

//添加目录下的证书到信任列表
- (void)addTrustedAnchorPath:(NSString*)path
{
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString* file in files)
    {
        if ([file.pathExtension isEqualToString:@"cer"] || [file.pathExtension isEqualToString:@"pem"])
        {
            NSData* certData = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:file]];
            CFTypeRef certDataRef = CFBridgingRetain(certData);
            SecCertificateRef rootcert =SecCertificateCreateWithData(kCFAllocatorDefault,certDataRef);
            id anchor = CFBridgingRelease(rootcert);
            [self addTrustedAnchor:anchor];
            CFRelease(certDataRef);
        }
    }
}

//使用信任列表评估认证挑战
- (void)evaluateAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
    SecTrustRef trust = [[challenge protectionSpace] serverTrust];
    int err;
    SecTrustResultType trustResult = 0;
    err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)self.trustedAnchors);
    if (err == noErr)
    {
        err = SecTrustEvaluate(trust,&trustResult);
    }
    SecTrustSetAnchorCertificatesOnly(trust, self.onlyAnchor);
    BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    if (trusted)
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    else
    {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
}

@end
