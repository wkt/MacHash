
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

static const size_t BUFFER_SIZE = 4096;

@implementation MHAppDelegate

@synthesize isDoingHash;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.isDoingHash = NO;
    [self initTotalProgress:1];
    [self initCurrentProgress:1];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
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
        NSAlert *alert = [NSAlert alertWithMessageText:@"App is busying"
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

- (IBAction)browserFiles:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:YES]; // yes if more than one dir is allowed
    
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){

        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *url in [panel URLs]) {
                NSLog(@"url:%@",[url path]);
            }
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
    [self.totalProgress setDoubleValue:total];
    [self.currentFileProgress setDoubleValue:current];
}

- (void) doHash:(NSArray*)fileUrls
{
    if([self isDoingHash]){
        return;
    }
    BOOL needDate = ([self.dateChecked state] == NSOnState);
    BOOL needMD5 = ([self.md4Checked state] == NSOnState);
    BOOL needSHA1 = ([self.sha1Checked state] == NSOnState);
    BOOL needSHA256 = ([self.sha256Checked state] == NSOnState);
    BOOL needCRC32 = ([self.crc32Checked state] == NSOnState);

    if(!(needMD5||needSHA1||needSHA256||needCRC32)){
        ///各种算法中至少要选一个
        return;
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
            fileCur=0;
            lastTime =0;
            date = Nil;

            mdString = [NSMutableString stringWithCapacity:0];
            [mdString appendFormat:@"File: %@\n",[url path]];
             
            stat([[url path] UTF8String],&st);
            [mdString appendFormat:@"Size: %lld\n",st.st_size];
            fileTotal = st.st_size;
            if(needDate){
                 date = [NSDate dateWithTimeIntervalSince1970:st.st_mtimespec.tv_sec];
                [mdString appendFormat:@"Modify: %@\n",date];
            }
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
                         [self updateProgress:*fileCurp total:i];
                     });
                 }
                }
              ];
            i++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateProgress:*fileCurp total:i];
            });
             if(needMD5){
                 unsigned char md[CC_MD5_DIGEST_LENGTH] = {0};
                 CC_MD5_Final(md,md5p);
                 [mdString appendFormat:@"MD5: %@\n",[Misc getHashString:md datalen:CC_MD5_DIGEST_LENGTH]];
             }
             if(needSHA1){
                 unsigned char sha1md[CC_SHA1_DIGEST_LENGTH] = {0};
                 CC_SHA1_Final(sha1md, sha1p);
                 [mdString appendFormat:@"SHA1: %@\n",[Misc getHashString:sha1md datalen:CC_SHA1_DIGEST_LENGTH]];
             }
            if(needSHA256){
                unsigned char sha256md[CC_SHA256_DIGEST_LENGTH] = {0};
                CC_SHA256_Final(sha256md, sha256p);
                [mdString appendFormat:@"SHA256: %@\n",[Misc getHashString:sha256md datalen:CC_SHA256_DIGEST_LENGTH]];
            }
            if(needCRC32){
                [mdString appendFormat:@"CRC32: %0lX\n",[crc32 finish]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                 NSMutableString *newS = [NSMutableString stringWithString:[self.logTextView string]];
                 [newS appendString:mdString];
                 [newS appendString:@"\n"];
                 [self.logTextView setString:newS];
             });

            ///刚刚算完休息一下
            usleep(500);
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [[self.window windowController] setEnabled:YES];
         });
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


