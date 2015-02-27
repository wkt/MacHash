//
//  MHFinderServicesProvider.h
//  MacHash
//
//  Created by WeiKeting on 15-2-27.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHFinderServicesProvider : NSObject
{
    void (^_hashFiles)(NSArray *files);
}

- (id)initWithBlock:(void (^)(NSArray *files))hashFiles;
- (void)openForHash:(NSPasteboard *)pboard
           userData:(NSString *)userData error:(NSString **)error;

+ (void)setupServices:(void (^)(NSArray *files))hashFiles;

@end
