//
//  JamadharAppDelegate.h
//  Jamadhar
//
//  Created by 高橋 啓治郎 on 10/07/02.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OscFinder.h"

@class EAGLView;

@interface JamadharAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
    UILabel *messageLabel;
    UIActivityIndicatorView *activityIndicatorView;
    NSTimer *messageTimer;
    OscFinder *oscFinder;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorView;

- (void)updateMessage:(id)sender;

@end

