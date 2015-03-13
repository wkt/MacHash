//
//  UpdateManager.h
//  MacHash
//
//  Created by WeiKeting on 15-3-6.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UpdateInfo

-(NSUInteger) versionCode;
-(NSString *)versionName;
-(NSString *)downloadURL;
-(NSString *)browseURL;

-(NSString *)updateLog;
-(NSInteger) updateLevel;

@end

@interface UpdateManager : NSURLConnection {
@private
    void (^__updateInfoHandler)(id<UpdateInfo> info);
}

@property (strong,readonly) NSMutableData *receivedData;


+(void)checkForUpdateWithWindow:(NSWindow*)window isLaunching:(BOOL)isLaunchingCheck;
+(BOOL)shouldCheckForUpdate;

@end


@interface UpdateLogViewController:NSViewController
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@end
