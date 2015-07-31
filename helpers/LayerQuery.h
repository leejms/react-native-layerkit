//
//  LayerQuery.h
//  layerPod
//
//  Created by Joseph Johnson on 7/29/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>

@interface LayerQuery : NSObject
-(NSOrderedSet*)fetchConvosForClient:(LYRClient*)client limit:(int)limit offset:(int)offset error:(NSError*)error;
-(LYRConversation*)fetchConvoWithId:(NSString*)convoID client:(LYRClient*)client error:(NSError*)error;
-(NSOrderedSet*)fetchMessagesForConvoId:(NSString*)convoID client:(LYRClient*)client limit:(int)limit offset:(int)offset error:(NSError*)error;
@end
