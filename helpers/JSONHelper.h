//
//  JSONHelper.h
//  layerPod
//
//  Created by Joseph Johnson on 7/27/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>

@interface JSONHelper : NSObject


/* converts LYRConversasion properties to a JSON object */
-(NSDictionary*)convertConvoToDictionary:(LYRConversation*)convo;
-(NSArray*)convertConvosToArray:(NSOrderedSet*)allConvos;
-(NSDictionary*)convertErrorToDictionary:(NSError*)error;
-(NSArray*)convertMessagesToArray:(NSOrderedSet*)allMessages;
-(NSArray*)convertChangesToArray:(NSArray*)changes;

@end
