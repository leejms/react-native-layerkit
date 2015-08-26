# react-native-layerkit
React Native module for commincating with Layer iOS SDK https://layer.com/

**this doc is a work in progress**

### Layer installation

1. Install cocopods (if not already installed)
	`sudo gem install cocoapods`

2. Run the following command:
	`pod init`

3. add the following line to Podfile:
	`pod 'LayerKit'`

4. Run the following command:
	`pod install --verbose`

5. Add this to your package.json dependencis under ReactNative dir  
	` "react-native-layerkit": "git@github.com:leejms/react-native-layerkit.git" `

6. Install npm `npm install`

7. Open your .xcworkspace

8. Click "Build Settings" in Xcode:
	Add the followindg to "Other Linker Flags": `$inherited`

##react-native-layerkit methods
_var Layer = require('react-native-layerkit');_
####connect(appID,callback)
```
appID: your unique Layer appID
callback return:[error,YES|NO]
```
example:
```
      Layer.connect(
        "layer:///apps/staging/myappid",
        (error, success) => {
          if (error) {
            console.log('login error',error);
            //go to main screen
          }
          else {
            console.log('connect success',success);
            //handle error
          }
        }
      )
```
####authenticateLayerWithUserID(userID, callback)
```
userID: unique userID that Layer will send nonce for
callback return:[error,'YES'|'NO']
```
example:
```
      Layer.authenticateLayerWithUserID(this.state.uname,(error, success) => {
          if (error) {
            console.error('login error',error);
          }
          else {
            console.log('login success',success);
          }
        }
      )
```
####disconnect()
####sendMessageToUserIDs(messageText, userIDs[], callback)
```
messageText: the text of the message
userIDs: an array of userids to send the message to
callback return:[error,'YES'|'NO']
```
example:
```
  Layer.sendMessageToUserIDs(
    'this is a test',
    ['user1234'],
    (error, success) => {
      if (error) { console.error('message error',error); }
      else {
        console.log('message success',success);
      }
    }
  );
```
####getConversations(limit, offset, callback)
```
limit: maximum number of messages to return.  0 = no maximum
offset: message numer to start from (for paging)
callback return:[error, Array of conversasion objects]
```
example:
```
    Layer.getConversations(0,0,(error, success) => {
        if (error) { console.error('getAllConvos error',error); }
        else {
          console.log('getAllConvos success',success);
        }
      }
    );
```
####getMessages(conversationID, limit, offset, callback)
```
conversationID: unique id of the conversation to retrieve messages for
limit: maximum number of messages to return.  0 = no maximum
offset: message numer to start from (for paging)
callback return:[error, Array of message objects]
```
example:
```
    Layer.getMessages(0,0,(error, success) => {
        if (error) { console.error('getMessages error',error); }
        else {
          console.log('getMessages success',success);
        }
      }
    );
```
####sendTypingBegin(conversationID)
```
conversationID: the unique conversation object id
```
example:
####sendTypingEnd(conversationID)
```
conversationID: the unique conversation object id
```
example:
####registerForTypingEvents()
```
will register to recieve typing indicator events from other users
```
listen to events example:
```
var React = require('react-native');
var {
  ...
  NativeAppEventEmitter,
  ...
} = React;
...
  componentWillMount() {
    subscription = NativeAppEventEmitter.addListener( 'LayerEvent', (event) => this._handleEvent(event) );
  },
  componentWillUnmount() {
    subscription.remove();
  },
  _handleEvent(event) {
    console.log(event);
  },
  ...
```
####unregisterForTypingEvents()
