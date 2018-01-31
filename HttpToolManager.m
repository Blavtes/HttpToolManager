//
//  HttpToolManager.m
//  HTMNetManager
//
//  Created by Blavtes on 2018/1/31.
//  Copyright © 2018年 boai. All rights reserved.
//

#import "HttpToolManager.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import "GjFaxCgiErrorCollection.h"

/*! 系统相册 */
#import <Photos/Photos.h>
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "UIImage+CompressImage.h"
#import "HttpToolManagerCache.h"

#import "HttpToolDataEntity.h"


static NSMutableArray *tasks;

//static void *isNeedCacheKey = @"isNeedCacheKey";

@interface HttpToolManager ()

@property(nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation HttpToolManager

+ (instancetype)sharedHTMNetManager
{
    /*! 为单例对象创建的静态实例，置为nil，因为对象的唯一性，必须是static类型 */
    static id sharedHTMNetManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHTMNetManager = [[super allocWithZone:NULL] init];
    });
    return sharedHTMNetManager;
}

+ (void)initialize
{
    [self setupHTMNetManager];
}

+ (void)setupHTMNetManager
{
    HTMNetManagerShare.sessionManager =  [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:GJS_HOST_NAME]];
    
    //    HTMNetManagerShare.requestSerializer = BAHttpRequestSerializerJSON;
    //    HTMNetManagerShare.responseSerializer = HTMHttpResponseSerializerJSON;
    
    /*! 设置请求超时时间，默认：30秒 */
    HTMNetManagerShare.timeoutInterval = 30;
    /*! 打开状态栏的等待菊花 */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    /*! 设置返回数据类型为 json, 分别设置请求以及相应的序列化器 */
    /*!
     根据服务器的设定不同还可以设置：
     json：[AFJSONResponseSerializer serializer](常用)
     http：[AFHTTPResponseSerializer serializer]
     */
    //    AFJSONResponseSerializer *response = [AFJSONResponseSerializer serializer];
    //    /*! 这里是去掉了键值对里空对象的键值 */
    ////    response.removesKeysWithNullValues = YES;
    //    HTMNetManagerShare.sessionManager.responseSerializer = response;
    
    /* 设置请求服务器数类型式为 json */
    /*!
     根据服务器的设定不同还可以设置：
     json：[AFJSONRequestSerializer serializer](常用)
     http：[AFHTTPRequestSerializer serializer]
     */
    //    AFJSONRequestSerializer *request = [AFJSONRequestSerializer serializer];
    //    HTMNetManagerShare.sessionManager.requestSerializer = request;
    /*! 设置apikey ------类似于自己应用中的tokken---此处仅仅作为测试使用*/
    //        [manager.requestSerializer setValue:apikey forHTTPHeaderField:@"apikey"];
    
    /*! 复杂的参数类型 需要使用json传值-设置请求内容的类型*/
    //        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    /*! 设置响应数据的基本类型 */
    //    HTMNetManagerShare.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/css", @"text/xml", @"text/plain", @"application/javascript", @"application/x-www-form-urlencoded", @"image/*", nil];
    //    HTMNetManagerShare.sessionManager.requestSerializer.timeoutInterval = kCommonNetworkingTimeout;
    //  设置返回格式
    HTMNetManagerShare.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", nil];
    //  设置请求格式
    [HTMNetManagerShare.sessionManager.requestSerializer setValue:@"zh-CN,en;" forHTTPHeaderField:@"Accept-Language"];
    HTMNetManagerShare.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    //        self.manager.requestSerializer.timeoutInterval = kCommonNetworkingTimeout;
    HTMNetManagerShare.sessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 状态消失的延时，默认为0.17秒。当调用不同接口时，关闭动画效果
    [AFNetworkActivityIndicatorManager sharedManager].completionDelay = 0.0;
    // 状态开启延时，默认为1s，当接口小于1s内返回结果，没必要开启效果
    [AFNetworkActivityIndicatorManager sharedManager].activationDelay = 0.0;
    // 配置自建证书的Https请求
    //    [self htm_setupSecurityPolicy];
}

/**
 配置自建证书的Https请求，只需要将CA证书文件放入根目录就行
 */
