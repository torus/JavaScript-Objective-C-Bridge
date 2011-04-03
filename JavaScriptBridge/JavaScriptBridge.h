//
//  JavaScriptBridge.h
//  Untitled
//
//  Created by Toru Hisai on 3/25/11.
//  Copyright 2011 Avatar Reality Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JavaScriptBridge : NSObject {
	NSMutableArray *stack;
    UIWebView *webView;
}

@property(nonatomic, retain) NSMutableArray *stack;
@property(nonatomic, retain) UIWebView *webView;

- (void)push:(id)operand;
- (id)pop;
- (int)stackDepth;
- (void)operate:(NSString*)op;
- (void)error:(NSString*)mesg;
- (void)eval:(NSString*)expr;

- (void)op_callback;

- (void)op_num;
- (void)op_int;
- (void)op_str;
- (void)op_hexstr;
- (void)op_hexifydata;
- (void)op_base64data;

- (void)op_hmac_sha1;
- (void)op_http_get;
- (void)op_http_post;
- (void)op_http_send;

@end

