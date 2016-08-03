//
//  WKWebView+TCWKWebView.m
//  TCKit
//
//  Created by jia on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "WKWebView+TCWKWebView.h"
#import <objc/runtime.h>
#import "UIView+TCWKWebView.h"


@interface _WKWebViewExtra : NSObject
{
    @public
    NSArray<__kindof UIView *> *_kvoSubviews;
}

@property (nonatomic, weak) UIView *headerView;

@end


@implementation _WKWebViewExtra

- (void)dealloc
{
    self.kvoSubviews = nil;
}

- (void)setKvoSubviews:(NSArray<__kindof UIView *> *)kvoSubviews
{
    if (_kvoSubviews == kvoSubviews) {
        return;
    }
    
    for (UIView *subView in _kvoSubviews) {
        [subView removeObserver:self forKeyPath:PropertySTR(frame)];
    }
    
    _kvoSubviews = kvoSubviews;
    for (UIView *subView in _kvoSubviews) {
        [subView addObserver:self forKeyPath:PropertySTR(frame) options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)setWebView:(WKWebView *)webView
{
    NSMutableArray *arry = NSMutableArray.array;
    for (UIView *subView in webView.scrollView.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"WKContentView")] || CGSizeEqualToSize(subView.frame.size, CGSizeZero)) {
            [arry addObject:subView];
        }
    }
    self.kvoSubviews = arry.copy;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context
{
    if ([_kvoSubviews containsObject:object] && [keyPath isEqualToString:PropertySTR(frame)]) { // bug fix for iOS9
        NSValue *value = change[NSKeyValueChangeNewKey];
        if ([value isKindOfClass:NSValue.class]) {
            CGRect frame = value.CGRectValue;
            CGFloat head = CGRectGetHeight(_headerView.frame);
            if (CGRectGetMinY(frame) < head) {
                frame.origin.y = head;
                ((UIView *)object).frame = frame;
            }
        }
    }
}


@end


@implementation WKWebView (TCWKWebView)

//@dynamic dataDetectorTypes;

+ (void)load
{
    [self tc_swizzle:@selector(loadRequest:)];
}

- (id<WKNavigationDelegate, WKUIDelegate>)delegate
{
    id delegate = self.navigationDelegate ?: (id)self.UIDelegate;
    return (id<WKNavigationDelegate, WKUIDelegate>)delegate;
}

- (void)setDelegate:(id<WKNavigationDelegate, WKUIDelegate>)delegate
{
    self.navigationDelegate = delegate;
    self.UIDelegate = delegate;
}

- (BOOL)scalesPageToFit
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit
{
    if (scalesPageToFit == self.scalesPageToFit) {
        return;
    }
    
    static NSString *const jScript = @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
    
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    
    if (scalesPageToFit) {
        [self.configuration.userContentController addUserScript:wkUScript];
    } else {
        NSMutableArray *userScripts = self.configuration.userContentController.userScripts.copy;
        NSInteger index = NSNotFound;
        for (WKUserScript *script in userScripts) {
            if ([script.source isEqualToString:jScript]) {
                index = [userScripts indexOfObject:script];
                break;
            }
        }
        
        if (index != NSNotFound) {
            [userScripts removeObjectAtIndex:index];
        }
        
        for (WKUserScript *script in userScripts) {
            [self.configuration.userContentController addUserScript:script];
        }
    }

    objc_setAssociatedObject(self, @selector(scalesPageToFit), @(scalesPageToFit), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable WKNavigation *)tc_loadRequest:(NSURLRequest *)request
{
    self.originalRequest = request;
    return [self tc_loadRequest:request];
}

/*
- (void)setDataDetectorTypes:(NSUInteger)dataDetectorTypes
{
    return;
}

- (NSUInteger)dataDetectorTypes
{
    return 0; // UIDataDetectorTypeNone
}
 */

- (void)clearCookies
{
    if (Nil != WKWebsiteDataStore.class) {
        WKWebsiteDataStore *dateStore = [WKWebsiteDataStore defaultDataStore];
        [dateStore fetchDataRecordsOfTypes:WKWebsiteDataStore.allWebsiteDataTypes completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
            for (WKWebsiteDataRecord *record in records) {
                NSRange range = [record.displayName rangeOfString:self.originalRequest.URL.host];
                if (range.location != NSNotFound) {
                    [dateStore removeDataOfTypes:record.dataTypes
                                  forDataRecords:@[record]
                               completionHandler:^{
                                   DLog(@"Cookies for %@ deleted successfully",record.displayName);
                               }];
                }
            }
        }];
        
    } else {
        NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSString *cookiesFolderPath = [libraryPath stringByAppendingPathComponent:@"Cookies"];
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:NULL];
    }
}


#pragma mark -

- (_WKWebViewExtra *)obsvrExtra
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setObsvrExtra:(_WKWebViewExtra *)obsvrExtra
{
    objc_setAssociatedObject(self, @selector(obsvrExtra), obsvrExtra, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)webHeaderView
{
    return self.obsvrExtra.headerView;
}

- (void)setWebHeaderView:(UIView *)webHeaderView
{
    NSArray *kvoSubviews = nil;
    _WKWebViewExtra *extra = self.obsvrExtra;
    
    if (nil != extra) {
        kvoSubviews = extra->_kvoSubviews;
    }
    
    if (nil == webHeaderView) {
        self.obsvrExtra = nil;
    } else if (nil == extra) {
        extra = [[_WKWebViewExtra alloc] init];
        extra.webView = self;
        self.obsvrExtra = extra;
        
        kvoSubviews = extra->_kvoSubviews;
    }

    BOOL needUpdate = NO;
    UIScrollView *scrollView = self.scrollView;
    
    UIView *headerView = self.webHeaderView;
    if (nil == headerView) {
        if (nil != webHeaderView) {
            needUpdate = YES;
            headerView = webHeaderView;
        }
    } else {
        needUpdate = YES;
        
        if (headerView != webHeaderView) {
            needUpdate = YES;
            [headerView removeFromSuperview];
            headerView = webHeaderView;
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
            extra.headerView = headerView;
        }
        
        NSParameterAssert(headerView.superview == scrollView);
    }
    
    if (needUpdate && nil != kvoSubviews) {
        CGFloat h = CGRectGetMaxY(frame);
        for (UIView *subView in kvoSubviews) {
            // bug fix for iOS8
            CGRect rect = subView.frame;
            if (CGRectGetMinY(rect) < h) {
                rect.origin.y = h;
                subView.frame = rect;
            }
        }
    }
}

@end


@implementation UIScrollView (HeaderView)

+ (void)load
{
    if (Nil != WKWebView.class) {
        [self tc_swizzle:@selector(setContentSize:)];
    }
}

- (void)tc_setContentSize:(CGSize)contentSize
{
    if ([self isKindOfClass:NSClassFromString(@"WKScrollView")]) {
        
        CGFloat height = 0;
        for (UIView *view in self.subviews) {
            CGFloat h = CGRectGetMaxY(view.frame);
            if (h > height) {
                height = h;
            }
        }
        
        if (contentSize.height < height) {
            contentSize.height = height;
        }
    }
    
    [self tc_setContentSize:contentSize];
}

@end

