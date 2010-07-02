//
//  JamadharAppDelegate.m
//  Jamadhar
//
//  Created by 高橋 啓治郎 on 10/07/02.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "JamadharAppDelegate.h"
#import "EAGLView.h"

@implementation JamadharAppDelegate

@synthesize window;
@synthesize glView;
@synthesize messageLabel;
@synthesize activityIndicatorView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    messageTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateMessage:) userInfo:nil repeats:TRUE];
    [glView startAnimation];
    return YES;
}

- (void)updateMessage:(id)sender
{
    static int i;
    if (i < 10) {
        messageLabel.text = [NSString
                             stringWithFormat:@"Waiting for server...\n%d",
                             i];
    } else if (i < 14) {
        [activityIndicatorView stopAnimating];
        messageLabel.text = @"Done!!";
    } else {
        messageLabel.hidden = YES;
    }
    i++;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)dealloc
{
    [window release];
    [glView release];

    [super dealloc];
}

@end
