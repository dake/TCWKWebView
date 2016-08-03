//
//  TCWKWebView.h
//  TCKit
//
//  Created by jia on 16/2/26.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TCWKWebView <NSObject>

@required
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;
@property (nonatomic, assign) BOOL scalesPageToFit;
//@property (nonatomic, assign) UIDataDetectorTypes dataDetectorTypes;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) UIView *webHeaderView;
@property (nonatomic, assign) BOOL reloadOriRequestEnterForeground;

- (void)loadRequest:(NSURLRequest *)request;
- (BOOL)canGoBack;
- (void)goBack;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler;

// refer: http://www.jianshu.com/p/d2c478bbcca5?hmsr=toutiao.io&utm_medium=toutiao.io&utm_source=toutiao.io
- (void)clearCookies;

@end
