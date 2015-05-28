//
//  WeatherHTTPClient.h
//  Weather
//
//  Created by qianfeng on 15/5/6.
//  Copyright (c) 2015年 Scott Sherwood. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@protocol WeatherHTTPClientDelegate;


@interface WeatherHTTPClient : AFHTTPSessionManager
@property (nonatomic,weak) id<WeatherHTTPClientDelegate>delegate;

+(WeatherHTTPClient*)sharedWeatherHTTPClient;

-(instancetype)initWithBaseURL:(NSURL *)url;
-(void)updateWeatherAtLocation:(CLLocation *)location forNumberOfDays:(NSUInteger)number;

@end


@protocol WeatherHTTPClientDelegate <NSObject>

@optional
-(void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)weather;
-(void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError*)error;
@end


