//
//  MHAppDelegate.h
//  MacHash
//
//  Created by WeiKeting on 02/25/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MHAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate,NSDraggingDestination>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
@property (weak) IBOutlet NSButton *dateChecked;
@property (weak) IBOutlet NSButton *md4Checked;
@property (weak) IBOutlet NSButton *sha1Checked;
@property (weak) IBOutlet NSButton *sha256Checked;
@property (weak) IBOutlet NSButton *crc32Checked;
@property (weak) IBOutlet NSView *topView;
@property (weak) IBOutlet NSProgressIndicator *currentFileProgress;
@property (weak) IBOutlet NSProgressIndicator *totalProgress;


@property BOOL isDoingHash;

- (IBAction)browserFiles:(id)sender;
- (IBAction)clearLog:(id)sender;

- (IBAction)saveLog:(id)sender;
@end