+ (void)htm_setupSecurityPolicy
{
    //    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
    
    if (cerSet.count == 0)
    {
        /*!
         采用默认的defaultPolicy就可以了. AFN默认的securityPolicy就是它, 不必另写代码. AFSecurityPolicy类中会调用苹果security.framework的机制去自行验证本次请求服务端放回的证书是否是经过正规签名.
         */
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        HTMNetManagerShare.sessionManager.securityPolicy = securityPolicy;
    }
    else
    {
        /*! 自定义的CA证书配置如下： */
        /*! 自定义security policy, 先前确保你的自定义CA证书已放入工程Bundle */
        /*!
         https://api.github.com网址的证书实际上是正规CADigiCert签发的, 这里把Charles的CA根证书导入系统并设为信任后, 把Charles设为该网址的SSL Proxy (相当于"中间人"), 这样通过代理访问服务器返回将是由Charles伪CA签发的证书.
         */
        // 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        // 如果需要验证自建证书(无效证书)，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        // 是否需要验证域名，默认为YES
        //    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
        
        HTMNetManagerShare.sessionManager.securityPolicy = securityPolicy;
        
        
        /*! 如果服务端使用的是正规CA签发的证书, 那么以下几行就可去掉: */
        //            NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        //            AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        //            policy.allowInvalidCertificates = YES;
        //            HTMNetManagerShare.sessionManager.securityPolicy = policy;
    }
}

#pragma mark - 网络请求的类方法 --- get / post / put / delete
/*!
 *  网络请求的实例方法
 *
 *  @param type         get / post / put / delete
 *  @param isNeedCache  是否需要缓存，只有 get / post 请求有缓存配置
 *  @param urlString    请求的地址
 *  @param parameters    请求的参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 *  @param progressBlock 进度
 */
