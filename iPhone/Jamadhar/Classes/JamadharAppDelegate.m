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
    messageLabel.text = @"Searching for service...";
    oscFinder = [[OscFinder alloc] init];
    messageTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateMessage:) userInfo:nil repeats:TRUE];
    [glView startAnimation];
    return YES;
}

- (void)updateMessage:(id)sender
{
    if (oscFinder.found)
    {
        messageLabel.text = [NSString
                             stringWithFormat:@"Connecting to service\n%@\n(%@:%d)",
                             oscFinder.serviceName,
                             oscFinder.address,
                             oscFinder.port];
    }
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
    [oscFinder dealloc];

    [super dealloc];
}

@end
