//
//  TofinityAppDelegate.m
//  Tofinity
//
//  Created by 高橋 啓治郎 on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "TofinityAppDelegate.h"
#import "EAGLView.h"

@implementation TofinityAppDelegate

@synthesize window;
@synthesize glView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [glView startAnimation];
    return YES;
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
