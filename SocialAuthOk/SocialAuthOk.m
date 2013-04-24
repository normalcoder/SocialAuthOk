#import "SocialAuthOk.h"
#import "Odnoklassniki.h"
#import "AppOpenUrlNotification.h"

@interface SocialAuthOkSuccessObject ()
@property (strong, nonatomic) NSString * authToken;
@property (strong, nonatomic) NSString * userID;
@end

bool working;

@implementation SocialAuthOkSuccessObject

+ (id)socialAuthSuccessObjectOkWithAuthToken:(NSString *)authToken
                                      userID:(NSString *)userID {
    return [[self alloc] initWithAuthToken:authToken
                                    userID:userID];
}

- (id)initWithAuthToken:(NSString *)authToken
                 userID:(NSString *)userID {
    if ((self = [super init])) {
        self.authToken = authToken;
        self.userID = userID;
    }
    return self;
}

@end

@interface SocialAuthOk () <OKSessionDelegate>

@property (strong, nonatomic) Odnoklassniki * api;
@property (strong, nonatomic) void (^success)(SocialAuthOkSuccessObject *);
@property (strong, nonatomic) void (^failure)(NSError *);

@end

@implementation SocialAuthOk

+ (instancetype)sharedInstance {
    static dispatch_once_t pred;
    static id instance;
    dispatch_once(&pred, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationDidBecomeActive:)
         name:UIApplicationDidBecomeActiveNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationWillTerminate:)
         name:UIApplicationWillTerminateNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationDidOpenUrl:)
         name:AppOpenUrlNotification
         object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)loginSuccess:(void (^)(SocialAuthOkSuccessObject *))success
             failure:(void (^)(NSError *))failure {
    self.success = success;
    self.failure = failure;
    working = YES;
    self.api =
    [[Odnoklassniki alloc]
     initWithAppId:[[NSBundle mainBundle].infoDictionary objectForKey:@"OdnoklassnikiAppID"]
     andAppSecret:[[NSBundle mainBundle].infoDictionary objectForKey:@"OdnoklassnikiAppSecret"]
     andAppKey:[[NSBundle mainBundle].infoDictionary objectForKey:@"OdnoklassnikiAppKey"]
     andDelegate:self];
    [self.api authorize:[NSArray arrayWithObjects:@"VALUABLE ACCESS", @"SET STATUS", nil]];
}

- (void)logoutFinish:(void (^)())finish {
    [self.api logout];
}

#pragma mark -

- (void)okDidLogin {
    assert(self.authType != SocialAuthOkAuthTypeCode);
    
    self.success
    ([SocialAuthOkSuccessObject
      socialAuthSuccessObjectOkWithAuthToken:self.api.session.accessToken
      userID:nil]);
}

- (BOOL)okShouldContinueLoginWithCode:(NSString *)code {
    if (self.authType == SocialAuthOkAuthTypeCode) {
        self.success
        ([SocialAuthOkSuccessObject
          socialAuthSuccessObjectOkWithAuthToken:code
          userID:nil]);
        return NO;
    } else {
        return YES;
    }
}

- (void)okDidNotLogin:(BOOL)canceled {
}

- (void)okDidNotLoginWithError:(NSError *)error {
    self.failure(error);
}

- (void)okDidExtendToken:(NSString *)accessToken {
	[self okDidLogin];
}

- (void)okDidNotExtendToken:(NSError *)error {
    self.failure(error);
}

- (void)okDidLogout {
}

/*** Request delegate ***/
- (void)request:(OKRequest *)request didLoad:(id)result {
}

- (void)request:(OKRequest *)request didFailWithError:(NSError *)error {
}

#pragma mark -

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (working)
        self.failure(nil);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
}

- (void)applicationDidOpenUrl:(NSNotification *)notification {
    working = NO;
	[OKSession.activeSession handleOpenURL:
     [[notification userInfo] objectForKey:AppOpenUrlNotificationUserInfoKey]];
}

@end