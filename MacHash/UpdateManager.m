//
//  UpdateManager.m
//  MacHash
//
//  Created by WeiKeting on 15-3-6.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "UpdateManager.h"
#import "NSAlertCompat.h"
#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static const NSInteger UPDATE_LEVEL_DEBUG = -1;

@implementation UpdateLogViewController

-(id)init
{
    self = [super initWithNibName:@"UpdateLogView" bundle:Nil];
    return self;
}

@end


@interface UpdateCheckingViewController:NSViewController
@property (unsafe_unretained) IBOutlet NSTextField *textView;

@end



@interface UpdateInfoObject : NSObject <UpdateInfo>
{
@private
    id _JSON;
}


-(id)initWithData:(NSData *)data;


@end

@implementation UpdateInfoObject

-(id)initWithData:(NSData *)data
{
    self = [super init];
    NSError *err = Nil;
    _JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    
    return self;
}

-(NSUInteger) versionCode
{
    return [[_JSON valueForKey:@"versionCode"] integerValue];
}

-(NSString *)versionName
{
    NSString *ret = [_JSON valueForKey:@"versionName"];
    if(ret == Nil)ret = [_JSON valueForKey:@"version"];
    return ret;
}

-(NSString *)downloadURL
{
    NSString *ret = [_JSON valueForKey:@"downloadURL"];
    if(ret == Nil)ret = [_JSON valueForKey:@"url"];
    return ret;
}

-(NSString *)browseURL
{
    NSString *ret = [_JSON valueForKey:@"browseURL"];
    if(ret == Nil){
        ret = [self downloadURL];
    }
    return ret;
}

-(NSString *)updateLog
{
    return [_JSON valueForKey:@"updateLog"];
}

-(NSInteger) updateLevel
{
    return [[_JSON valueForKey:@"updateLevel"] integerValue];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"{version:%@,versionCode:%lu,url:%@,updateLog:%@,updateLevel:%lu}",
            [self versionName],[self versionCode],[self downloadURL],[self updateLog],
            [self updateLevel]
            ];
}

@end


@implementation UpdateManager

@synthesize receivedData;


- (NSString *) getSysInfoByName:(char *)typeSpecifier

{
    
    size_t size;
    
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    
    return results;
    
}

-(id)initWithUpdateInfoHandler:(void (^)(id<UpdateInfo> info))updateInfoHandler
{
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL:[NSURL URLWithString:
                                                     @"http://machash.weiketing.com/check4update.do"
                                                     ]
                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:60.0];
    NSBundle* bundle = [NSBundle mainBundle];
    NSDictionary *osInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];

    NSString *osName=[osInfo valueForKey:@"ProductName"];
    NSString *osVersion=[osInfo valueForKey:@"ProductUserVisibleVersion"];
    NSString *osBuild = [osInfo valueForKey:@"ProductBuildVersion"];

    NSString *versionName=[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *versionCode = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];;
    NSMutableString *userAgent = [NSMutableString stringWithFormat:
                                  @"%@/%@(%@); %@/%@(%@)",
                                  [[[NSProcessInfo processInfo] processName] stringByReplacingOccurrencesOfString:@" " withString:@""],
                                  versionName,
                                  versionCode,
                                  osName,osVersion,
                                  osBuild
                                ];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
    [dict setObject:versionName forKey:@"versionName"];
    [dict setValue:versionCode forKey:@"versionCode"];
    [dict setObject:[bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"softId"];

    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:Nil]];

    [theRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [theRequest setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    receivedData = [NSMutableData dataWithCapacity:0];
    self =[super initWithRequest:theRequest delegate:self];
    if(!self){
        receivedData = Nil;
    }
    __updateInfoHandler=updateInfoHandler;
    
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    receivedData = nil;
        if(__updateInfoHandler)__updateInfoHandler(NULL);

    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UpdateInfoObject *info=[[UpdateInfoObject alloc]initWithData:self.receivedData];
    if(info.versionName==NULL && info.versionCode>0)
    {
        info = Nil;
    }
    
#if defined(DEBUG) && DEBUG
    NSLog(@"receivedData:%s",[self.receivedData bytes]);
#endif
    
    if(__updateInfoHandler)__updateInfoHandler(info);
    receivedData = nil;
}

+(void)setLastUpdateChecked
{
    NSString *toDay = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:Nil locale:Nil];
    [[NSUserDefaults standardUserDefaults] setObject:toDay forKey:@"lastUpateChecked"];
}