+ (HTMURLSessionTask *)htm_requestWithType:(HTMHttpRequestType)type
                             isNeedCache:(BOOL)isNeedCache
                               urlString:(NSString *)urlString
                              parameters:(id)parameters
                            successBlock:(HTMResponseSuccessBlock)successBlock
                            failureBlock:(HTMResponseFailBlock)failureBlock
                           progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (urlString == nil)
    {
        return nil;
    }
    
    HTMWeak;
    /*! 检查地址中是否有中文 */
    CFTimeInterval time = CFAbsoluteTimeGetCurrent();
    
    NSString *URLString = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];
    
    NSString *requestType;
    switch (type) {
        case 0:
            requestType = @"GET";
            break;
        case 1:
            requestType = @"POST";
            break;
        case 2:
            requestType = @"PUT";
            break;
        case 3:
            requestType = @"DELETE";
            break;
            
        default:
            break;
    }
    
    AFHTTPSessionManager *scc = HTMNetManagerShare.sessionManager;
    AFHTTPResponseSerializer *scc2 = scc.responseSerializer;
    AFHTTPRequestSerializer *scc3 = scc.requestSerializer;
    NSTimeInterval timeoutInterval = HTMNetManagerShare.timeoutInterval;
    
    NSString *isCache = isNeedCache ? @"开启":@"关闭";
    CGFloat allCacheSize = [HttpToolManagerCache htm_getAllHttpCacheSize];
    
    DLog(@"******************** 请求参数 ***************************");
    
    DLog(@"\n请求头: %@\n超时时间设置：%.1f 秒【默认：30秒】\nAFHTTPResponseSerializer：%@【默认：AFJSONResponseSerializer】\nAFHTTPRequestSerializer：%@【默认：AFJSONRequestSerializer】\n请求方式: %@\n请求URL: %@\n请求param: %@\n是否启用缓存：%@【默认：开启】\n目前总缓存大小：%.6fM\n", HTMNetManagerShare.sessionManager.requestSerializer.HTTPRequestHeaders, timeoutInterval, scc2, scc3, requestType, URLString, parameters, isCache, allCacheSize);
    DLog(@"********************************************************");
    
    HTMURLSessionTask *sessionTask = nil;
    
    // 读取缓存
    id responseCacheData = [HttpToolManagerCache htm_httpCacheWithUrlString:urlString parameters:parameters];
    
    if (isNeedCache && responseCacheData != nil)
    {
        if (successBlock)
        {
            successBlock(responseCacheData);
        }
        DLog(@"取用缓存数据结果： *** %@", responseCacheData);
        
        [[weakSelf tasks] removeObject:sessionTask];
        return nil;
    }
    
    if (type == HTMHttpRequestTypeGet)
    {
        sessionTask = [HTMNetManagerShare.sessionManager GET:URLString parameters:parameters  progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (successBlock)
            {
                successBlock(responseObject);
            }
            // 对数据进行异步缓存
            [HttpToolManagerCache htm_setHttpCache:responseObject urlString:urlString parameters:parameters];
            [[weakSelf tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock)
            {
                failureBlock(error);
            }
            [[weakSelf tasks] removeObject:sessionTask];
            
        }];
    }
    else if (type == HTMHttpRequestTypePost)
    {
        AFHTTPSessionManager *manager = HTMNetManagerShare.sessionManager;
        NSDictionary *reqDic = [self postAFHTTPSessionManager:manager parameters:parameters];
       
        sessionTask = [manager POST:URLString parameters:reqDic progress:^(NSProgress * _Nonnull uploadProgress) {
            DLog(@"上传进度--%lld, 总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
            
            /*! 回到主线程刷新UI */
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock)
                {
                    progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                }
            });
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            DLog(@"post 请求数据结果： *** %@", responseObject);
            if ([GJS_GetMyAccountInfo_Api isEqualToString:urlString]) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
            }
            DLog(@"url ->%@ ### time-> %f",urlString,CFAbsoluteTimeGetCurrent() - time);
            if (responseObject == nil || [responseObject isNilObj]) {
                successBlock([self fetchNetworkErrorResponseJSON:kInterfaceRetStatusFail withCode:kNetworkSystemError withInfo:kInterfaceRetDataErrorStr]);
                
                //                DLog(@"%@ -> 返回数据格式错误[数据为空]", strUrl);
                
#pragma mark - -  接口错误采集
                //  接口错误采集
                [[GjFaxCgiErrorCollection manager] collectCgiErrorWithCgiName:urlString andCode:kNetworkSystemError andInfo:FMT_STR(@"[返回数据为空]%@", kInterfaceRetDataErrorStr)];
                
            } else {
                //  非空
                NSDictionary *retDic = [HttpParamsSetting dicFromServerRet:responseObject];
                
                if (retDic) {
                    [BuglyTool reportGetDataNoSuccessResponse:retDic url:urlString params:reqDic];
                    successBlock(retDic);
                    
                } else if (![[responseObject objectForKeyForSafetyValue:@"note"] isNilObj] &&
                           ![[responseObject objectForKeyForSafetyValue:@"resultCode"] isNilObj] &&
                           ![[responseObject objectForKeyForSafetyValue:@"success"] isNilObj]) {
#pragma mark - 格式完全符合老版本的情形
                    NSString *retStatus = [responseObject objectForKeyForSafetyValue:@"success"];
                    NSString *retCode = [responseObject objectForKeyForSafetyValue:@"resultCode"];
                    NSString *retInfo = [responseObject objectForKeyForSafetyValue:@"note"];
                    successBlock([self fetchNetworkErrorResponseJSON:retStatus withCode:retCode withInfo:kInterfaceRetDataErrorStr]);
                    
                    //                    DLog(@"%@ -> 返回数据格式错误[老版本格式]", strUrl);
                    
#pragma mark - - 接口错误采集
                    //  接口错误采集
                    [[GjFaxCgiErrorCollection manager] collectCgiErrorWithCgiName:urlString andCode:retCode andInfo:FMT_STR(@"[老版本格式]%@", retInfo)];
                } else {
                    successBlock([self fetchNetworkErrorResponseJSON]);
                    
                    //                    DLog(@"%@ -> 返回数据格式错误[有返回数据、解析数据为空]", strUrl);
#pragma mark - - 接口错误采集
                    //  接口错误采集
                    [[GjFaxCgiErrorCollection manager] collectCgiErrorWithCgiName:urlString andCode:kNetworkSystemError andInfo:FMT_STR(@"[有返回数据、解析数据为空]%@", kInterfaceRetDataErrorStr)];
                }
            }
            // 对数据进行异步缓存
            [HttpToolManagerCache htm_setHttpCache:responseObject urlString:urlString parameters:parameters];
            [[weakSelf tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            DLog(@"错误信息：%@",error);
            
            if (failureBlock)
            {
                failureBlock(error);
            }
            [[weakSelf tasks] removeObject:sessionTask];
            
        }];
    }
    else if (type == HTMHttpRequestTypePut)
    {
        sessionTask = [HTMNetManagerShare.sessionManager PUT:URLString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (successBlock)
            {
                successBlock(responseObject);
            }
            
            [[weakSelf tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock)
            {
                failureBlock(error);
            }
            [[weakSelf tasks] removeObject:sessionTask];
            
        }];
    }
    else if (type == HTMHttpRequestTypeDelete)
    {
        sessionTask = [HTMNetManagerShare.sessionManager DELETE:URLString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (successBlock)
            {
                successBlock(responseObject);
            }
            
            [[weakSelf tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock)
            {
                failureBlock(error);
            }
            [[weakSelf tasks] removeObject:sessionTask];
            
        }];
    }
    
    if (sessionTask)
    {
        [[weakSelf tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

+ (NSDictionary *)postAFHTTPSessionManager:(AFHTTPSessionManager *)manager parameters:(NSDictionary *)parameters
{
    NSDictionary *reqDic = [HttpParamsSetting dicParamsSetting:(NSMutableDictionary *)parameters];
    NSString *signStr = [HttpParamsSetting md5StrWithDic:reqDic];
    [manager.requestSerializer setValue:signStr forHTTPHeaderField:@"sign"];
    [manager.requestSerializer  setValue:[CommonMethod UUIDWithKeyChain] forHTTPHeaderField:@"uuid"];
    
    NSDictionary *cookiePropertiesDic = @{@"sign": signStr};
    [cookiePropertiesDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //  设定 cookie
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                             [manager.baseURL host], NSHTTPCookieDomain,
                             [manager.baseURL path], NSHTTPCookiePath,
                             key, NSHTTPCookieName,
                             obj, NSHTTPCookieValue,
                             nil];
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:dic];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        
    }];
    return reqDic;
}

