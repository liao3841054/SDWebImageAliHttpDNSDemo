//
//  NetworkManager.h
//  httpdns_ios_demo
//
//  Created by ryan on 27/1/2016.
//  Copyright © 2016 alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

/*
 * 判断当前网络状态下
 * 是否处理有Http/Https代理
 */
+ (BOOL) configureProxies;

@end