+(void)setSkipVersionCode:(NSInteger)versionCode
{
    [[NSUserDefaults standardUserDefaults] setInteger:versionCode forKey:@"skipThisVersionCode"];
}

+(NSInteger)skipVersionCode
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"skipThisVersionCode"];
}


//启动时的例行检查一天最多一次
+(BOOL)shouldCheckForUpdate
{
    NSString *toDay = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:Nil locale:Nil];
    NSString *oldDay = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpateChecked"];
    if([toDay isEqualToString:oldDay]){
        return NO;
    }
    return YES;
}

+(void)checkForUpdateWithHandler:(void (^)(id<UpdateInfo> info))updateInfoHandler
{
    if(updateInfoHandler == Nil)return;
    [[[UpdateManager alloc] initWithUpdateInfoHandler:updateInfoHandler] start];
}

+(void)checkForUpdateWithWindow:(NSWindow*)window isLaunching:(BOOL)isLaunchingCheck
{
    if([UpdateManager shouldCheckForUpdate] || !isLaunchingCheck ){

        [UpdateManager checkForUpdateWithHandler:^(id<UpdateInfo>info){
            NSUInteger versionCode = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue];
            NSString *message = Nil;
            NSString *informative = Nil;
            NSString *defaultString = Nil;
            NSString *alternateButton = Nil;
            NSString *otherButton = Nil;
            NSBundle *bundle = [NSBundle mainBundle];
            
#if defined (DEBUG) && DEBUG
            NSLog(@"info:%@",info);
#endif

            if([info updateLevel] < 0)return;
            
            if([UpdateManager skipVersionCode] == [info versionCode])return;

            if(info == Nil || [info versionCode] <= versionCode){
                if(!isLaunchingCheck){
                    
                    message = [NSString  stringWithFormat:
                                NSLocalizedString(@"%@ is up to date.", @""),
                               [bundle objectForInfoDictionaryKey:@"CFBundleName"]
                               ];
                    ;
                    informative =  NSLocalizedString(@"Version %@",Nil);
                    NSAlert *alert = [NSAlert alertWithMessageText:message
                                                   defaultButton:defaultString
                                                 alternateButton:alternateButton
                                                     otherButton:otherButton
                                       informativeTextWithFormat:informative,
                                      [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                      Nil];
                    [NSAlertCompat
                     runAlertSheetModal:alert
                     sheetWindow:window?window:[NSApp mainWindow]];
                }
                return;
            }else{
                message = [NSString stringWithFormat:NSLocalizedString(@"A new version is available",@"")];
                alternateButton = Nil;
                defaultString = NSLocalizedString(@"Download Now",@"");
                otherButton = NSLocalizedString(@"Reminer Me Later",@"");
                
                informative =  [NSString stringWithFormat:NSLocalizedString(@"%@ %@ is available--You have %@. Would you like to download it now?",@""),
                                [bundle objectForInfoDictionaryKey:@"CFBundleName"],
                                [info versionName],
                                [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

            }
            
             NSAlert *alert = [NSAlert alertWithMessageText:message
                                             defaultButton:defaultString
                                           alternateButton:alternateButton
                                               otherButton:otherButton
                                 informativeTextWithFormat:informative,Nil];
            UpdateLogViewController *viewContrl = Nil;
            if([info updateLog])
            {
                viewContrl = [[UpdateLogViewController alloc] init];
                [alert setAccessoryView:[viewContrl view]];
                [viewContrl.textView setString:[info updateLog]];
                
            }
            [[alert window] setTitle:NSLocalizedString(@"Software Update",@"")];

            [NSApp requestUserAttention:NSCriticalRequest];
            NSInteger ret = [NSAlertCompat
                             runAlertSheetModal:alert
                             sheetWindow:window?window:[NSApp mainWindow]];
            
            [UpdateManager setLastUpdateChecked];

            if (NSAlertFirstButtonReturn == ret)
            {
                //upgrade now
                if([info versionCode] > versionCode){
                    system([[NSString stringWithFormat:@"open \"%@\"",[info browseURL]] UTF8String]);
                }
            }else if(NSAlertThirdButtonReturn == ret){
                //skip this version
                [UpdateManager setSkipVersionCode:[info versionCode]];
            }else if(NSAlertSecondButtonReturn == ret){
                //remind me later
                
            }
        }];
    }
    
}

@end
