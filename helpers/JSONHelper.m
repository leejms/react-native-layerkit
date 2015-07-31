//
//  JSONHelper.m
//  layerPod
//
//  Created by Joseph Johnson on 7/27/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
/////////////////////////////////////////////////////////
/*
  This class will convert LYRConversation object properties
  to a JSON object that can be sent back to REACT in a callback

  Layer Objects need to be broken down into Dictionaries of simple classes
  (NSString, NSNumber, etc)
*/

#import "JSONHelper.h"

@implementation JSONHelper

#pragma mark-public methods
-(NSDictionary*)convertConvoToDictionary:(LYRConversation *)convo
{
  NSError *writeError = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self convertCovoToDict:convo] options:NSJSONWritingPrettyPrinted error:&writeError];
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  NSLog(@"JSON Output: %@", jsonString);
  
  return [self convertCovoToDict:convo];
}

-(NSArray*)convertConvosToArray:(NSOrderedSet*)allConvos
{
  NSMutableArray *allArr = [NSMutableArray new];
  for(LYRConversation *convo in allConvos){
    [allArr addObject:[self convertCovoToDict:convo]];
  }
//  NSError *writeError = nil;
//  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allArr options:NSJSONWritingPrettyPrinted error:&writeError];
//  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//  NSLog(@"JSON Output: %@", jsonString);
  
  return allArr;
}

-(NSArray*)convertMessagesToArray:(NSOrderedSet *)allMessages
{
  NSMutableArray *allArr = [NSMutableArray new];
  for (LYRMessage *msg in allMessages) {
    [allArr addObject:[self convertMessageToDict:msg]];
  }
  return allArr;
}

-(NSDictionary*)convertErrorToDictionary:(NSError *)error
{
  return @{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]};
}

-(NSArray*)convertChangesToArray:(NSArray*)changes
{
  NSMutableArray *allChanges = [NSMutableArray new];
  for(LYRObjectChange *thisChange in changes){
    NSMutableDictionary *changeData = [NSMutableDictionary new];
    [changeData setValue:NSStringFromClass([thisChange.object class]) forKey:@"object"];
    //TODO: make this safer in the event they change it from NSURL in the future
    [changeData setValue:[[thisChange.object valueForKey:@"identifier"] absoluteString] forKey:@"identifier"];
    //[changeData setValue:[thisChange.object description] forKey:@"description"];
    [changeData setValue:thisChange.property forKey:@"property"];
    if(thisChange.type==LYRObjectChangeTypeCreate)
      [changeData setValue:@"LYRObjectChangeTypeCreate" forKey:@"type"];
    else if(thisChange.type==LYRObjectChangeTypeDelete)
      [changeData setValue:@"LYRObjectChangeTypeDelete" forKey:@"type"];
    else if(thisChange.type==LYRObjectChangeTypeUpdate)
      [changeData setValue:@"LYRObjectChangeTypeUpdate" forKey:@"type"];

    [allChanges addObject:changeData];
  }
  
  return allChanges;

}

#pragma mark-private methods
-(NSDictionary*)convertCovoToDict:(LYRConversation*)convo
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[convo.identifier absoluteString] forKey:@"identifier"];
  [propertyDict setValue:@(convo.hasUnreadMessages) forKey:@"hasUnreadMessages"];
  [propertyDict setValue:@(convo.deliveryReceiptsEnabled) forKey:@"deliveryReceiptsEnabled"];
  [propertyDict setValue:@(convo.isDeleted) forKey:@"isDeleted"];
  [propertyDict setValue:convo.metadata forKey:@"metadata"];
  [propertyDict setValue:[convo.participants allObjects] forKey:@"participants"];

  [propertyDict setValue:[self convertDateToJSON:convo.createdAt] forKey:@"createdAt"];
  [propertyDict setValue:[self convertMessageToDict:convo.lastMessage] forKey:@"lastMessage"];

  return [NSDictionary dictionaryWithDictionary:propertyDict];
}

-(NSDictionary*)convertMessageToDict:(LYRMessage*)msg
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[NSMutableDictionary dictionaryWithDictionary:msg.recipientStatusByUserID] forKey:@"recipientStatusByUserID"];
  [propertyDict setValue:@(msg.isSent) forKey:@"isSent"];
  [propertyDict setValue:@(msg.isDeleted) forKey:@"isDeleted"];
  [propertyDict setValue:@(msg.isUnread) forKey:@"isUnread"];
  [propertyDict setValue:msg.sender.userID forKey:@"sender"];
  [propertyDict setValue:[self convertDateToJSON:msg.sentAt] forKey:@"sentAt"];
  [propertyDict setValue:[self convertDateToJSON:msg.receivedAt] forKey:@"recievedAt"];
  [propertyDict setValue:[msg.identifier absoluteString] forKey:@"identifier"];

  NSMutableString *messageText= [NSMutableString new];
  NSMutableArray *messageParts = [NSMutableArray new];
  for(LYRMessagePart *part in msg.parts){
    [messageParts addObject:[self convertMessagePartToDict:part]];
    if([part.MIMEType isEqualToString:@"text/plain"]){
      [messageText appendString:[[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding]];
    }
  }

  [propertyDict setValue:messageParts forKey:@"parts"];
  [propertyDict setValue:messageText forKey:@"text"];

  
  return [NSDictionary dictionaryWithDictionary:propertyDict];
}

-(NSDictionary*)convertMessagePartToDict:(LYRMessagePart*)msgPart
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[msgPart.identifier absoluteString] forKey:@"identifier"];
  [propertyDict setValue:msgPart.MIMEType forKey:@"MIMEType"];
  [propertyDict setValue:@(msgPart.size) forKey:@"size"];
  [propertyDict setValue:@(msgPart.transferStatus) forKey:@"transferStatus"];
  [propertyDict setValue: [[NSString alloc] initWithData:msgPart.data encoding:NSUTF8StringEncoding] forKey:@"data"];

  return [NSDictionary dictionaryWithDictionary:propertyDict];
}

-(NSString*)convertDateToJSON:(NSDate*)date
{
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  [fmt setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
  return [fmt stringFromDate:date];
}
@end
