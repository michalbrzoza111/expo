// Copyright 2016-present 650 Industries. All rights reserved.

#import "ABI19_0_0EXGoogle.h"
#import "ABI19_0_0EXOAuthViewController.h"
#import "ABI19_0_0EXScopedModuleRegistry.h"

#import <GoogleSignIn/GoogleSignIn.h>
#import <AppAuth.h>
#import <ReactABI19_0_0/ABI19_0_0RCTUtils.h>

NSString *ABI19_0_0EXGoogleErrorCode = @"GOOGLE_ERROR";

@interface ABI19_0_0EXGoogle () <GIDSignInDelegate, GIDSignInUIDelegate>

@property (nonatomic, weak) id kernelGoogleAuthServiceDelegate;

@end

@implementation ABI19_0_0EXGoogle
{
  ABI19_0_0RCTPromiseResolveBlock _logInResolve;
  ABI19_0_0RCTPromiseRejectBlock _logInReject;
}

ABI19_0_0EX_EXPORT_SCOPED_MODULE(ExponentGoogle, GoogleAuthManager);

- (instancetype)initWithExperienceId:(NSString *)experienceId kernelServiceDelegate:(id)kernelServiceInstance params:(NSDictionary *)params
{
  if (self = [super initWithExperienceId:experienceId kernelServiceDelegate:kernelServiceInstance params:params]) {
    _kernelGoogleAuthServiceDelegate = kernelServiceInstance;
  }
  return self;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

ABI19_0_0RCT_REMAP_METHOD(logInAsync,
                 config:(NSDictionary *)config
                 resolver:(ABI19_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI19_0_0RCTPromiseRejectBlock)reject)
{
  if (_logInResolve != nil) {
    reject(ABI19_0_0EXGoogleErrorCode, @"Another login request is already in progress.", nil);
    return;
  }
  _logInResolve = resolve;
  _logInReject = reject;
  NSString *behavior = config[@"behavior"];
  if ([behavior isEqualToString:@"system"]) {
    [self systemLogInWithClientId:config[@"iosClientId"] scopes:config[@"scopes"]];
  } else if ([behavior isEqualToString:@"web"]) {
    [self webLogInWithClientId:config[@"iosClientId"] scopes:config[@"scopes"]];
  } else {
    reject(ABI19_0_0EXGoogleErrorCode, [NSString stringWithFormat:@"Invalid behavior %@", behavior], nil);
  }
}

-(void)systemLogInWithClientId:(NSString *)clientId scopes:(NSArray<NSString *> *)scopes
{
  [GIDSignIn sharedInstance].delegate = self;
  [GIDSignIn sharedInstance].uiDelegate = self;
  [GIDSignIn sharedInstance].clientID = clientId;
  [GIDSignIn sharedInstance].serverClientID = clientId;
  [GIDSignIn sharedInstance].scopes = scopes;
  [GIDSignIn sharedInstance].shouldFetchBasicProfile = YES;
  [[GIDSignIn sharedInstance] signIn];
}

-(void)webLogInWithClientId:(NSString *)clientId scopes: (NSArray<NSString *> *)scopes
{
  NSURL *authorizationEndpoint = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/v2/auth"];
  NSURL *tokenEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v4/token"];
  // Get the Google redirect scheme from Info.plist.
  NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  __block NSArray *urlSchemes;
  [urlTypes enumerateObjectsUsingBlock:^(id _Nonnull urlType, NSUInteger idx,  BOOL * _Nonnull stop) {
    if ([[urlType objectForKey:@"CFBundleURLName"] isEqualToString:@"OAuthRedirect"]) {
      urlSchemes = [(NSDictionary *)urlType objectForKey:@"CFBundleURLSchemes"];
      *stop = YES;
    }
  }];
  if (!urlSchemes || !urlSchemes.count) {
    _logInReject(ABI19_0_0EXGoogleErrorCode,
                 @"Google sign in error",
                 ABI19_0_0RCTErrorWithMessage(@"No OAuthRedirect bundle url type was configured in this app's Info.plist."));
    _logInResolve = nil;
    _logInReject = nil;
    return;
  }
  NSString *urlScheme = [urlSchemes objectAtIndex:0];
  NSURL *redirect = [NSURL URLWithString:[NSString stringWithFormat:@"%@:/oauthredirect", urlScheme]];

  OIDServiceConfiguration *configuration =
    [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authorizationEndpoint
                                                     tokenEndpoint:tokenEndpoint];

  OIDAuthorizationRequest *request =
    [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                  clientId:clientId
                                                    scopes:scopes
                                               redirectURL:redirect
                                              responseType:OIDResponseTypeCode
                                      additionalParameters:nil];

  OIDAuthStateAuthorizationCallback callback = ^(OIDAuthState *_Nullable authState, NSError *_Nullable error) {
    if (authState) {
      if (authState.isAuthorized) {
        _logInResolve(@{
          @"type": @"success",
          @"accessToken": authState.lastTokenResponse.accessToken,
          @"idToken": authState.lastTokenResponse.idToken ? authState.lastTokenResponse.idToken : [NSNull null],
          @"refreshToken": authState.lastTokenResponse.refreshToken,
          @"serverAuthCode": authState.lastAuthorizationResponse.authorizationCode,
        });
      } else {
        _logInResolve(@{@"type": @"cancel"});
      }
    } else {
      _logInReject(ABI19_0_0EXGoogleErrorCode, @"Google sign in error", error);
    }

    _logInResolve = nil;
    _logInReject = nil;
  };

  id<OIDAuthorizationFlowSession> currentAuthorizationFlow =
    [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                   presentingViewController:ABI19_0_0RCTPresentedViewController()
                                                   callback:callback];
  [_kernelGoogleAuthServiceDelegate googleModule:self didBeginOAuthFlow:currentAuthorizationFlow];
}

-(void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error
{
  if (error != nil) {
    _logInReject(ABI19_0_0EXGoogleErrorCode, @"Google sign in error", error);
  } else {
    _logInResolve(@{
      @"type": @"success",
      @"accessToken": user.authentication.accessToken,
      @"serverAuthCode": user.serverAuthCode,
      @"idToken": user.authentication.idToken ? user.authentication.idToken : [NSNull null],
      @"refreshToken": user.authentication.refreshToken,
      @"user": @{
        @"id": user.userID,
        @"name": user.profile.name,
        @"familyName": user.profile.familyName,
        @"givenName": user.profile.givenName,
        @"email": user.profile.email ? user.profile.email : [NSNull null],
        @"photoUrl": user.profile.hasImage ?
          [[user.profile imageURLWithDimension:96] absoluteString] :
          [NSNull null],
      },
    });
  }

  _logInResolve = nil;
  _logInReject = nil;
}

-(void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController
{
  [ABI19_0_0RCTPresentedViewController() presentViewController:viewController animated:YES completion:nil];
}

-(void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController
{
  [ABI19_0_0RCTPresentedViewController() dismissViewControllerAnimated:YES completion:nil];
}

@end
