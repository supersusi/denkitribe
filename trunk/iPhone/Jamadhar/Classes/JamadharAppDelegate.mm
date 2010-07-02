#import "JamadharAppDelegate.h"
#import "EAGLView.h"
#import "OscClient.h"

@implementation JamadharAppDelegate

@synthesize window;
@synthesize glView;
@synthesize messageLabel;
@synthesize activityIndicatorView;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    messageLabel.text = @"Searching for service...";
    oscServiceFinder = [[OscServiceFinder alloc] init];
    clientInit = NO;
    messageTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateMessage:) userInfo:nil repeats:TRUE];
    messageDelay = 0;
    [glView startAnimation];
    return YES;
}

- (void)updateMessage:(id)sender
{
    if (oscServiceFinder.found && !clientInit)
    {
        Jamadhar::OscClient::Initialize([oscServiceFinder.address UTF8String], oscServiceFinder.port);
        clientInit = YES;
        messageLabel.text = [NSString
                             stringWithFormat:@"Connected to\n%@\n(%@:%d)",
                             oscServiceFinder.serviceName,
                             oscServiceFinder.address,
                             oscServiceFinder.port];
        messageDelay = 12;
        [activityIndicatorView stopAnimating];
    }
    
    if (messageDelay > 0)
    {
        if (--messageDelay == 0)
        {
            messageLabel.hidden = YES;
        }
    }
    
    if (clientInit)
    {
        Jamadhar::OscClient::SendBang();
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
    if (!clientInit) Jamadhar::OscClient::Terminate();
    [window release];
    [glView release];
    [oscServiceFinder dealloc];

    [super dealloc];
}

@end
