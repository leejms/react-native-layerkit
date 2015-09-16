#import "RCTBridgeModule.h"
#import <LayerKit/LayerKit.h>
#import "JSONHelper.h"
#import "LayerAuthenticate.h"
#import "LayerQuery.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"

@interface RNLayerKit : NSObject <RCTBridgeModule>
- (void)didReceiveTypingIndicator:(NSNotification *)notification;
- (BOOL)updateRemoteNotificationDeviceToken:(NSData*)deviceToken;
@end
