
//
//  MHAppDelegate.m
//  MacHash
//
//  Created by WeiKeting on 02/25/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "MHAppDelegate.h"
#import "MHCrc32.h"
#import "Misc.h"
#include <sys/stat.h>

#include <CommonCrypto/CommonDigest.h>

@implementation MHAppDelegate

@synthesize isDoingHash;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.isDoingHash = NO;
    [self initTotalProgress:1];
    [self initCurrentProgress:1];
    [self.window registerForDraggedTypes: [NSArray arrayWithObject:NSFilenamesPboardType]];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if(self.isDoingHash){
        [Misc openNewInstanceWithFile:filename];
    }else{
        [self doHash:[NSArray arrayWithObject:[NSURL fileURLWithPath:filename]]];
    }
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    if(self.isDoingHash){
        [Misc openNewInstanceWithFiles:filenames];
    }else{
        NSMutableArray *urls = [NSMutableArray arrayWithCapacity:0];
        for(NSString *path in filenames){
            [urls addObject:[NSURL fileURLWithPath:path]];
        }
        [self doHash:urls];
    }
}

/*
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if(self.isDoingHash)return NSTerminateCancel;
    return NSTerminateNow;
}
 */

- (BOOL)windowShouldClose:(id)sender
{
    BOOL res = NO;
    if(self.isDoingHash)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Application is busying"
                                         defaultButton:@"YES"
                                       alternateButton:@"NO"
                                           otherButton:nil
                             informativeTextWithFormat:@"Quit now?"];
                if (NSAlertDefaultReturn == [alert runModal])
        {
            res = YES;
        }
    }else{
        res = YES;
    }
    //    NSLog(@"%s:%d",__func__,res);
    return res;
}


#pragma mark - Destination Operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if(self.isDoingHash)return NSDragOperationNone;
    if ( [[ [sender draggingPasteboard]  types] containsObject:NSFilenamesPboardType] ) {
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *urls = [NSMutableArray arrayWithCapacity:0];
        for(NSString *path in filenames){
            [urls addObject:[NSURL fileURLWithPath:path]];
        }
        [self doHash:urls];
    }
    return YES;
}

#pragma mark - Destination Operations end

- (IBAction)browserFiles:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:YES]; // yes if more than one dir is allowed
    
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){

        if (result == NSFileHandlingPanelOKButton) {
            [self doHash:[panel URLs]];
        }
    }];
    
}

- (IBAction)clearLog:(id)sender {
    [self.logTextView setString:@""];
}

- (IBAction)saveLog:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){
        
        if (result == NSFileHandlingPanelOKButton) {
            [Misc setStringToURL:[panel URL] data:[self.logTextView string]];
        }
    }];
}

- (void)initTotalProgress:(double)totalMax
{
    [self.totalProgress setMinValue:0];
    [self.totalProgress setDoubleValue:0];
    [self.totalProgress setMaxValue:totalMax];
}

- (void)initCurrentProgress:(double)currentMax
{
    [self.currentFileProgress setMinValue:0];
    [self.currentFileProgress setDoubleValue:0];
    [self.currentFileProgress setMaxValue:currentMax];
}

-(void)updateProgress:(double)current total:(double)total
{
    [self.currentFileProgress setDoubleValue:current];
    [self.totalProgress setDoubleValue:total];
}



