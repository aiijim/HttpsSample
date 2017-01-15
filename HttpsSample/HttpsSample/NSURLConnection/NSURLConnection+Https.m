//
//  NSURLConnection+Https.m
//  CertificateValid
//
//  Created by aiijim on 2017/1/13.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "NSURLConnection+Https.h"
#import <objc/runtime.h>
#import "CredentialsManager.h"

static void exchangeOCInstanceMethod(Class cls,SEL orig, SEL swizzle)
{
    Method originalMethod = class_getInstanceMethod(cls, orig);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzle);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

static void exchangeOCClassMethod(Class cls,SEL orig, SEL swizzle)
{
    Method originalMethod = class_getClassMethod(cls, orig);
    Method swizzledMethod = class_getClassMethod(cls, swizzle);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

static void *dummyDelegateKey = @"dummyDelegateKey";

typedef void (^completionHandler)(NSURLResponse* __nullable response, NSData* __nullable data, NSError* __nullable connectionError);

@interface NSURLConnectionProxy : NSObject <NSURLConnectionDataDelegate>

@property (strong, nonatomic) id originalDelegate;

@property (strong, nonatomic) NSURLResponse * response;
@property (strong, nonatomic) NSError * error;
@property (strong, nonatomic) NSMutableData* totalData;
@property (assign, nonatomic) BOOL isFinished;

//@property (strong, nonatomic) NSOperationQueue* queue;
@property (copy, nonatomic) completionHandler handler;

@end

@implementation NSURLConnectionProxy

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void) dealloc
{
    NSLog(@"self=%p,%@---%@",self,NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.isFinished = NO;
        self.totalData = [NSMutableData data];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self.originalDelegate respondsToSelector:@selector(connection:didFailWithError:)])
    {
        return [self.originalDelegate connection:connection didFailWithError:error];
    }
    
    self.isFinished = YES;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    if ([self.originalDelegate respondsToSelector:@selector(connectionShouldUseCredentialStorage:)])
    {
        return [self.originalDelegate connectionShouldUseCredentialStorage:connection];
    }
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [[CredentialsManager shareInstance] evaluateAuthenticationChallenge:challenge];
    }
    else
    {
        if ([self.originalDelegate respondsToSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)])
        {
            [self.originalDelegate connection:connection willSendRequestForAuthenticationChallenge:challenge];
        }
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:@""])
    {
        [[CredentialsManager shareInstance] evaluateAuthenticationChallenge:challenge];
    }
    else
    {
        if ([self.originalDelegate respondsToSelector:@selector(connection:didReceiveAuthenticationChallenge:)])
        {
            [self.originalDelegate connection:connection didReceiveAuthenticationChallenge:challenge];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([self.originalDelegate respondsToSelector:@selector(connection:didCancelAuthenticationChallenge:)])
    {
        [self.originalDelegate connection:connection didCancelAuthenticationChallenge:challenge];
    }
}


#pragma mark -

- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response
{
    if ([self.originalDelegate respondsToSelector:@selector(connection:willSendRequest:redirectResponse:)])
    {
        [self.originalDelegate connection:connection willSendRequest:request redirectResponse:response];
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    if([self.originalDelegate respondsToSelector:@selector(connection:didReceiveResponse:)])
    {
        [self.originalDelegate connection:connection didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.totalData appendData:data];
    if ([self.originalDelegate respondsToSelector:@selector(connection:didReceiveData:)])
    {
        [self.originalDelegate connection:connection didReceiveData:data];
    }
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if ([self.originalDelegate respondsToSelector:@selector(connection:willCacheResponse:)])
    {
        return [self.originalDelegate connection:connection willCacheResponse:cachedResponse];
    }
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.originalDelegate respondsToSelector:@selector(connectionDidFinishLoading:)])
    {
        [self.originalDelegate connectionDidFinishLoading:connection];
    }
    
    self.isFinished = YES;
    if (self.handler)
    {
        self.handler(self.response, [self.totalData copy], nil);
    }
}

@end
#pragma clang diagnostic pop

@implementation NSURLConnection (Https)

//+ (void) load
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
// 
//        exchangeOCInstanceMethod(self,
//                                 @selector(initWithRequest:delegate:startImmediately:),
//                                 @selector(initWithRequest_Https:delegate:startImmediately:));
//        
//        exchangeOCInstanceMethod(self,
//                                 @selector(initWithRequest:delegate:),
//                                 @selector(initWithRequest_Https:delegate:));
//        
//        exchangeOCClassMethod(   self,
//                                 @selector(sendSynchronousRequest:returningResponse:error:),
//                                 @selector(sendSynchronousRequest_Https:returningResponse:error:));
//        
//        exchangeOCClassMethod(   self,
//                              @selector(sendAsynchronousRequest:queue:completionHandler:),
//                              @selector(sendAsynchronousRequest_https:queue:completionHandler:));
//    });
//}

+ (void) hookApi
{
    exchangeOCInstanceMethod(self,
                             @selector(initWithRequest:delegate:startImmediately:),
                             @selector(initWithRequest_Https:delegate:startImmediately:));
    
    exchangeOCInstanceMethod(self,
                             @selector(initWithRequest:delegate:),
                             @selector(initWithRequest_Https:delegate:));
    
    exchangeOCClassMethod(   self,
                          @selector(sendSynchronousRequest:returningResponse:error:),
                          @selector(sendSynchronousRequest_Https:returningResponse:error:));
    
    exchangeOCClassMethod(   self,
                          @selector(sendAsynchronousRequest:queue:completionHandler:),
                          @selector(sendAsynchronousRequest_https:queue:completionHandler:));
}

- (id) dummyDelegate
{
    id dummy_delegate = objc_getAssociatedObject(self, &dummyDelegateKey);
    if (!dummy_delegate)
    {
        dummy_delegate = [NSURLConnectionProxy new];
        objc_setAssociatedObject(self, &dummyDelegateKey, dummy_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dummy_delegate;
}

- (nullable instancetype)initWithRequest_Https:(NSURLRequest *)request delegate:(nullable id)delegate startImmediately:(BOOL)startImmediately
{
    [[self dummyDelegate] setOriginalDelegate:delegate];
    return [self initWithRequest_Https:request delegate:[self dummyDelegate] startImmediately:startImmediately];
}

- (nullable instancetype)initWithRequest_Https:(NSURLRequest *)request delegate:(nullable id)delegate
{
    [[self dummyDelegate] setOriginalDelegate:delegate];
    return [self initWithRequest_Https:request delegate:[self dummyDelegate]];
}

+ (nullable NSData *)sendSynchronousRequest_Https:(NSURLRequest *)request returningResponse:(NSURLResponse * __nullable * __nullable)response error:(NSError **)error
{
    NSURLConnection* con = [self alloc];
    con = [con initWithRequest_Https:request delegate:[con dummyDelegate]];
    [con start];
    
    while (![[con dummyDelegate] isFinished])
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    if (response != NULL)
    {
        *response = [[con dummyDelegate] response];
    }
    if (error != NULL)
    {
        *error = [[con dummyDelegate] error];
    }
    
    return [[[con dummyDelegate] totalData] copy];
}

+ (void)sendAsynchronousRequest_https:(NSURLRequest*) request
                          queue:(NSOperationQueue*) queue
              completionHandler:(void (^)(NSURLResponse* __nullable response, NSData* __nullable data, NSError* __nullable connectionError)) handler
{
    NSURLConnection* con = [self alloc];
    NSURLConnectionProxy* dummyDelegate = [con dummyDelegate];
//    dummyDelegate.queue = queue;
    dummyDelegate.handler = handler;
    con = [con initWithRequest_Https:request delegate:dummyDelegate];
    [con start];
}

@end
