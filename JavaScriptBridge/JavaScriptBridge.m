//
//  JavaScriptBridge.m
//  Untitled
//
//  Created by Toru Hisai on 3/25/11.
//  Copyright 2011 Avatar Reality Inc. All rights reserved.
//

#import "JavaScriptBridge.h"
#include <objc/runtime.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation JavaScriptBridge

@synthesize stack;

- (id)init {
	[super init];
	[self setStack:[[NSMutableArray alloc] init]];
	NSLog(@"init: %@", self);
	return self;
}

-(void)push:(NSString*)operand {
	[stack addObject:operand];
	NSLog(@"pushed: %@, [%d]", operand, [stack count]);
}

-(void)operate:(NSString*)op {
	NSLog(@"--> [%d]", [stack count]);
	NSString *func = [NSString stringWithFormat:@"op_%@", op];
	char buf[128];
	[func getCString:buf maxLength:sizeof(buf) encoding:NSUTF8StringEncoding];
	SEL sel = sel_getUid(buf);
	if ([self respondsToSelector:sel]) {
		objc_msgSend(self, sel);
	} else {
		NSLog(@"unknown operator: %@", op);
	}
	NSLog(@"--> [%d]", [stack count]);
}

-(void)error:(NSString*)mesg {
	NSLog(@"JavaScript bridge error: %@", mesg);
}

-(void)op_call {
}

// string -> number
-(void)op_num {
	if ([stack count] > 0) {
		NSString *str = [stack lastObject];
		[stack removeLastObject];
		[stack addObject:[NSNumber numberWithDouble:[str doubleValue]]];
	} else {
		[self error:@"ERROR: stack underflow"];
	}

}

// string -> integer
-(void)op_int {
	if ([stack count] > 0) {
		NSString *str = [stack lastObject];
		[stack removeLastObject];
		[stack addObject:[NSNumber numberWithInteger:[str integerValue]]];
	} else {
		[self error:@"ERROR: stack underflow"];
	}
	
}

// a:number, b:number -> a+b:number
-(void)op_add {
	if ([stack count] > 1) {
		NSNumber *n1 = [stack lastObject];
		[stack removeLastObject];
		NSNumber *n2 = [stack lastObject];
		[stack removeLastObject];
		[stack addObject:[NSNumber numberWithDouble:[n1 doubleValue] + [n2 doubleValue]]];
	} else {
		[self error:@"ERROR: stack underflow"];
	}
	
}

// any -> (none)
-(void)op_print {
	if ([stack count] > 0) {
		NSString *str = [NSString stringWithFormat:@"%@", [stack lastObject]];
		[stack removeLastObject];
		NSLog(@"print: %@", str);
	} else {
		[self error:@"ERROR: stack underflow"];
	}
}

// src:string -> data
-(void)op_hexstr {
	if ([stack count] > 0) {
		NSString *str = [stack lastObject];
		[stack removeLastObject];
		
		NSUInteger len = [str lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
		NSMutableData *data = [NSMutableData dataWithLength:len / 2];

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
		[stack addObject:data];
	} else {
		[self error:@"ERROR: stack underflow"];
	}
}

// key:string / data:string -> data
-(void)op_hmac_sha1 {
	if ([stack count] > 1) {
		NSString *key = [stack lastObject];
		[stack removeLastObject];
		NSLog(@"hmac_sha1: key: %@", key);
		
		// The length does not include space for a terminating NULL character.
		NSInteger keylen = [key lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
		char *keybuf = malloc(keylen + 1);
		// The maximum number of bytes in the string to return in buffer (including the NULL termination byte).
		[key getCString:keybuf maxLength:keylen + 1 encoding:NSASCIIStringEncoding];
		
		NSString *str = [stack lastObject];
		[stack removeLastObject];
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
		[stack addObject:dest];
	} else {
		[self error:@"ERROR: stack underflow"];
	}
}

//-(void)op_http_get;
//-(void)op_http_post;

@end