+ (NSDictionary *)fetchNetworkErrorResponseJSON
{
    NSMutableDictionary *retErrorJSONDic = [[NSMutableDictionary alloc] initWithDictionary:[self fetchNetworkErrorResponseJSON:kInterfaceRetStatusFail withCode:kNetworkSystemError withInfo:kInterfaceRetNoteNetworkErrorStr]];
    
    return retErrorJSONDic;
}

+ (NSDictionary *)fetchNetworkErrorResponseJSON:(NSString *)retStatus
                                       withCode:(NSString *)retCode
                                       withInfo:(NSString *)retInfo
{
    NSMutableDictionary *retErrorJSONDic = [[NSMutableDictionary alloc] init];
    
    //  result
    [retErrorJSONDic setObjectJudgeNil:@"" forKey:@"result"];
    
#pragma mrak - retStatus/code/note 为空时，给予一个默认值
    if (retStatus == nil || [retStatus isNilObj]) {
        retStatus = kInterfaceRetStatusFail;
    }
    
    if (retCode == nil || [retCode isNilObj]) {
        retCode = kNetworkSystemError;
    }
    
    if (retInfo == nil || [retCode isNilObj]) {
        retInfo = kInterfaceRetDataErrorStr;
    }
    
    //  retInfo
    NSMutableDictionary *interfaceInfoDic = [[NSMutableDictionary alloc] init];
    [interfaceInfoDic setObjectJudgeNil:retStatus forKey:@"status"];
    [interfaceInfoDic setObjectJudgeNil:retCode forKey:@"retCode"];
    [interfaceInfoDic setObjectJudgeNil:retInfo forKey:@"note"];
    
    [retErrorJSONDic setObjectJudgeNil:interfaceInfoDic forKey:@"retInfo"];
    
    return retErrorJSONDic;
}

#pragma mark - 网络请求的类方法 + Entity --- get / post / put / delete

/**
 网络请求的实例方法 get
 
 @param entity 请求信息载体
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 @param progressBlock 进度回调
 @return HTMURLSessionTask
 */
+ (HTMURLSessionTask *)htm_request_GETWithEntity:(HttpToolDataEntity *)entity
                                  successBlock:(HTMResponseSuccessBlock)successBlock
                                  failureBlock:(HTMResponseFailBlock)failureBlock
                                 progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (!entity || ![entity isKindOfClass:[HttpToolDataEntity class]]) {
        return nil;
    }
    return [self htm_requestWithType:HTMHttpRequestTypeGet isNeedCache:entity.isNeedCache urlString:entity.urlString
                         parameters:entity.parameters successBlock:successBlock failureBlock:failureBlock progressBlock:progressBlock];
}

/**
 网络请求的实例方法 post
 
 @param entity 请求信息载体
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 @param progressBlock 进度
 @return HTMURLSessionTask
 */
