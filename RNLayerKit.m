#import "RNLayerKit.h"

@implementation RNLayerKit{
    NSString *_appID;
    LYRClient *_layerClient;
    JSONHelper *_jsonHelper;
}

@synthesize bridge = _bridge;

- (id)init
{
    if ((self = [super init])) {
        RCTLogInfo(@"LayerBridge init");
        _jsonHelper = [JSONHelper new];
    }
    return self;
}

//- (dispatch_queue_t)methodQueue
//{
//  return dispatch_queue_create("com.schoolstatus.LayerCLientQueue", DISPATCH_QUEUE_SERIAL);
//}

RCT_EXPORT_MODULE()


RCT_EXPORT_METHOD(connect:(NSString*)appIDstr callback:(RCTResponseSenderBlock)callback)
{
    if (!_layerClient) {
        NSLog(@"No Layer Client");
        NSURL *appID = [NSURL URLWithString:appIDstr];
        _layerClient = [LYRClient clientWithAppID:appID];
        [_layerClient setDelegate:self];
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                RCTLogInfo(@"Failed to connect to Layer: %@", error);
                callback(@[[_jsonHelper convertErrorToDictionary:error], @NO]);
            } else {
                RCTLogInfo(@"Connected to Layer!");
                callback(@[[NSNull null], @YES]);
            }
        }];
        
    }
}

RCT_EXPORT_METHOD(disconnect)
{
    [_layerClient disconnect];
}

RCT_EXPORT_METHOD(sendMessageToUserIDs:(NSString*)messageText userIDs:(NSArray*)userIDs callback:(RCTResponseSenderBlock)callback)
{
    // Declares a MIME type string
    static NSString *const MIMETypeTextPlain = @"text/plain";
    
    // Creates and returns a new conversation object with a single participant represented by
    // your backend's user identifier for the participant
    NSError *convErr = nil;
    LYRConversation *conversation = [self fetchLayerConversationWithParticipants:userIDs andErr:convErr];
    if(!conversation){
        RCTLogError(@"Error creating conversastion");
    }
    if(convErr){
        id retErr = RCTMakeAndLogError(@"Error creating conversastion",convErr,NULL);
        callback(@[retErr,[NSNull null]]);
    }
    // Creates a message part with a text/plain MIMEType
    NSError *error = nil;
    NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];
    LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];
    
    // Creates and returns a new message object with the given conversation and array of message parts
    LYRMessage *message = [_layerClient newMessageWithParts:@[ messagePart ] options:nil error:&error];
    
    // Sends the specified message
    BOOL success = [conversation sendMessage:message error:&error];
    
    if(success){
        RCTLogInfo(@"Layer Message sent to %@", userIDs);
        //callback(@[[NSNull null],conversation]);
        callback(@[[NSNull null],@YES]);
        
    }
    else {
        id retErr = RCTMakeAndLogError(@"Error sending Layer message",error,NULL);
        callback(@[retErr,[NSNull null]]);
        
    }
    
}

RCT_EXPORT_METHOD(getConversations:(int)limit offset:(int)offset callback:(RCTResponseSenderBlock)callback)
{
    LayerQuery *query = [LayerQuery new];
    NSError *queryError;
    id allConvos = [query fetchConvosForClient:_layerClient limit:limit offset:offset error:queryError];
    if(queryError){
        id retErr = RCTMakeAndLogError(@"Error getting Layer conversations",queryError,NULL);
        callback(@[retErr,[NSNull null]]);
    }
    else{
        JSONHelper *helper = [JSONHelper new];
        NSArray *retData = [helper convertConvosToArray:allConvos];
        callback(@[[NSNull null],retData]);
    }
}

RCT_EXPORT_METHOD(getMessages:(NSString*)convoID limit:(int)limit offset:(int)offset callback:(RCTResponseSenderBlock)callback)
{
    LayerQuery *query = [LayerQuery new];
    NSError *queryError;
    NSOrderedSet *convoMessages = [query fetchMessagesForConvoId:convoID client:_layerClient limit:limit offset:offset error:queryError];
    if(queryError){
        id retErr = RCTMakeAndLogError(@"Error getting Layer messages",queryError,NULL);
        callback(@[retErr,[NSNull null]]);
    }
    else{
        JSONHelper *helper = [JSONHelper new];
        NSArray *retData = [helper convertMessagesToArray:convoMessages];
        callback(@[[NSNull null],retData]);
    }
}

RCT_EXPORT_METHOD(sendTypingBegin:(NSString*)convoID)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingDidBegin];
    }
}

RCT_EXPORT_METHOD(sendTypingEnd:(NSString*)convoID)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingDidBegin];
    }
}

RCT_EXPORT_METHOD(registerForTypingEvents)
{
    // Registers and object for typing indicator notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTypingIndicator:)
                                                 name:LYRConversationDidReceiveTypingIndicatorNotification
                                               object:nil];
}

