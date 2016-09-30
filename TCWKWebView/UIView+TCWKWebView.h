//
//  UIView+TCWKWebView.h
//  TCKit
//
//  Created by dake on 16/7/27.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (TCWKWebView)

@property (nonatomic, strong) NSURLRequest *originalRequest;
@property (nonatomic, assign) BOOL reloadOriRequestEnterForeground;

+ (NSString *)tc_systemUserAgent;

@end