+ (HTMURLSessionTask *)htm_request_POSTWithEntity:(HttpToolDataEntity *)entity
                                   successBlock:(HTMResponseSuccessBlock)successBlock
                                   failureBlock:(HTMResponseFailBlock)failureBlock
                                  progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (!entity || ![entity isKindOfClass:[HttpToolDataEntity class]]) {
        return nil;
    }
    return [self htm_requestWithType:HTMHttpRequestTypePost isNeedCache:entity.isNeedCache urlString:entity.urlString parameters:entity.parameters successBlock:successBlock failureBlock:failureBlock progressBlock:progressBlock];
}

/**
 网络请求的实例方法 put
 
 @param entity 请求信息载体
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 @param progressBlock 进度
 @return HTMURLSessionTask
 */
+ (HTMURLSessionTask *)htm_request_PUTWithEntity:(HttpToolDataEntity *)entity
                                  successBlock:(HTMResponseSuccessBlock)successBlock
                                  failureBlock:(HTMResponseFailBlock)failureBlock
                                 progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (!entity || ![entity isKindOfClass:[HttpToolDataEntity class]]) {
        return nil;
    }
    return [self htm_requestWithType:HTMHttpRequestTypePut isNeedCache:NO urlString:entity.urlString parameters:entity.parameters successBlock:successBlock failureBlock:failureBlock progressBlock:progressBlock];
}

/**
 网络请求的实例方法 delete
 
 @param entity 请求信息载体
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 @param progressBlock 进度
 @return HTMURLSessionTask
 */
+ (HTMURLSessionTask *)htm_request_DELETEWithEntity:(HttpToolDataEntity *)entity
                                     successBlock:(HTMResponseSuccessBlock)successBlock
                                     failureBlock:(HTMResponseFailBlock)failureBlock
                                    progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (!entity || ![entity isKindOfClass:[HttpToolDataEntity class]]) {
        return nil;
    }
    return [self htm_requestWithType:HTMHttpRequestTypeDelete isNeedCache:NO urlString:entity.urlString parameters:entity.parameters successBlock:successBlock failureBlock:failureBlock progressBlock:progressBlock];
}

/**
 上传图片(多图)
 
 @param entity 请求信息载体
 @param successBlock 上传成功的回调
 @param failureBlock 上传失败的回调
 @param progressBlock 上传进度
 @return HTMURLSessionTask
 */
