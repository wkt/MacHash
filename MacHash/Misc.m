//
//  Misc.m
//  MacHash
//
//  Created by WeiKeting on 02/26/2015.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "Misc.h"

static const size_t BYTE = 1L;
static const size_t KB = BYTE * 1024L;
static const size_t MB = KB   * 1024L;
static const size_t GB = MB   * 1024L;
static const size_t TB = GB   * 1024L;

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
        const char *ss =[s UTF8String];
        size_t n=0;
        size_t len = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        while(n<len){
            n+=fwrite(ss+n,1,MIN(len-n,BUFFER_SIZE), fp);
        }
        fclose(fp);
    }
}

+(NSString*)byteToString:(uint64_t)size
{
    if(size <KB){
        return  [NSString stringWithFormat:@"%llu Byte",size];
    }else if(size <MB){
        return  [NSString stringWithFormat:@"%.1f KB",size*1.0/KB];
    }else if(size <GB){
        return  [NSString stringWithFormat:@"%.2f MB",size*1.0/MB];
    }else if(size <TB){
        return  [NSString stringWithFormat:@"%.2f GB",size*1.0/GB];
    }
    return  [NSString stringWithFormat:@"%.2f TB",size*1.0/TB];
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
    args[i++]="-a";
    args[i++]=[[[NSBundle mainBundle] bundlePath] UTF8String];
    
    int j=0;
    for(;j<[filenames count];j++){
        args[i+j]=[[filenames objectAtIndex:j] UTF8String];
    }
    args[i+j]=NULL;
    [Misc runCommand:args];
    free(args);
}

+(void)openNewInstanceWithFile:(NSString*)filename
{
    [Misc openNewInstanceWithFiles:[NSArray arrayWithObject:filename]];
}

+(void)lionCompatForBaseLproj
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    NSString *osVersion = [pi operatingSystemVersionString];
    
    NSMutableString *cmd = [NSMutableString stringWithFormat:@"cd '%@/';",resourcePath];
    if(strnstr([osVersion UTF8String],"10.7",[osVersion lengthOfBytesUsingEncoding:NSUTF8StringEncoding])){
        //[cmd appendString:@"/bin/ln -sf ../Base.lproj/*.nib ."];
        [cmd appendString:@"for pj in *.lproj ; do test \"Base.lproj\" = \"$pj\" && continue; test \"base.lproj\" = \"$pj\" && continue; (cd $pj; /bin/ln -sf ../Base.lproj/*.nib . ); done"];
    }
    system([cmd UTF8String]);
}

@end