- (void) doHash:(NSArray*)fileUrls
{
    if([self isDoingHash]){
        return;
    }
    BOOL needDate = ([self.dateChecked state] == NSOnState);
    BOOL needMD5 = ([self.md5Checked state] == NSOnState);
    BOOL needSHA1 = ([self.sha1Checked state] == NSOnState);
    BOOL needSHA256 = ([self.sha256Checked state] == NSOnState);
    BOOL needCRC32 = ([self.crc32Checked state] == NSOnState);

    if(!(needMD5||needSHA1||needSHA256||needCRC32)){
        ///各种算法中至少要选一个
        needMD5 = YES;
        [self.md5Checked setState:NSOnState];
    }
    self.isDoingHash = YES;
    [self initTotalProgress:[fileUrls count]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = Nil;
        CC_MD5_CTX md5={};
        CC_MD5_CTX *md5p = NULL;
        if(needMD5)md5p = &md5;
         
        CC_SHA1_CTX sha1 = {0};
        CC_SHA1_CTX *sha1p = NULL;
        if(needSHA1)sha1p = &sha1;

        CC_SHA256_CTX sha256 = {0};
        CC_SHA256_CTX *sha256p = NULL;
        if(needSHA256)sha256p = &sha256;
        
        MHCrc32 *crc32 = NULL;
        if(needCRC32)crc32 = [MHCrc32 newInstance];
        NSDate *date = NULL;
        NSMutableString *mdString = NULL;
        struct stat st = {0};
        time_t lastTime = 0;
        time_t *lastTimep = &lastTime;
        int i =0;
        size_t fileTotal = 0;
        size_t fileCur = 0;
        size_t *fileCurp = &fileCur;
        for (NSURL *url in fileUrls) {

            date = Nil;
            mdString = [NSMutableString stringWithCapacity:0];

            [mdString appendFormat:@"<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"
             "</head><body><span style=\"font-size:120%%\">File</span> : %@<br />",[url path]];
             
            stat([[url path] UTF8String],&st);
            if(S_ISDIR(st.st_mode)){
                [mdString appendString:@"<span style=\"font-size:120%%\">Folder</span> : YES<br />"];
            }else{
                [mdString appendFormat:@"<span style=\"font-size:120%%\">Size</span> : %lld (%@)<br />",st.st_size,[Misc byteToString:st.st_size]];
            }
            fileTotal = st.st_size;

            if(needDate){
                date = [NSDate dateWithTimeIntervalSince1970:st.st_mtimespec.tv_sec];
                [mdString appendFormat:@"<span style=\"font-size:120%%\">Modified</span> : %@ <br/>",[date descriptionWithLocale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]];
            }
            if(S_ISDIR(st.st_mode))[mdString appendString:@"<br/></body></html>"];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.logTextView.textStorage appendAttributedString:
                 [[NSAttributedString alloc] initWithHTML:
                  [NSData dataWithBytes:[mdString UTF8String] length:[mdString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] ] documentAttributes:Nil] ];

                NSMutableString *newS = [NSMutableString stringWithString:[self.logTextView string]];
                [self.logTextView scrollRangeToVisible:NSMakeRange([newS length],0)];
            });
            if(S_ISDIR(st.st_mode)){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgress:*fileCurp total:i+1];
                });
                continue;
            }
            
            fileCur=0;
            lastTime =0;
            mdString = [NSMutableString stringWithCapacity:0];

            if(md5p)CC_MD5_Init(md5p);
            if(sha1p)CC_SHA1_Init(sha1p);
            if(sha256p)CC_SHA256_Init(sha256p);
            if(crc32)crc32 = [crc32 initWith:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initCurrentProgress:fileTotal];
                [self updateProgress:0 total:i];
            });
            [self dealWithURL:url readFunc:^(const void *data,size_t data_len){
                if(md5p)CC_MD5_Update(md5p,data,data_len);
                if(sha1p)CC_SHA1_Update(sha1p, data, data_len);
                if(sha256p)CC_SHA256_Update(sha256p,data,data_len);
                if(crc32)[crc32 update:data length:data_len];
                *fileCurp += data_len;
                if(time(NULL)-*lastTimep>=1){
                    *lastTimep=time(lastTimep);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateProgress:*fileCurp total:i+(*fileCurp*1.0/fileTotal)/[fileUrls count]];
                    });
                }
            }];
            i++;
            if(needMD5){
                 unsigned char md[CC_MD5_DIGEST_LENGTH] = {0};
                 CC_MD5_Final(md,md5p);
                 [mdString appendFormat:@"<span style=\"font-size:120%%\">MD5</span> : %@<br/>",[Misc getHashString:md datalen:CC_MD5_DIGEST_LENGTH]];
             }
             if(needSHA1){
                 unsigned char sha1md[CC_SHA1_DIGEST_LENGTH] = {0};
                 CC_SHA1_Final(sha1md, sha1p);
                 [mdString appendFormat:@"<span style=\"font-size:120%%\">SHA1</span> : %@<br/>",[Misc getHashString:sha1md datalen:CC_SHA1_DIGEST_LENGTH]];
             }
            if(needSHA256){
                unsigned char sha256md[CC_SHA256_DIGEST_LENGTH] = {0};
                CC_SHA256_Final(sha256md, sha256p);
                [mdString appendFormat:@"<span style=\"font-size:120%%\">SHA256</span> : %@<br/>",[Misc getHashString:sha256md datalen:CC_SHA256_DIGEST_LENGTH]];
            }
            if(needCRC32){
                [mdString appendFormat:@"<span style=\"font-size:120%%\">CRC32</span> : %0lX<br/>",[crc32 finish]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [mdString appendString:@"<br/>"];
                [self.logTextView.textStorage appendAttributedString:
                 [[NSAttributedString alloc] initWithHTML:
                  [NSData dataWithBytes:[mdString UTF8String] length:[mdString length] ] documentAttributes:Nil] ];
                NSMutableString *newS = [NSMutableString stringWithString:[self.logTextView string]];
                [self.logTextView scrollRangeToVisible:NSMakeRange([newS length],0)];
                [self updateProgress:*fileCurp total:i];
             });

            ///刚刚算完休息一下
            usleep(500);
         }
         self.isDoingHash = NO;
     });
}
              
-(void) dealWithURL:(NSURL *)url readFunc:(void (^)(const void *data,size_t data_len))readFunc
{
    NSString *path = [url path];
    if(path){
        FILE *fp = fopen([path  UTF8String], "rb");
        char data[BUFFER_SIZE]={0};
        size_t datalen = 0;
        if(fp){
            while(!feof(fp)){
                datalen = fread(data, 1,BUFFER_SIZE, fp);
                if(datalen >0)readFunc(data,datalen);
            }
            fclose(fp);
        }
    }
}

@end