+ (HTMURLSessionTask *)htm_uploadImageWithEntity:(HttpToolDataEntity *)entity
                                  successBlock:(HTMResponseSuccessBlock)successBlock
                                   failurBlock:(HTMResponseFailBlock)failureBlock
                                 progressBlock:(HTMUploadProgressBlock)progressBlock
{
    if (!entity || entity.urlString == nil || ![entity isKindOfClass:[HttpToolImageDataEntity class]]) {
        return nil;
    }
    
    HttpToolImageDataEntity *imageEntity = (HttpToolImageDataEntity *)entity;
    
    HTMWeak;
    /*! 检查地址中是否有中文 */
    NSString *URLString = [NSURL URLWithString:imageEntity.urlString] ? imageEntity.urlString : [self strUTF8Encoding:imageEntity.urlString];
    
    DLog(@"******************** 请求参数 ***************************");
    DLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",HTMNetManagerShare.sessionManager.requestSerializer.HTTPRequestHeaders, @"POST",URLString, imageEntity.parameters);
    DLog(@"********************************************************");
    
    HTMURLSessionTask *sessionTask = nil;
    sessionTask = [HTMNetManagerShare.sessionManager POST:URLString parameters:imageEntity.parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        /*! 出于性能考虑,将上传图片进行压缩 */
        [imageEntity.imageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            /*! image的压缩方法 */
            UIImage *resizedImage;
            /*! 此处是使用原生系统相册 */
            if ([obj isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)obj;
                PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
                [imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth , asset.pixelHeight) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    
                    DLog(@" width:%f height:%f",result.size.width,result.size.height);
                    
                    [self htm_uploadImageWithFormData:formData resizedImage:result imageType:imageEntity.imageType imageScale:imageEntity.imageScale fileNames:imageEntity.fileNames index:idx];
                }];
            } else {
                /*! 此处是使用其他第三方相册，可以自由定制压缩方法 */
                resizedImage = obj;
                [self htm_uploadImageWithFormData:formData resizedImage:resizedImage imageType:imageEntity.imageType imageScale:imageEntity.imageScale fileNames:imageEntity.fileNames index:idx];
            }
        }];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        DLog(@"上传进度--%lld, 总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        /*! 回到主线程刷新UI */
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock) {
                progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DLog(@"上传图片成功 = %@",responseObject);
        if (successBlock) {
            successBlock(responseObject);
        }
        
        [[weakSelf tasks] removeObject:sessionTask];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failureBlock) {
            failureBlock(error);
        }
        [[weakSelf tasks] removeObject:sessionTask];
    }];
    
    if (sessionTask) {
        [[self tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

/**
 视频上传
 
 @param entity 请求信息载体
 @param successBlock 成功的回调
 @param failureBlock 失败的回调
 @param progressBlock 上传的进度
 */
+ (void)htm_uploadVideoWithEntity:(HttpToolDataEntity *)entity
                    successBlock:(HTMResponseSuccessBlock)successBlock
                    failureBlock:(HTMResponseFailBlock)failureBlock
                   progressBlock:(HTMUploadProgressBlock)progressBlock
{
    if (!entity || entity.urlString == nil || ![entity isKindOfClass:[HttpToolFileDataEntity class]]) {
        return;
    }
    HttpToolFileDataEntity *fileEntity = (HttpToolFileDataEntity *)entity;
    /*! 获得视频资源 */
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:fileEntity.filePath]  options:nil];
    
    /*! 压缩 */
    
    //    NSString *const AVAssetExportPreset640x480;
    //    NSString *const AVAssetExportPreset960x540;
    //    NSString *const AVAssetExportPreset1280x720;
    //    NSString *const AVAssetExportPreset1920x1080;
    //    NSString *const AVAssetExportPreset3840x2160;
    
    /*! 创建日期格式化器 */
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    /*! 转化后直接写入Library---caches */
    NSString *videoWritePath = [NSString stringWithFormat:@"output-%@.mp4",[formatter stringFromDate:[NSDate date]]];
    NSString *outfilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", videoWritePath];
    
    AVAssetExportSession *avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    
    avAssetExport.outputURL = [NSURL fileURLWithPath:outfilePath];
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([avAssetExport status]) {
            case AVAssetExportSessionStatusCompleted:
            {
                [HTMNetManagerShare.sessionManager POST:fileEntity.urlString parameters:fileEntity.parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    NSURL *filePathURL2 = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", outfilePath]];
                    // 获得沙盒中的视频内容
                    [formData appendPartWithFileURL:filePathURL2 name:@"video" fileName:outfilePath mimeType:@"application/octet-stream" error:nil];
                    
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    DLog(@"上传进度--%lld, 总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
                    
                    /*! 回到主线程刷新UI */
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressBlock)
                        {
                            progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                        }
                    });
                } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
                    DLog(@"上传视频成功 = %@",responseObject);
                    if (successBlock)
                    {
                        successBlock(responseObject);
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    DLog(@"上传视频失败 = %@", error);
                    if (failureBlock)
                    {
                        failureBlock(error);
                    }
                }];
                break;
            }
            default:
                break;
        }
    }];
}

/**
 文件下载
 
 @param entity 请求信息载体
 @param successBlock 下载文件成功的回调
 @param failureBlock 下载文件失败的回调
 @param progressBlock 下载文件的进度显示
 @return HTMURLSessionTask
 */

+ (HTMURLSessionTask *)htm_downLoadFileWithEntity:(HttpToolDataEntity *)entity
                                   successBlock:(HTMResponseSuccessBlock)successBlock
                                   failureBlock:(HTMResponseFailBlock)failureBlock
                                  progressBlock:(HTMDownloadProgressBlock)progressBlock
{
    if (!entity || entity.urlString == nil || ![entity isKindOfClass:[HttpToolFileDataEntity class]]) {
        return nil;
    }
    
    HttpToolFileDataEntity *fileEntity = (HttpToolFileDataEntity *)entity;
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:fileEntity.urlString]];
    
    DLog(@"******************** 请求参数 ***************************");
    DLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",HTMNetManagerShare.sessionManager.requestSerializer.HTTPRequestHeaders, @"download", fileEntity.urlString, fileEntity.parameters);
    DLog(@"******************************************************");
    
    
    HTMURLSessionTask *sessionTask = nil;
    
    sessionTask = [HTMNetManagerShare.sessionManager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        
        DLog(@"下载进度：%.2lld%%",100 * downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        /*! 回到主线程刷新UI */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (progressBlock)
            {
                progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
            
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (!fileEntity.filePath)
        {
            NSURL *downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            DLog(@"默认路径--%@",downloadURL);
            return [downloadURL URLByAppendingPathComponent:[response suggestedFilename]];
        }
        else
        {
            return [NSURL fileURLWithPath:fileEntity.filePath];
        }
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self tasks] removeObject:sessionTask];
        
        DLog(@"下载文件成功");
        if (error == nil)
        {
            if (successBlock)
            {
                /*! 返回完整路径 */
                successBlock([filePath path]);
            }
            else
            {
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }
        }
    }];
    
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask)
    {
        [[self tasks] addObject:sessionTask];
    }
    return sessionTask;
}

