//
//  JavaScriptBridgeReceiver.m
//  JSBridgeTest
//
//  Created by Toru Hisai on 11/03/25.
//  Copyright 2011 Kronecker's Delta Studio. All rights reserved.
//

#import "JavaScriptBridgeReceiver.h"

@implementation JavaScriptBridgeReceiver

@synthesize bridge;

- (id)init {
    [super init];
    
    JavaScriptBridge *brdg = [[JavaScriptBridge alloc] init];
    [self setBridge:brdg];
    [brdg release];

    return self;
}

- (void)dealloc {
    [super dealloc];
    [self setBridge:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    NSString *scheme = [url scheme];
    NSLog(@"url: %@", url);
    
    if ([scheme isEqualToString:@"bridge"]) {
        NSArray *path = [url pathComponents];
        NSLog(@"path: %@", path);
        
        [self performSelector:@selector(feedInstructions:) withObject:path];
        
        return NO;
    } else {
        return YES;
    }

}

- (void)feedInstructions:(NSArray *)instructions {
    for (NSString *str in instructions) {
        unichar head = [str characterAtIndex:0];
        NSString *tail = [str substringFromIndex:1];
        switch (head) {
            case '-':// operand
                [[self bridge] push:tail];
                break;
            case '@':// operator
                [[self bridge] operate:tail];
                break;
            default:
                break;
        }
        NSLog(@"-- %@", str);
    }
}

@end
