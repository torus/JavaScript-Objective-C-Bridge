//
//  JavaScriptBridge.m
//  Untitled
//
//  Created by Toru Hisai on 3/25/11.
//  Copyright 2011 Avatar Reality Inc. All rights reserved.
//

#import "JavaScriptBridge.h"
#import "NSStringAdditions.h"
#import "JavaScriptBridgeURLConnectionDelegate.h"

#include <objc/runtime.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation JavaScriptBridge

@synthesize stack, webView;

- (id)init {
	[super init];
	[self setStack:[[NSMutableArray alloc] init]];
	NSLog(@"init: %@", self);
	return self;
}

- (void)push:(NSString*)operand {
	[[self stack] addObject:operand];
	NSLog(@"pushed: %@, [%d]", operand, [self stackDepth]);
}

- (id)pop {
    id obj = [[[[self stack] lastObject] retain] autorelease];
    [[self stack] removeLastObject];
    
    return obj;
}

- (int)stackDepth {
    return [[self stack] count];
}

- (void)operate:(NSString*)op {
	NSLog(@"--> [%d]", [self stackDepth]);
	NSString *func = [NSString stringWithFormat:@"op_%@", op];
	char buf[128];
	[func getCString:buf maxLength:sizeof(buf) encoding:NSUTF8StringEncoding];
	SEL sel = sel_getUid(buf);
	if ([self respondsToSelector:sel]) {
		objc_msgSend(self, sel);
	} else {
		NSLog(@"unknown operator: %@", op);
	}
	NSLog(@"--> [%d]", [self stackDepth]);
}

- (void)error:(NSString*)mesg {
	NSLog(@"JavaScript bridge error: %@", mesg);
}

#define CHECK_STACK_DEPTH_WITH_FAIL(n, fail) \
do {\
    const char *name = sel_getName(_cmd);\
    NSLog(@"method = %s", name);\
    if ([self stackDepth] < (n)) {\
        [self error:[NSString stringWithFormat:@"%s: stack underflow", name]];\
        return fail;\
    }\
} while (0)

#define CHECK_STACK_DEPTH(n) CHECK_STACK_DEPTH_WITH_FAIL(n,)

- (void)op_call {
}

// string -> number
- (void)op_num {
    CHECK_STACK_DEPTH(1);
    
    NSString *str = [self pop];
    [self push:[NSNumber numberWithDouble:[str doubleValue]]];
}

// string -> integer
- (void)op_int {
    CHECK_STACK_DEPTH(1);
    
    NSString *str = [self pop];
    [self push:[NSNumber numberWithInteger:[str integerValue]]];
}

// data -> str
- (void)op_str {
    CHECK_STACK_DEPTH(1);

    NSData *dat = [self pop];
    NSString *str = [[[NSString alloc] initWithData:dat encoding:NSUTF8StringEncoding] retain];
    [self push:str];
    [str release];
}

// a:number/string, b:number/string -> a+b:number
- (void)op_add {
    CHECK_STACK_DEPTH(2);

    NSNumber *n1 = [self pop];
    NSNumber *n2 = [self pop];
    [self push:[NSNumber numberWithDouble:[n1 doubleValue] + [n2 doubleValue]]];
}

// any -> (none)
- (void)op_print {
    CHECK_STACK_DEPTH(1);

    NSString *str = [NSString stringWithFormat:@"%@", [self pop]];
    NSLog(@"print: %@", str);
}

// src:string -> data
- (void)op_hexstr {
    CHECK_STACK_DEPTH(1);
    
    NSString *str = [self pop];
    
    NSUInteger len = [str lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *data = [[NSMutableData alloc] init];
    
    if (len % 2 > 0) {
        [self error:@"odd number of character"];
    } else {
        int p = 0;
        while (p < len) {
            NSScanner *scan = [NSScanner scannerWithString:[str substringWithRange:NSMakeRange(p, 2)]];
            unsigned int val = 0;
            [scan scanHexInt:&val];
            p += 2;
            unsigned char chr = val;
            [data appendBytes:&chr length:1];
        }
    }
    
    NSLog(@"hexstr: %@", data);
    [self push:data];
    [data release];
}

// numargs:int/string, funcname:string, arg:string[, ...] -> (none)
- (void)op_callback {
    CHECK_STACK_DEPTH(2);
    
    NSNumber *num = [self pop];
    NSString *funcname = [self pop];
    
    NSInteger n = [num integerValue];
    
    NSLog(@"callback: [%d] num: %@, %d, func: %@", [self stackDepth], num, n, funcname);
    
    CHECK_STACK_DEPTH(n);

    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < n; i ++) {
        NSString *arg = [self pop];
        if (!arg) {
            arg = @"";
        }
            // arg must be a *safe* string, which doesn't contain any control charactor nor ", \, etc...
        [args addObject:arg];
    }
    
    NSString *arglist = n > 0 ? [NSString stringWithFormat:@"\"%@\"", [args componentsJoinedByString:@"\",\""]] : @"";
    NSString *expr = [NSString stringWithFormat:@"%@(%@)", funcname, arglist];
    NSLog(@"callback: %@", expr);
    [self performSelector:@selector(eval:) withObject:expr afterDelay:0];
    [args release];
}

- (void)eval:(NSString*)expr {
    NSLog(@"eval: %@ -> webView: %@", expr, [self webView]);
    [[self webView] stringByEvaluatingJavaScriptFromString:expr];
}

