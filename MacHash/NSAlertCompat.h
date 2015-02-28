//
//  NSAlertCompat.h
//  MacHash
//
//  Created by WeiKeting on 15-2-28.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAlertCompat : NSObject
@property NSAlert *privateAlert;
+ (void)alertToSheet:(NSAlert*)alert beginSheetModalForWindow:(NSWindow *)sheetWindow
               completionHandler:(void (^)(NSModalResponse returnCode))handler;
+(NSModalResponse)runAlertSheetModal:(NSAlert*)alert sheetWindow:(NSWindow *)window;
@end
