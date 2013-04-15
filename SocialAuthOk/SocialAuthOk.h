#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SocialAuthOkAuthType) {
    SocialAuthOkAuthTypeToken = 0,
    SocialAuthOkAuthTypeCode,
};

@interface SocialAuthOkSuccessObject : NSObject

- (NSString *)authToken;
- (NSString *)userID;

@end

@interface SocialAuthOk : NSObject

@property (nonatomic, assign) SocialAuthOkAuthType authType;

+ (instancetype)sharedInstance;

- (void)loginSuccess:(void (^)(SocialAuthOkSuccessObject *))success
             failure:(void (^)(NSError *))failure;

- (void)logoutFinish:(void (^)())finish;

@end