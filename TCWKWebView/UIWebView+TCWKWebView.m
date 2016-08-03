//
//  UIWebView+TCWKWebView.m
//  TCKit
//
//  Created by jia on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "UIWebView+TCWKWebView.h"
#import "UIView+TCWKWebView.h"

@implementation UIWebView (TCWKWebView)


+ (void)load
{
    [self tc_swizzle:@selector(loadRequest:)];
}

- (void)clearCookies
{
    for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
        NSRange domainRange = [cookie.domain rangeOfString:self.request.URL.host];
        if (domainRange.location != NSNotFound) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSString *string = [self stringByEvaluatingJavaScriptFromString:javaScriptString];
    
    if (nil != completionHandler) {
        completionHandler(string, nil);
    }
}


- (void)tc_loadRequest:(NSURLRequest *)request
{
    self.originalRequest = request;
    [self tc_loadRequest:request];
}


#pragma mark -


- (UIView *)webHeaderView
{
    return [self bk_associatedValueForKey:_cmd];
}

- (void)setWebHeaderView:(UIView *)webHeaderView
{
    BOOL needResetTopInsets = NO;
    UIScrollView *scrollView = self.scrollView;
    
    UIView *headerView = self.webHeaderView;
    if (nil == headerView) {
        if (nil != webHeaderView) {
            needResetTopInsets = YES;
            headerView = webHeaderView;
        }
    } else {
        needResetTopInsets = YES;
        
        if (headerView != webHeaderView) {
            needResetTopInsets = YES;
            [headerView removeFromSuperview];
            headerView = webHeaderView;
        } else if (nil == webHeaderView) {
            [self bk_weaklyAssociateValue:nil withKey:@selector(webHeaderView)];
        }
    }
    
    CGRect frame = CGRectZero;
    if (nil != headerView) {
        frame = headerView.frame;
        frame.origin = CGPointZero;
        headerView.frame = frame;
        
        if (headerView.superview == nil) {
            [scrollView addSubview:headerView];
            headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
            [self bk_weaklyAssociateValue:headerView withKey:@selector(webHeaderView)];
        }
        
        NSParameterAssert(headerView.superview == scrollView);
    }
    
    if (needResetTopInsets) {
        for (UIView *subView in scrollView.subviews) {
            if ([subView isKindOfClass:NSClassFromString(@"UIWebBrowserView")]) {
                CGRect rect = subView.frame;
                rect.origin.y = CGRectGetMaxY(frame);
                subView.frame = rect;
                break;
            }
        }
    }
}

@end
