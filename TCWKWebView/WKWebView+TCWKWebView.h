//
//  WKWebView+TCWKWebView.h
//  TCKit
//
//  Created by jia on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "TCWKWebView.h"

@interface WKWebView (TCWKWebView) <TCWKWebView>

@property (nonatomic, weak) id<WKNavigationDelegate, WKUIDelegate> delegate;

@end