RCT_EXPORT_METHOD(unregisterForTypingEvents)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRConversationDidReceiveTypingIndicatorNotification object:nil];
}
#pragma mark - Authentication
RCT_EXPORT_METHOD(authenticateLayerWithUserID:(NSString *)userID callback:(RCTResponseSenderBlock)callback)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRConversationDidReceiveTypingIndicatorNotification object:nil];
    LayerAuthenticate *lAuth = [LayerAuthenticate new];
    [lAuth authenticateLayerWithUserID:userID layerClient:_layerClient completion:^(NSError *error) {
        if (!error) {
            //GOOD LOGIN!!!
            callback(@[[NSNull null],@(YES)]);
        }
        else{
            id retErr = RCTMakeAndLogError(@"Error logging in",error,NULL);
            callback(@[retErr,[NSNull null]]);
        }
    }];
}

#pragma mark - Register for Push Notif
-(BOOL)updateRemoteNotificationDeviceToken:(NSData*)deviceToken
{
    NSError *error;
    BOOL success = [_layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
    if (success) {
        NSLog(@"Application did register for remote notifications");
        return true;
    } else {
        NSLog(@"Error updating Layer device token for push:%@", error);
        [self sendErrorEvent:error];
        return false;
    }

}
#pragma mark - Error Handle
-(void)sendErrorEvent:(NSError*)error{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"error",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
#pragma mark - Layer Client Delegate
- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",@"type": @"didAuthenticateAsUserID", @"data":@{@"userID":userID}}];
}
- (void)layerClient:(LYRClient *)client didFailOperationWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFailOperationWithError",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didFailSynchronizationWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFailSynchronizationWithError",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didFinishContentTransfer:(LYRContentTransferType)contentTransferType ofObject:(id)object
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFinishContentTransfer"}];
}
- (void)layerClient:(LYRClient *)client didFinishSynchronizationWithChanges:(NSArray *)changes
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFinishSynchronizationWithChanges"}];
}
- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didLoseConnectionWithError", @"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didReceiveAuthenticationChallengeWithNonce"}];
}
- (void)layerClient:(LYRClient *)client objectsDidChange:(NSArray *)changes;
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",
                                                        @"type": @"objectsDidChange",
                                                        @"data":[_jsonHelper convertChangesToArray:changes]}];
}
- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type":@"willAttemptToConnect", @"data":@{@"attemptNumber":@(attemptNumber), @"delayInterval":@(delayInterval), @"attemptLimit":@(attemptLimit)}}];
}
- (void)layerClient:(LYRClient *)client willBeginContentTransfer:(LYRContentTransferType)contentTransferType ofObject:(id)object withProgress:(LYRProgress *)progress
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"willBeginContentTransfer"}];
}
- (void)layerClientDidConnect:(LYRClient *)client{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidConnect"}];
}
- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidDeauthenticate"}];
}
- (void)layerClientDidDisconnect:(LYRClient *)client
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidDisconnect"}];
}

#pragma mark - Typing Indicator
- (void)didReceiveTypingIndicator:(NSNotification *)notification
{
    NSString *participantID = notification.userInfo[LYRTypingIndicatorParticipantUserInfoKey];
    NSString *convoID = [[notification.object valueForKey:@"identifier"] absoluteString];
    LYRTypingIndicator typingIndicator = [notification.userInfo[LYRTypingIndicatorValueUserInfoKey] unsignedIntegerValue];
    
    if (typingIndicator == LYRTypingDidBegin) {
        NSLog(@"Typing Started");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidBegin",
                                                                      @"conversationID":convoID}}];
    }
    else if(typingIndicator==LYRTypingDidPause){
        NSLog(@"Typing paused");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidPause",
                                                                      @"conversationID":convoID}}];
    }
    else {
        NSLog(@"Typing Stopped");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidEnd",
                                                                      @"conversationID":convoID}}];
    }
}

//#pragma mark - Layer Query Delegate
//- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerDidChangeObject"}];
//
//}
//- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerDidChangeContent"}];
//
//}
//- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerWillChangeContent"}];
//
//}
#pragma mark - Fetching Layer Content

- (LYRConversation*)fetchLayerConversationWithParticipants:(NSArray*)participants andErr:(NSError*)convErr
{
    // Fetches all conversations between the authenticated user and the supplied participant
    // For more information about Querying, check out https://developer.layer.com/docs/integration/ios#querying
    
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"participants" predicateOperator:LYRPredicateOperatorIsEqualTo value:participants];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO] ];
    
    NSOrderedSet *conversations = [_layerClient executeQuery:query error:&convErr];
    
    if (conversations.count <= 0) {
        NSError *conv_error = nil;
        return [_layerClient newConversationWithParticipants:[NSSet setWithArray: participants ] options:nil error:&conv_error];
    }
    else {
        return [conversations lastObject];
    }
}

-(id) fetchAllLayerConversasions
{
    // Fetches all LYRConversation objects
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    
    NSError *error = nil;
    NSOrderedSet *conversations = [_layerClient executeQuery:query error:&error];
    if (conversations) {
        RCTLogInfo(@"%tu conversations", conversations.count);
    } else {
        RCTLogError(@"Query failed with error %@", error);
    }
    if (!error) {
        return conversations;
    }
    else {
        return error;
    }
}

@end
