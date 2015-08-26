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
####connect(appID,callback)
```
appID: your unique Layer appID
callback return:(error,YES|NO)
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
####disconnect()
####sendMessageToUserIDs(messageText, userIDs[], callback)
####getConversations(limit, offset, callback)
####getMessages(conversationID, limit, callback)
####sendTypingBegin(conversationID)
####sendTypingEnd(conversationID)
####registerForTypingEvents()
####unregisterForTypingEvents()
