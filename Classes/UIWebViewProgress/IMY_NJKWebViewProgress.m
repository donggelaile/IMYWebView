//
//  IMY_NJKWebViewProgress.m
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "IMY_NJKWebViewProgress.h"

static NSString * const IMY_completeRPCURL = @"webviewprogressproxy:///complete";

const CGFloat IMY_NJKInitialProgressValue = 0.1;
const CGFloat IMY_NJKInteractiveProgressValue = 0.5;
const CGFloat IMY_NJKFinalProgressValue = 0.9;

@implementation IMY_NJKWebViewProgress
{
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (id)init
{
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress
{
    if (_progress < IMY_NJKInitialProgressValue) {
        [self setProgress:IMY_NJKInitialProgressValue];
    }
}

- (void)incrementProgress
{
    CGFloat progress = self.progress;
    CGFloat maxProgress = _interactive ? IMY_NJKFinalProgressValue : IMY_NJKInteractiveProgressValue;
    CGFloat remainPercent = (CGFloat)_loadingCount / (CGFloat)_maxLoadCount;
    CGFloat increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress
{
    [self setProgress:1.0];
}

- (void)setProgress:(CGFloat)progress
{
    // progress should be incremental only
    if (progress > _progress || progress == 0) {
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset
{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}

- (NSString *)getNonFragmentStringWithURL:(NSURL*)url
{
    if (!url) {
        return @"";
    }
    if (url.fragment) {
        return [url.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:url.fragment] withString:@""];
    }
    else {
        return url.absoluteString;
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate


#pragma mark - 
#pragma mark Method Forwarding
// for future UIWebViewDelegate impl

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    
    if ([self.webViewProxyDelegate respondsToSelector:aSelector])
        return YES;
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if(!signature) {
        if([_webViewProxyDelegate respondsToSelector:selector]) {
            return [(NSObject *)_webViewProxyDelegate methodSignatureForSelector:selector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation*)invocation
{
    if ([_webViewProxyDelegate respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:_webViewProxyDelegate];
    }
}

@end