// data -> hexstr:string
- (void)op_hexifydata {
    CHECK_STACK_DEPTH(1);

    NSData *dat = [self pop];
    
    NSMutableString *str = [[NSMutableString alloc] init];
    const unsigned char *bytes = [dat bytes];
    NSUInteger len = [dat length];
    
    for (NSUInteger i = 0; i < len; i ++) {
        unsigned char ch = bytes[i];
        [str appendFormat:@"%02x", ch];
    }
    
    [self push:str];
    [str release];
}

// data -> base64:string
- (void)op_base64data {
    CHECK_STACK_DEPTH(1);
    
    NSData *dat = [self pop];
    NSString *str = [NSString base64StringFromData:dat length:[dat length]];
    
    [self push:str];
}

// key:string / data:string -> data
- (void)op_hmac_sha1 {
    CHECK_STACK_DEPTH(2);
    
    NSString *key = [self pop];
    NSLog(@"hmac_sha1: key: %@", key);
    
		// The length does not include space for a terminating NULL character.
    NSInteger keylen = [key lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    char *keybuf = malloc(keylen + 1);
		// The maximum number of bytes in the string to return in buffer (including the NULL termination byte).
    [key getCString:keybuf maxLength:keylen + 1 encoding:NSASCIIStringEncoding];
    
    NSString *str = [self pop];
    NSLog(@"hmac_sha1: str: %@", str);
    
		// The length does not include space for a terminating NULL character.
    NSInteger datalen = [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    char *databuf = malloc(datalen + 1);
		// The maximum number of bytes in the string to return in buffer (including the NULL termination byte).
    [str getCString:databuf maxLength:datalen + 1 encoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, keybuf, keylen, databuf, datalen, digest);
    
    free(keybuf);
    free(databuf);
    
    NSData *dest = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    [self push:dest];
}

static NSMutableURLRequest*
prepareHTTPConnection (JavaScriptBridge* self, SEL _cmd)
{
    CHECK_STACK_DEPTH_WITH_FAIL(2, nil);
    
    NSString *url_str = [self pop];
    NSInteger n = [[self pop] integerValue];
    
    NSURL *url = [NSURL URLWithString:url_str];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    CHECK_STACK_DEPTH_WITH_FAIL(n * 2, nil);
    for (NSInteger i = 0; i < n; i ++) {
        NSString *field = [self pop];
        NSString *value = [self pop];
        [req addValue:value forHTTPHeaderField:field];
    }
    
    return req;
}

static void
returnHTTPHandle (JavaScriptBridge *self, SEL _cmd, NSURLRequest *req)
{
    JavaScriptBridgeURLConnectionDelegate *hndl = [[JavaScriptBridgeURLConnectionDelegate alloc] initWithWebView:[self webView]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:hndl startImmediately:NO];
    
    [self push:[NSString stringWithFormat:@"%d", [hndl connectionID]]];
    [self push:[NSString stringWithFormat:@"%d", conn]];
}

// url:string, num_header:number, header_field:string, header_value:string, ... -> connection_handle:string, connectionID:string
- (void)op_http_get {
    NSURLRequest *req = prepareHTTPConnection(self, _cmd);
    if (!req) {// fail
        return;
    }
    
    returnHTTPHandle(self, _cmd, req);
}

// url:string, num_header:number, header_field:string, header_value:string, ..., request_body:string -> connection_handle:string, connectionID:string
- (void)op_http_post {
    NSMutableURLRequest *req = prepareHTTPConnection(self, _cmd);
    if (!req) {// fail
        return;
    }
    
    CHECK_STACK_DEPTH(1);
    NSData *body = [self pop];
    [req setHTTPBody:body];
    [req setHTTPMethod:@"POST"];
    
    returnHTTPHandle(self, _cmd, req);
}

// request_handle:string -> (none)
- (void)op_http_send {
    CHECK_STACK_DEPTH(1);
    NSURLConnection *conn = (NSURLConnection*)[[self pop] integerValue];

    [conn start];
}

// oauth_token:string, oauth_token_secret:string -> (none)
- (void)op_store_twitter_credential {
    CHECK_STACK_DEPTH(2);
    NSString *token = [self pop];
    NSString *secret = [self pop];
    
    NSLog(@"token = %@, secret = %@", token, secret);
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setValue:token forKey:@"oauth_token"];
    [def setValue:secret forKey:@"oauth_token_secret"];
}

// (none) -> oauth_token:string, oauth_token_secret:string
- (void)op_twitter_credential {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *token = [def stringForKey:@"oauth_token"];
    NSString *secret = [def stringForKey:@"oauth_token_secret"];
    
    [self push:secret];
    [self push:token];
}

// url:string -> handle:string
- (void)op_open_url_in_new_browser {
    CHECK_STACK_DEPTH(1);
    NSString *url = [self pop];
    
    UIWebView *newWebView = [[UIWebView alloc] initWithFrame:[[self webView] frame]];
    [newWebView setDelegate:[[self webView] delegate]];
    [[self webView] addSubview:newWebView];
    [newWebView release];
    
    [newWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self push:[NSString stringWithFormat:@"%d", newWebView]];
}

// handle:string -> (none)
- (void)op_close_browser {
    CHECK_STACK_DEPTH(1);
    NSInteger hndl = [[self pop] integerValue];
    UIWebView *wv = (UIWebView*)hndl;
    
    [wv removeFromSuperview];
}

@end
