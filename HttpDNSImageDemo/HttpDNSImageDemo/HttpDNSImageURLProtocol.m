//
//  HttpDNSImageURLProtocol.m
//  HttpDNSImageDemo
//
//  Created by liaoyp on 2016/9/27.
//  Copyright © 2016年 BT. All rights reserved.
//

#import "HttpDNSImageURLProtocol.h"
//#import <AlicloudHttpDNS/AlicloudHttpDNS.h>
#import "NetworkManager.h"

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";


@interface HttpDNSImageURLProtocol () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;


@end

@implementation HttpDNSImageURLProtocol

/*
 -URLProtocol:cachedResponseIsValid:
 -URLProtocol:didCancelAuthenticationChallenge:
 -URLProtocol:didFailWithError:
 -URLProtocol:didLoadData:
 -URLProtocol:didReceiveAuthenticationChallenge:
 -URLProtocol:didReceiveResponse:cacheStoragePolicy:
 -URLProtocol:wasRedirectedToRequest:redirectResponse:
 -URLProtocolDidFinishLoading:
 */


/*======================================================================
 Begin responsibilities for protocol implementors
 
 The methods between this set of begin-end markers must be
 implemented in order to create a working protocol.
 ======================================================================*/

/*!
 @method canInitWithRequest:
 @abstract This method determines whether this protocol can handle
 the given request.
 @discussion A concrete subclass should inspect the given request and
 determine whether or not the implementation can perform a load with
 that request. This is an abstract method. Sublasses must provide an
 implementation.
 @param request A request to inspect.
 @result YES if the protocol can handle the given request, NO if not.
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    
    //看看是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    // 监测当前是否有代理模式
    if ([NetworkManager configureProxies]) {
        return NO;
    }

    
    //拦截半糖链接，使用AliDNSHTTP 解析
    //bt.img.17gwx.com", @"pic1.bantangapp.com
    NSString *host = request.URL.host;
    if ([host isEqualToString:@"bt.img.17gwx.com"] || [host isEqualToString:@"pic1.bantangapp.com"]) {
        // 还需要测试是否需要添加这个链接。
        
        return YES;
        
    }
    
    return NO;
}



/*!
 @method canonicalRequestForRequest:
 @abstract This method returns a canonical version of the given
 request.
 @discussion It is up to each concrete protocol implementation to
 define what "canonical" means. However, a protocol should
 guarantee that the same input request always yields the same
 canonical form. Special consideration should be given when
 implementing this method since the canonical form of a request is
 used to look up objects in the URL cache, a process which performs
 equality checks between NSURLRequest objects.
 <p>
 This is an abstract method; sublasses must provide an
 implementation.
 @param request A request to make canonical.
 @result The canonical form of the given request.
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    mutableReqeust = [self redirectHostInRequset:mutableReqeust];
    return mutableReqeust;
}

/*!
 @method requestIsCacheEquivalent:toRequest:
 @abstract Compares two requests for equivalence with regard to caching.
 @discussion Requests are considered euqivalent for cache purposes
 if and only if they would be handled by the same protocol AND that
 protocol declares them equivalent after performing
 implementation-specific checks.
 @result YES if the two requests are cache-equivalent, NO otherwise.
 */
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

/*!
 @method startLoading
 @abstract Starts protocol-specific loading of a request.
 @discussion When this method is called, the protocol implementation
 should start loading a request.
 */
//- (void)startLoading;

/*!
 @method stopLoading
 @abstract Stops protocol-specific loading of a request.
 @discussion When this method is called, the protocol implementation
 should end the work of loading a request. This could be in response
 to a cancel operation, so protocol implementations must be able to
 handle this call while a load is in progress.
 */
//- (void)stopLoading;

#pragma mark -- private

+(NSMutableURLRequest*)redirectHostInRequset:(NSMutableURLRequest*)request
{
    NSMutableURLRequest *mutableReq = [request mutableCopy];
    NSString *originalUrl = mutableReq.URL.absoluteString;
    NSURL *url = [NSURL URLWithString:originalUrl];
    // 异步接口获取IP地址
    //NSString *ip = [[HttpDnsService sharedInstance] getIpByHostAsync:url.host];
    
    /*
    HttpDNSImageURLProtocol.m:164	New URL: http://220.194.215.98/topic/201609/22/50100101_617639_0.jpg/300x300
    HttpDNSImageURLProtocol.m:160	Get IP(220.194.215.98) for host(pic1.bantangapp.com) from HTTPDNS
    */
    
    NSString *ip = @"220.194.215.98";

    if (ip) {
        //ip = @"60.220.194.21077"; // 测试错误的Ip地址访问图片信息
        // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
        NSLog(@"Get IP(%@) for host(%@) from HTTPDNS Successfully!", ip, url.host);
        NSRange hostFirstRange = [originalUrl rangeOfString:url.host];
        if (NSNotFound != hostFirstRange.location) {
            NSString *newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:ip];
            NSLog(@"New URL: %@", newUrl);
            mutableReq.URL = [NSURL URLWithString:newUrl];
            [mutableReq setValue:url.host forHTTPHeaderField:@"host"];
            // 添加originalUrl保存原始URL
            [mutableReq addValue:originalUrl forHTTPHeaderField:@"originalUrl"];
        }
    }
    return [mutableReq copy];
}


/**
 *  开始加载，在该方法中，加载一个请求
 */
- (void)startLoading {
    NSMutableURLRequest *request = [self.request mutableCopy];
    // 表示该请求已经被处理，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:URLProtocolHandledKey inRequest:request];
    [self startRequest];
}
/**
 *  取消请求
 */
- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
}

/**
 *  使用NSURLSession转发请求
 */
- (void)startRequest {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    NSURLSessionTask *task = [_session dataTaskWithRequest:self.request];
    [task resume];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain {
    /*
     * 创建证书校验策略
     */
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateSSL(true, (__bridge CFStringRef) domain)];
    } else {
        [policies addObject:(__bridge_transfer id) SecPolicyCreateBasicX509()];
    }
    /*
     * 绑定校验策略到服务端的证书上
     */
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef) policies);
    /*
     * 评估当前serverTrust是否可信任，
     * 官方建议在result = kSecTrustResultUnspecified 或 kSecTrustResultProceed
     * 的情况下serverTrust可以被验证通过，https://developer.apple.com/library/ios/technotes/tn2232/_index.html
     * 关于SecTrustResultType的详细信息请参考SecTrust.h
     */
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

#pragma NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *_Nullable))completionHandler {
    if (!challenge) {
        return;
    }
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    /*
     * 获取原始域名信息。
     */
    NSString *host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = self.request.URL.host;
    }
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    // 对于其他的challenges直接使用默认的验证方案
    completionHandler(disposition, credential);
}

#pragma NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //NSLog(@"receive response: %@", response);
    // 获取原始URL
    NSString* originalUrl = [dataTask.currentRequest valueForHTTPHeaderField:@"originalUrl"];
    if (!originalUrl) {
        originalUrl = response.URL.absoluteString;
    }
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSURLResponse *retResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:originalUrl] statusCode:httpResponse.statusCode HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1 headerFields:httpResponse.allHeaderFields];
        [self.client URLProtocol:self didReceiveResponse:retResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    } else {
        NSURLResponse *retResponse = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:originalUrl] MIMEType:response.MIMEType expectedContentLength:response.expectedContentLength textEncodingName:response.textEncodingName];
        [self.client URLProtocol:self didReceiveResponse:retResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end
