//
//  JavaScriptBridgeReceiver.m
//  JSBridgeTest
//
//  Created by Toru Hisai on 11/03/25.
//  Copyright 2011 Kronecker's Delta Studio. All rights reserved.
//

#import "JavaScriptBridgeReceiver.h"
#import "JavaScriptBridge.h"

@implementation JavaScriptBridgeReceiver

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    NSString *scheme = [url scheme];
    NSLog(@"url: %@", url);
    
    if ([scheme isEqualToString:@"bridge"]) {
        NSArray *path = [url pathComponents];
        NSLog(@"path: %@", path);
        
        JavaScriptBridge *brdg = [[JavaScriptBridge alloc] init];
        
        for (NSString *str in path) {
            unichar head = [str characterAtIndex:0];
            NSString *tail = [str substringFromIndex:1];
            switch (head) {
                case '-':// operand
                    [brdg push:tail];
                    break;
                case '@':// operator
                    [brdg operate:tail];
                    break;
                default:
                    break;
            }
            NSLog(@"-- %@", str);
        }
        
        return NO;
    } else {
        return YES;
    }

}

@end