/**
 文件上传
 
 @param entity 请求信息载体
 @param successBlock successBlock description
 @param failureBlock failureBlock description
 @param progressBlock progressBlock description
 @return HTMURLSessionTask
 */

+ (HTMURLSessionTask *)htm_uploadFileWithWithEntity:(HttpToolDataEntity *)entity
                                     successBlock:(HTMResponseSuccessBlock)successBlock
                                     failureBlock:(HTMResponseFailBlock)failureBlock
                                    progressBlock:(HTMUploadProgressBlock)progressBlock
{
    if (!entity || entity.urlString == nil || ![entity isKindOfClass:[HttpToolFileDataEntity class]]) {
        return nil;
    }
    
    HttpToolFileDataEntity *fileEntity = (HttpToolFileDataEntity *)entity;
    
    DLog(@"******************** 请求参数 ***************************");
    DLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",HTMNetManagerShare.sessionManager.requestSerializer.HTTPRequestHeaders, @"uploadFile", fileEntity.urlString, fileEntity.parameters);
    DLog(@"******************************************************");
    
    HTMURLSessionTask *sessionTask = nil;
    sessionTask = [HTMNetManagerShare.sessionManager POST:fileEntity.urlString parameters:fileEntity.parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:fileEntity.filePath] name:fileEntity.fileName error:&error];
        if (failureBlock && error)
        {
            failureBlock(error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        DLog(@"上传进度--%lld, 总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        
        /*! 回到主线程刷新UI */
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock)
            {
                progressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self tasks] removeObject:sessionTask];
        if (successBlock)
        {
            successBlock(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self tasks] removeObject:sessionTask];
        if (failureBlock)
        {
            failureBlock(error);
        }
    }];
    
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask)
    {
        [[self tasks] addObject:sessionTask];
    }
    return sessionTask;
}

#pragma mark - 网络状态监测
/*!
 *  开启网络监测
 */
+ (void)htm_startNetWorkMonitoringWithBlock:(HTMNetworkStatusBlock)networkStatus
{
    /*! 1.获得网络监控的管理者 */
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    /*! 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示 */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    /*! 2.设置网络状态改变后的处理 */
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        /*! 当网络状态改变了, 就会调用这个block */
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown:
                DLog(@"未知网络");
                networkStatus ? networkStatus(HTMNetworkStatusUnknown) : nil;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                DLog(@"没有网络");
                networkStatus ? networkStatus(HTMNetworkStatusNotReachable) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                DLog(@"手机自带网络");
                networkStatus ? networkStatus(HTMNetworkStatusReachableViaWWAN) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                DLog(@"wifi 网络");
                networkStatus ? networkStatus(HTMNetworkStatusReachableViaWiFi) : nil;
                break;
        }
    }];
    [manager startMonitoring];
}

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
+ (void)htm_cancelAllRequest
{
    // 锁操作
    @synchronized(self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self tasks] removeAllObjects];
    }
}

/*!
 *  取消指定 URL 的 Http 请求
 */
+ (void)htm_cancelRequestWithURL:(NSString *)URL
{
    if (!URL)
    {
        return;
    }
    @synchronized (self)
    {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL])
            {
                [task cancel];
                [[self tasks] removeObject:task];
                *stop = YES;
            }
        }];
    }
}


#pragma mark - 压缩图片尺寸
/*! 对图片尺寸进行压缩 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    if (newSize.height > 375/newSize.width*newSize.height)
    {
        newSize.height = 375/newSize.width*newSize.height;
    }
    
    if (newSize.width > 375)
    {
        newSize.width = 375;
    }
    
    UIImage *newImage = [UIImage needCenterImage:image size:newSize scale:1.0];
    
    return newImage;
}

#pragma mark - url 中文格式化
+ (NSString *)strUTF8Encoding:(NSString *)str
{
    /*! ios9适配的话 打开第一个 */
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0)
    {
        return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    }
    else
    {
        return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
}

