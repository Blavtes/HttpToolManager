//
//  HttpToolManager.h
//  BANetManager
//
//  Created by Blavtes on 2018/1/31.
//  Copyright © 2018年 boai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#define HTMNetManagerShare [HttpToolManager sharedHTMNetManager]

#define HTMWeak  __weak __typeof(self) weakSelf = self

/*! 过期属性或方法名提醒 */
#define HTMNetManagerDeprecated(instead) __deprecated_msg(instead)


/*! 使用枚举NS_ENUM:区别可判断编译器是否支持新式枚举,支持就使用新的,否则使用旧的 */
typedef NS_ENUM(NSUInteger, HTMNetworkStatus)
{
    /*! 未知网络 */
    HTMNetworkStatusUnknown           = 0,
    /*! 没有网络 */
    HTMNetworkStatusNotReachable,
    /*! 手机 3G/4G 网络 */
    HTMNetworkStatusReachableViaWWAN,
    /*! wifi 网络 */
    HTMNetworkStatusReachableViaWiFi
};

/*！定义请求类型的枚举 */
typedef NS_ENUM(NSUInteger, HTMHttpRequestType)
{
    /*! get请求 */
    HTMHttpRequestTypeGet = 0,
    /*! post请求 */
    HTMHttpRequestTypePost,
    /*! put请求 */
    HTMHttpRequestTypePut,
    /*! delete请求 */
    HTMHttpRequestTypeDelete
};

typedef NS_ENUM(NSUInteger, HTMHttpRequestSerializer) {
    /** 设置请求数据为JSON格式*/
    HTMHttpRequestSerializerJSON,
    /** 设置请求数据为HTTP格式*/
    HTMHttpRequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, HTMHttpResponseSerializer) {
    /** 设置响应数据为JSON格式*/
    HTMHttpResponseSerializerJSON,
    /** 设置响应数据为HTTP格式*/
    HTMHttpResponseSerializerHTTP,
};

/*! 实时监测网络状态的 block */
typedef void(^HTMNetworkStatusBlock)(HTMNetworkStatus status);

/*! 定义请求成功的 block */
typedef void( ^ HTMResponseSuccessBlock)(id response);
/*! 定义请求失败的 block */
typedef void( ^ HTMResponseFailBlock)(NSError *error);

/*! 定义上传进度 block */
typedef void( ^ HTMUploadProgressBlock)(int64_t bytesProgress,
                                       int64_t totalBytesProgress);
/*! 定义下载进度 block */
typedef void( ^ HTMDownloadProgressBlock)(int64_t bytesProgress,
                                         int64_t totalBytesProgress);

/*!
 *  方便管理请求任务。执行取消，暂停，继续等任务.
 *  - (void)cancel，取消任务
 *  - (void)suspend，暂停任务
 *  - (void)resume，继续任务
 */
typedef NSURLSessionTask HTMURLSessionTask;

@class HttpToolDataEntity;

@interface HttpToolManager : NSObject

/**
 创建的请求的超时间隔（以秒为单位），此设置为全局统一设置一次即可，默认超时时间间隔为30秒。
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 设置网络请求参数的格式，此设置为全局统一设置一次即可，默认：BAHttpRequestSerializerJSON
 */
@property (nonatomic, assign) HTMHttpRequestSerializer requestSerializer;

/**
 设置服务器响应数据格式，此设置为全局统一设置一次即可，默认：BAHttpResponseSerializerJSON
 */
@property (nonatomic, assign) HTMHttpResponseSerializer responseSerializer;

/**
 自定义请求头：httpHeaderField
 */
@property(nonatomic, strong) NSDictionary *httpHeaderFieldDictionary;

/*!
 *  获得全局唯一的网络请求实例单例方法
 *
 *  @return 网络请求类HTMNetManager单例
 */
+ (instancetype)sharedHTMNetManager;


#pragma mark - 网络请求的类方法 --- get / post / put / delete

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
                                 progressBlock:(HTMDownloadProgressBlock)progressBlock;

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
                                  progressBlock:(HTMDownloadProgressBlock)progressBlock;

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
                                 progressBlock:(HTMDownloadProgressBlock)progressBlock;

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
                                    progressBlock:(HTMDownloadProgressBlock)progressBlock;

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
                                 progressBlock:(HTMUploadProgressBlock)progressBlock;

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
                   progressBlock:(HTMUploadProgressBlock)progressBlock;

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
                                  progressBlock:(HTMDownloadProgressBlock)progressBlock;

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
                                    progressBlock:(HTMUploadProgressBlock)progressBlock;


#pragma mark - 网络状态监测
/*!
 *  开启实时网络状态监测，通过Block回调实时获取(此方法可多次调用)
 */
+ (void)htm_startNetWorkMonitoringWithBlock:(HTMNetworkStatusBlock)networkStatus;

#pragma mark - 自定义请求头
/**
 *  自定义请求头
 */
+ (void)htm_setValue:(NSString *)value forHTTPHeaderKey:(NSString *)HTTPHeaderKey;

/**
 删除所有请求头
 */
+ (void)htm_clearAuthorizationHeader;

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
+ (void)htm_cancelAllRequest;

/*!
 *  取消指定 URL 的 Http 请求
 */
+ (void)htm_cancelRequestWithURL:(NSString *)URL;

/**
 清空缓存：此方法可能会阻止调用线程，直到文件删除完成。
 */
- (void)htm_clearAllHttpCache;

@end
