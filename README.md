# SDWebImageAliHttpDNSDemo

自定义的HttpDNSImageURLProtocol 拦截sdwebimage的图片请求，配合HttpDNS动态解替换请求Host， 解决不同网络情况下图片域名被拦截的情况.

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

HttpDNSImageURLProtocol
    canInitWithRequest： 实现了HttpRequest host的监测开启是否对应的域名的预解析
    判断是否开启了代理模式，代理模式下不走HttpDNS解析
    
    canonicalRequestForRequest:
    设置解析URL替换请求中的host
    
    startLoading:
    实现连接的重复请求检测判断，NSURLSession开始自定义请求数据下载
    