#pragma mark - setter / getter
/**
 存储着所有的请求task数组
 
 @return 存储着所有的请求task数组
 */
+ (NSMutableArray *)tasks
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DLog(@"创建数组");
        tasks = [[NSMutableArray alloc] init];
    });
    return tasks;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _timeoutInterval = timeoutInterval;
    HTMNetManagerShare.sessionManager.requestSerializer.timeoutInterval = timeoutInterval;
}

- (void)setRequestSerializer:(HTMHttpRequestSerializer)requestSerializer
{
    _requestSerializer = requestSerializer;
    switch (requestSerializer) {
        case HTMHttpRequestSerializerJSON:
        {
            HTMNetManagerShare.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer] ;
        }
            break;
        case HTMHttpRequestSerializerHTTP:
        {
            HTMNetManagerShare.sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer] ;
        }
            break;
            
        default:
            break;
    }
}

- (void)setResponseSerializer:(HTMHttpResponseSerializer)responseSerializer
{
    _responseSerializer = responseSerializer;
    switch (responseSerializer) {
        case HTMHttpResponseSerializerJSON:
        {
            HTMNetManagerShare.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer] ;
        }
            break;
        case HTMHttpResponseSerializerHTTP:
        {
            HTMNetManagerShare.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer] ;
        }
            break;
            
        default:
            break;
    }
}

- (void)setHttpHeaderFieldDictionary:(NSDictionary *)httpHeaderFieldDictionary
{
    _httpHeaderFieldDictionary = httpHeaderFieldDictionary;
    
    if (![httpHeaderFieldDictionary isKindOfClass:[NSDictionary class]])
    {
        DLog(@"请求头数据有误，请检查！");
        return;
    }
    NSArray *keyArray = httpHeaderFieldDictionary.allKeys;
    
    if (keyArray.count <= 0)
    {
        DLog(@"请求头数据有误，请检查！");
        return;
    }
    
    for (NSInteger i = 0; i < keyArray.count; i ++)
    {
        NSString *keyString = keyArray[i];
        NSString *valueString = httpHeaderFieldDictionary[keyString];
        
        [HttpToolManager htm_setValue:valueString forHTTPHeaderKey:keyString];
    }
}

/**
 *  自定义请求头
 */
+ (void)htm_setValue:(NSString *)value forHTTPHeaderKey:(NSString *)HTTPHeaderKey
{
    [HTMNetManagerShare.sessionManager.requestSerializer setValue:value forHTTPHeaderField:HTTPHeaderKey];
}


/**
 删除所有请求头
 */
+ (void)htm_clearAuthorizationHeader
{
    [HTMNetManagerShare.sessionManager.requestSerializer clearAuthorizationHeader];
}

+ (void)htm_uploadImageWithFormData:(id<AFMultipartFormData>  _Nonnull )formData
                      resizedImage:(UIImage *)resizedImage
                         imageType:(NSString *)imageType
                        imageScale:(CGFloat)imageScale
                         fileNames:(NSArray <NSString *> *)fileNames
                             index:(NSUInteger)index
{
    /*! 此处压缩方法是jpeg格式是原图大小的0.8倍，要调整大小的话，就在这里调整就行了还是原图等比压缩 */
    if (imageScale == 0)
    {
        imageScale = 0.8;
    }
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, imageScale ?: 1.f);
    
    /*! 拼接data */
    if (imageData != nil)
    {   // 图片数据不为空才传递 fileName
        //                [formData appendPartWithFileData:imgData name:[NSString stringWithFormat:@"picflie%ld",(long)i] fileName:@"image.png" mimeType:@" image/jpeg"];
        
        // 默认图片的文件名, 若fileNames为nil就使用
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str, index, imageType?:@"jpg"];
        
        [formData appendPartWithFileData:imageData
                                    name:[NSString stringWithFormat:@"picflie%ld", index]
                                fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[index],imageType?:@"jpg"] : imageFileName
                                mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        DLog(@"上传图片 %lu 成功", (unsigned long)index);
    }
}

/**
 清空缓存：此方法可能会阻止调用线程，直到文件删除完成。
 */
- (void)htm_clearAllHttpCache
{
    [HttpToolManagerCache htm_clearAllHttpCache];
}

@end

#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建 NSDictionary 与 NSArray 的分类, 控制台打印 json 数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (HTMNetManager)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (HTMNetManager)

- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end

#endif


