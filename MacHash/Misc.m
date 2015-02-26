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

+(void)openNewInstanceWithFiles:(NSArray*)filenames
{
    const char **args = malloc(sizeof(char*)*([filenames count]+7));
    int i=0;
    args[i++]="/usr/bin/open";
    args[i++]="-n";
    args[i++]=[[[NSBundle mainBundle] bundlePath] UTF8String];
    
    int j=0;
    for(;j<[filenames count];j++){
        args[i+j]=[[filenames objectAtIndex:j] UTF8String];
    }
    args[i+j]=NULL;
    
    free(args);
}

+(void)openNewInstanceWithFile:(NSString*)filename
{
    [Misc openNewInstanceWithFiles:[NSArray arrayWithObject:filename]];
}

@end
