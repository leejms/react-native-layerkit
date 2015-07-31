//
//  LayerAuthenticate.h
//  layerPod
//
//  Created by Joseph Johnson on 7/29/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>

@interface LayerAuthenticate : NSObject
-(void)authenticateLayerWithUserID:(NSString *)userID layerClient:(LYRClient*)layerClient completion:(void(^)(NSError *error))completion;
@end
