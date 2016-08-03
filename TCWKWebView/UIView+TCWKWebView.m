//
//  UIView+TCWKWebView.m
//  TCKit
//
//  Created by dake on 16/7/27.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "UIView+TCWKWebView.h"
#import <objc/runtime.h>
#import "TCWKWebView.h"



@interface _TCWKWebViewExtra: NSObject
{
    @public
    __weak id _obsvr;
}

@end

@implementation _TCWKWebViewExtra

- (void)dealloc
{
    if (nil != _obsvr) {
        [[NSNotificationCenter defaultCenter] removeObserver:_obsvr];
    }
}

@end



@implementation UIView (TCWKWebView)

- (NSURLRequest *)originalRequest
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalRequest:(NSURLRequest *)request
{
    objc_setAssociatedObject(self, @selector(originalRequest), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (id)enterForgrdObsvr
{
    _TCWKWebViewExtra *extra = objc_getAssociatedObject(self, _cmd);
    return nil != extra ? extra->_obsvr : nil;
}

- (void)setEnterForgrdObsvr:(id)obsvr
{
    _TCWKWebViewExtra *extra = nil;
    if (nil != obsvr) {
        extra = [[_TCWKWebViewExtra alloc] init];
        extra->_obsvr = obsvr;
    }
    objc_setAssociatedObject(self, @selector(enterForgrdObsvr), extra, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)reloadOriRequestEnterForeground
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setReloadOriRequestEnterForeground:(BOOL)reload
{
    if (reload) {
        if (nil == self.enterForgrdObsvr) {
            __weak id<TCWKWebView> wSelf = (id<TCWKWebView>)self;
            self.enterForgrdObsvr = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                [wSelf loadRequest:wSelf.originalRequest];
            }];
        }
    } else {
        self.enterForgrdObsvr = nil;
    }
    objc_setAssociatedObject(self, @selector(reloadOriRequestEnterForeground), @(reload), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
