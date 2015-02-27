//
//  Misc.h
//  MacHash
//
//  Created by WeiKeting on 02/26/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BUFFER_SIZE  4096

@interface Misc : NSObject

+(NSString*) getHashString:(unsigned char *)data datalen:(size_t) datalen;
+(void) setStringToURL:(NSURL*)url data:(NSString*)s;
+(void)openNewInstanceWithFiles:(NSArray*)filenames;
+(void)openNewInstanceWithFile:(NSString*)filename;
@end
