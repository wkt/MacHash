//
//  MHFinderServicesProvider.m
//  MacHash
//
//  Created by WeiKeting on 15-2-27.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "MHFinderServicesProvider.h"

@implementation MHFinderServicesProvider

- (id)initWithBlock:(void (^)(NSArray *files))hashFiles
{
    self = [super init];
    _hashFiles = hashFiles;
    return  self;
}

+ (NSArray *)filenamesFrom:(NSString *)aString
{
    NSMutableArray *ret = Nil;
    NSArray *files = [aString componentsSeparatedByString:@("\n")];
    if(files == NULL)files = [aString componentsSeparatedByString:@("\r")];
    if(files == NULL)files = [aString componentsSeparatedByString:@("\r\n")];
    if(files!=NULL){
        for (int i=0; i<[files count]; i++) {
            NSURL *url = [NSURL URLWithString:files[i]];
            if(ret == Nil)ret = [NSMutableArray arrayWithCapacity:1];
            [ret addObject:[url path]];
        }
    }
    return  ret;
}

+ (void)runCommand:(char* const*)args
{
    pid_t pid = fork();
    if(pid <0){
        NSLog(@"fork(): failed!");
    }else if(pid == 0){
        ///child
        execv(args[0],args);
    }else {
        //parent
        int st=0;
        waitpid(pid,&st,0);
    }
}


- (void)openForHash:(NSPasteboard *)pboard
             userData:(NSString *)userData error:(NSString **)error
{
    if(!_hashFiles)return;
    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    if (![pboard canReadObjectForClasses:classes options:options]) {
        *error = NSLocalizedString(@"Error: couldn't encrypt text.",
                                   @"pboard couldn't give string.");
        return;
    }
    
    NSString *pboardString = [pboard stringForType:NSPasteboardTypeString];
    NSArray *files = [MHFinderServicesProvider filenamesFrom:pboardString];
    if (!files) {
        *error = NSLocalizedString(@"Error: couldn't encrypt text.",
                                   @"self couldn't rotate letters.");
        return;
    }
    
    _hashFiles(files);
    
    [pboard clearContents];
}


+(void)setupServices:(void (^)(NSArray *files))hashFiles
{
    [NSApp setServicesProvider:[[MHFinderServicesProvider alloc] initWithBlock:hashFiles]];
    NSUpdateDynamicServices();
}
@end
