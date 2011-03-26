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
}

@property(nonatomic, retain) NSMutableArray *stack;

-(void)push:(NSString*)operand;
-(void)operate:(NSString*)op;

-(void)error:(NSString*)mesg;

-(void)op_num;
-(void)op_int;
-(void)op_hexstr;

-(void)op_hmac_sha1;
-(void)op_http_get;
-(void)op_http_post;

@end
