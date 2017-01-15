//
//  SelfSignedHttpsURLProtocol.h
//  AJAXSample
//
//  Created by aiijim on 17/1/15.
//  Copyright © 2017年 aiijim. All rights reserved.
//

#import "SelfSignedHttpsURLProtocol.h"
#import "CredentialsManager.h"

static NSString *const kOurRecursiveRequestFlagProperty = @"com.custom.SelfSignedHttpsURLProtocol";

@interface SelfSignedHttpsURLProtocol()<NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSURLConnection* realConnection;

@end

@implementation SelfSignedHttpsURLProtocol

+ (void)start
{
    [NSURLProtocol registerClass:self];
}

+ (void)stop
{
    [NSURLProtocol unregisterClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if (!([[[request URL] scheme] compare:@"https"] == NSOrderedSame))
    {
        return NO;
    }
    
    if ([self propertyForKey:kOurRecursiveRequestFlagProperty inRequest:request] != nil)
    {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return [request copy];
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [a isEqual:b];
}

- (void)startLoading
{
    NSMutableURLRequest* recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
    
    [[self class] setProperty:@YES forKey:kOurRecursiveRequestFlagProperty inRequest:recursiveRequest];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.realConnection = [[NSURLConnection alloc] initWithRequest:recursiveRequest delegate:self];
#pragma clang diagnostic pop
    
    [self.realConnection start];
}

- (void)stopLoading
{
    [self.realConnection cancel];
    self.realConnection = nil;
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [[CredentialsManager shareInstance] evaluateAuthenticationChallenge:challenge];
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
}

@end
