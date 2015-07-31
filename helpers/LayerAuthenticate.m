//
//  LayerAuthenticate.m
//  layerPod
//
//  Created by Joseph Johnson on 7/29/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "LayerAuthenticate.h"

@implementation LayerAuthenticate

-(void)authenticateLayerWithUserID:(NSString *)userID layerClient:(LYRClient*)layerClient completion:(void(^)(NSError *error))completion;
{
  // Check to see if the layerClient is already authenticated.
  if (layerClient.authenticatedUserID) {
    // If the layerClient is authenticated with the requested userID, complete the authentication process.
    if ([layerClient.authenticatedUserID isEqualToString:userID]){
      completion(nil);
    } else {
      //If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
      [layerClient deauthenticateWithCompletion:^(BOOL success, NSError *deError) {
        if (!deError){
          [self authenticationTokenWithUserId:userID lyrClient:layerClient completion:^(BOOL success, NSError *aError) {
            if(aError){
              completion(aError);
            }
            else{
              completion(nil);
            }
            
          }];
        } else {
          completion(deError);
        }
      }];
    }
  } else {
    // If the layerClient isn't already authenticated, then authenticate.
    [self authenticationTokenWithUserId:userID lyrClient:layerClient completion:^(BOOL success, NSError *error) {
      if(error){
        completion(error);
      }
      else{
        completion(nil);
      }
    }];
  }

}
- (void)authenticationTokenWithUserId:(NSString *)userID lyrClient:(LYRClient*)lyrClient completion:(void (^)(BOOL success, NSError* error))completion{
  
  /*
   * 1. Request an authentication Nonce from Layer
   */
  [lyrClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
    if (!nonce) {
      if (completion) {
        completion(NO, error);
      }
      return;
    }
    
    /*
     * 2. Acquire identity Token from Layer Identity Service
     */
    [self requestIdentityTokenForUserID:userID appID:[lyrClient.appID absoluteString] nonce:nonce completion:^(NSString *identityToken, NSError *error) {
      if (!identityToken) {
        if (completion) {
          completion(NO, error);
        }
        return;
      }
      
      /*
       * 3. Submit identity token to Layer for validation
       */
      [lyrClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
        if (authenticatedUserID) {
          if (completion) {
            completion(YES, nil);
          }
          NSLog(@"Layer Authenticated as User: %@", authenticatedUserID);
        } else {
          completion(NO, error);
        }
      }];
    }];
  }];
}

- (void)requestIdentityTokenForUserID:(NSString *)userID appID:(NSString *)appID nonce:(NSString *)nonce completion:(void(^)(NSString *identityToken, NSError *error))completion
{
  NSParameterAssert(userID);
  NSParameterAssert(appID);
  NSParameterAssert(nonce);
  NSParameterAssert(completion);
  
  NSURL *identityTokenURL = [NSURL URLWithString:@"https://layer-identity-provider.herokuapp.com/identity_tokens"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:identityTokenURL];
  request.HTTPMethod = @"POST";
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  
  NSDictionary *parameters = @{ @"app_id": appID, @"user_id": userID, @"nonce": nonce };
  NSData *requestBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
  request.HTTPBody = requestBody;
  
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
      completion(nil, error);
      return;
    }
    
    // Deserialize the response
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if(![responseObject valueForKey:@"error"])
    {
      NSString *identityToken = responseObject[@"identity_token"];
      completion(identityToken, nil);
    }
    else
    {
      NSString *domain = @"layer-identity-provider.herokuapp.com";
      NSInteger code = [responseObject[@"status"] integerValue];
      NSDictionary *userInfo =
      @{
        NSLocalizedDescriptionKey: @"Layer Identity Provider Returned an Error.",
        NSLocalizedRecoverySuggestionErrorKey: @"There may be a problem with your APPID."
        };
      
      NSError *error = [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
      completion(nil, error);
    }
    
  }] resume];
}

@end
