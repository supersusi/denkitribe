#import <Foundation/Foundation.h>

@interface OscFinder : NSObject <NSNetServiceBrowserDelegate,
                                 NSNetServiceDelegate>
{
@private
    NSNetServiceBrowser *netServiceBrowser;
    NSString *serviceName;
    NSString *address;
    NSInteger port;
    Boolean found;
}

@property (readonly, nonatomic) NSString *serviceName;
@property (readonly, nonatomic) NSString *address;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) Boolean found;

@end
