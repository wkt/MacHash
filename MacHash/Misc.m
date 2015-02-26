//
//  Misc.m
//  MacHash
//
//  Created by WeiKeting on 02/26/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "Misc.h"

@implementation Misc

+(NSString*) getHashString:(unsigned char *)data datalen:(size_t) datalen
{
    size_t hashlen =datalen*2+1;
    char *hash = malloc(hashlen);
    for(int i=0;i<datalen;i++){
        snprintf(hash+i*2, hashlen-(i*2), "%02X",data[i]);
    }
    return [NSString stringWithFormat:@"%s",hash];
}

+(void) setStringToURL:(NSURL*)url data:(NSString*)s
{
    FILE *fp = fopen([[url path] UTF8String], "wb");
    if(fp){
        fwrite([s UTF8String],1,[s length], fp);
        fclose(fp);
    }
}

@end
