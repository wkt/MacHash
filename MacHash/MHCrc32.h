//
//  MHCrc32.h
//  MacHash
//
//  Created by WeiKeting on 02/25/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHCrc32 : NSObject{
    unsigned long _inCrc32;
    unsigned long _crc32;
}

- (id)initWith:(unsigned long)inCrc32;

- (void)update:(const void *)buf  length:(size_t)bufLen;

- (unsigned long)finish;

+(id)newInstance;

@end
