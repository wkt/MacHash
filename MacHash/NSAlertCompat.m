//
//  NSAlertCompat.m
//  MacHash
//
//  Created by WeiKeting on 15-2-28.
//  Copyright (c) 2015年 weiketing.com. All rights reserved.
//

#import "NSAlertCompat.h"

@interface NSAlert (BEPrivateMethods)

-(IBAction) BE_stopSynchronousSheet:(id)sender;   // hide sheet & stop modal
-(void) BE_beginSheetModalForWindow:(NSWindow *)aWindow;
@end

@implementation NSAlertCompat

+ (void)alertToSheet:(NSAlert*)alert beginSheetModalForWindow:(NSWindow *)sheetWindow
               completionHandler:(void (^)(NSModalResponse returnCode))handler
{
    @try{
        SEL aSelector = NSSelectorFromString(@"beginSheetModalForWindow:completionHandler:");
        if([alert methodForSelector:aSelector]){
            [alert performSelector:aSelector withObject:sheetWindow withObject:handler];
        }else{
            [NSException raise:@"Error" format:@"No method beginSheetModalForWindow:completionHandler: for %@ ",[alert className]];
        }
    }@catch ( NSException *e )
    {
        NSAlertCompat *compat = [[NSAlertCompat alloc] init];
        [alert beginSheetModalForWindow:sheetWindow modalDelegate:compat didEndSelector:@selector(alertEnded:code:context:) contextInfo:(__bridge void *)(handler)];
    }
}

-(void)alertEnded:(NSAlert*)alert code:(NSInteger)choice context:(void*)v
{
    void (^handler)(NSModalResponse returnCode) = (__bridge void (^)(NSModalResponse))(v);
    handler(choice);
}

+(NSModalResponse)runAlertSheetModal:(NSAlert*)alert sheetWindow:(NSWindow *)window
{
    NSAlertCompat *compat = [[NSAlertCompat alloc] init];
    [compat performSelector:@selector(setPrivateAlert:) withObject:alert];
    return [compat runModalSheetForWindow:window];
}


-(NSInteger) runModalSheetForWindow:(NSWindow *)aWindow {
	// Set ourselves as the target for button clicks
    NSAlert *aAlert =[self performSelector:@selector(privateAlert)];// [self valueForKey:@"privateAlert"];
    
	for (NSButton *button in [aAlert buttons]) {
		[button setTarget:self];
		[button setAction:@selector(BE_stopSynchronousSheet:)];
	}
	
	// Bring up the sheet and wait until stopSynchronousSheet is triggered by a button click
	[self performSelectorOnMainThread:@selector(BE_beginSheetModalForWindow:) withObject:aWindow waitUntilDone:YES];
	NSInteger modalCode = [NSApp runModalForWindow:[aAlert window]];
	
	// This is called only after stopSynchronousSheet is called (that is,
	// one of the buttons is clicked)
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:[aAlert window] waitUntilDone:YES];
	
	// Remove the sheet from the screen
	[[aAlert window] performSelectorOnMainThread:@selector(orderOut:) withObject:self waitUntilDone:YES];
	
	return modalCode;
}

-(NSInteger) runModalSheet {
	return [self runModalSheetForWindow:[NSApp mainWindow]];
}

#pragma mark Private methods

-(IBAction) BE_stopSynchronousSheet:(id)sender {
	// See which of the buttons was clicked
    NSAlert *aAlert = [self performSelector:@selector(privateAlert)];
	NSUInteger clickedButtonIndex = [[aAlert buttons] indexOfObject:sender];
	
	// Be consistent with Apple's documentation (see NSAlert's addButtonWithTitle) so that
	// the fourth button is numbered NSAlertThirdButtonReturn + 1, and so on
	//
	// TODO: handle case when alert created with alertWithMessageText:... where the buttons
	//       have values NSAlertDefaultReturn, NSAlertAlternateReturn, ... instead (see also
	//       the documentation for the runModal method)
	NSInteger modalCode = 0;
	if (clickedButtonIndex == NSAlertFirstButtonReturn)
		modalCode = NSAlertFirstButtonReturn;
	else if (clickedButtonIndex == NSAlertSecondButtonReturn)
		modalCode = NSAlertSecondButtonReturn;
	else if (clickedButtonIndex == NSAlertThirdButtonReturn)
		modalCode = NSAlertThirdButtonReturn;
	else
		modalCode = NSAlertThirdButtonReturn + (clickedButtonIndex - 2);
	[NSApp stopModalWithCode:modalCode];
}

-(void) BE_beginSheetModalForWindow:(NSWindow *)aWindow {
    NSAlert *aAlert =[self performSelector:@selector(privateAlert)];
	[aAlert beginSheetModalForWindow:aWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

@end
