//
//  NetworkManager.m
//  httpdns_ios_demo
//
//  Created by ryan on 27/1/2016.
//  Copyright © 2016 alibaba. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager

+ (BOOL) configureProxies
{
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    
    NSArray *proxies = nil;
    
    NSURL *url = [[NSURL alloc] initWithString:@"http://api.m.taobao.com"];
    
    proxies = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)url,
                                                           (__bridge CFDictionaryRef)proxySettings));
    if (proxies > 0)
    {
        NSDictionary *settings = [proxies objectAtIndex:0];
        NSString *host = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
        NSString *port = [settings objectForKey:(NSString *)kCFProxyPortNumberKey];
        
        if (host || port)
        {
            return YES;
        }
    }
    return NO;
}

@end
