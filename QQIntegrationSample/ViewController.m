//
//  ViewController.m
//  QQIntegrationSample
//
//  Created by Yongping on 10/1/14.
//  Copyright (c) 2014 Kii Corporation. All rights reserved.
//

#import "ViewController.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import <AFNetworking/AFNetworking.h>

//refer http://wiki.open.qq.com/wiki/mobile/%E5%85%AC%E5%85%B1%E8%BF%94%E5%9B%9E%E7%A0%81%E8%AF%B4%E6%98%8E
typedef NS_ENUM(NSInteger, QQAPIReturnCode){
    //QQAPI connected successfully
    QQAPIConnectSuccess                             = 0,
    //request without response_type parameter or with illegal response_type parameter
    QQAPIRequestWithWrongResponseType               =100000,
    //reqeust without client_id parameter
    QQAPIRequestWithoutClientID                     =100001,
    //request without client_secret parameter
    QQAPIRequestWithoutClientSecret                 = 100002,
    //request without Authorization in the http header
    QQAPIRequestWithoutAuthorization                = 100003,
    //request without grant_type parameter or with illegal grant_type parameter
    QQAPIRequestWithWroingGrantType                 = 100004,
    //request without code parameter
    QQAPIRequestWithoutCode                         = 100005,
    //request without refresh token parameter
    QQAPIRequestWithoutRefreshToken                 = 100006,
    //request without access token
    QQAPIRequestWithoutAccessToken                  = 100007,
    //the given appid not exist
    QQAPIRequestAppIDNotExist                       = 100008,
    //client_secret(appkey) illegal
    QQAPIRequestWithIllegalClientSecret             = 100009,
    //redirect uri illegal
    QQAPIRequestWithIllegalRedirectURI              = 100010,
    //the app is not public
    QQAPIRequestedAPPNotPublic                      = 100011,
    //method of http request is not POST
    QQAPIRequestNotPost                             = 100012,
    //illegal access token
    QQAPIRequestWithIllegalAccessToken              = 100013,
    //requested access token is expired
    QQAPIRequestWithExpiredAccessToken              = 100014,
    //requested access token is abolished
    QQAPIRequestWithAbolishedAccessToken            = 100015,
    //verify access token failed
    QQAPIAccessTokenVerifiedFailed                  = 100016,
    //request appid failed
    QQAPIRequestAppIDFailed                         = 100017,
    //request code failed
    QQAPIRequestCodeFailed                          = 100018,
    //faild to get access token by code
    QQAPIRequestGetAccessTokenByCodeFailed          = 100019,
    //code is reused
    QQAPICodeReused                                 = 100020,
    //request access token failed
    QQAPIRequestAccessTokenFailed                   = 100021,
    //request refresh token failed
    QQAPIRequestRefreshTokenFailed                  = 100022,
    //request access list of given app failed
    QQAPIRequestAppAccessListFailed                 = 100023,
    //request access list of given open id to given app failed
    QQAPIRequestAccessListOfGivenOpenIDToAppIDFailed = 100024,
    //got all information of api and groupt
    QQAPIRequestAllInformationOfAPIANDGroup         = 100025,
    //authorize user to given app failed
    QQAPIAuthorizeUserToGivenAppFailed              = 100026,
    //authorize a timing to given user for a given app
    QQAPIAuthorizeTimingToUserFailed                = 100027,
    //request without which parameter
    QQAPIRequestWithoutWhichParameter               = 100028,
    //wrong http request
    QQAPIWroingHttpRequest                          = 100029,
    //user not authorize the api or remove the authorization of the api
    QQAPIWithoutAuthorizationFromUser               = 100030,
    //the app without the authority of the api
    QQAPIAPPWithoutAuthorizationOfAPI               = 100031,

} ;

@interface ViewController ()<TencentSessionDelegate>
{
    TencentOAuth *tencentOAuth;
    NSString *_accessToken;
    NSString *openID;
    NSDate *expirationDate;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginOutButton;
@property (weak, nonatomic) IBOutlet UIButton *requestUserInfoButton;
@property (weak, nonatomic) IBOutlet UITextView *responseView;

- (IBAction)tapBarButton:(id)sender;
- (IBAction)tapRequestUserInfo:(id)sender;
- (IBAction)tapVerifyAccessToken:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapBarButton:(id)sender{
    
    UIBarButtonItem *barButton = (UIBarButtonItem *)sender;
    
    if ([barButton.title isEqualToString:@"Login"]) { //tap login button
        
        //request login with app id
        tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"1103266634" andDelegate:self];
        [tencentOAuth authorize:@[@"get_simple_userinfo"] inSafari:NO];
        
    }else{//tap logout button
        [tencentOAuth logout:self];
    }

}

//after login and get the access token, code can request user info
- (IBAction)tapRequestUserInfo:(id)sender {
    [self getUserProfile];
    
}

- (IBAction)tapVerifyAccessToken:(id)sender {
    [self verifyAccessToken:_accessToken appID:@"1103266634"];
}

-(void)tencentDidLogin{
    if (tencentOAuth.accessToken && 0 != [tencentOAuth.accessToken length])
    {
        // can get appid, accesstoken and expiereddate
        _loginOutButton.title = @"Logout";
        _requestUserInfoButton.enabled = true;
        _accessToken = tencentOAuth.accessToken;
        openID = tencentOAuth.openId;
        expirationDate = tencentOAuth.expirationDate;
        
        NSLog(@"accessToken:%@, openID:%@, expirationDate:%@",_accessToken,openID,expirationDate);
        
        //verify access token
        [self verifyAccessToken:_accessToken appID:@"1103266634"];
    }
    else
    {
        NSLog(@"login failed, no access token returned");
    }
}

-(void)tencentDidNotLogin:(BOOL)cancelled
{
    NSLog(@"did not login");
}

-(void)tencentDidNotNetWork
{
    NSLog(@"no network available");
}

-(void)tencentDidLogout{
    NSLog(@"Did logout");
    _loginOutButton.title = @"Login";
    _requestUserInfoButton.enabled = false;
}

/**
 *  Request user profile after getting access token and open id
 */
-(void)getUserProfile{
    
    //1. GET request user profile from the api http://wiki.open.qq.com/wiki/mobile/get_simple_userinfo
    NSDictionary *parameters = @{@"access_token":_accessToken,
                                 @"oauth_consumer_key":@"1103266634",
                                 @"openid":openID, @"format":@"json"};//response data format can be xml
    
    NSError *error;
    NSMutableURLRequest *request =[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"https://graph.qq.com/user/get_simple_userinfo" parameters:parameters error:&error];
    
    //Add your request object to an AFHTTPRequestOperation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation,
       id responseObject) {
         
         NSLog(@"response after request:%@",operation.responseString);
         [_responseView setText:operation.responseString];
         //2. parse the response
         NSError *error;
         NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:operation.responseData options:NSJSONReadingMutableLeaves error:&error];
         if (!error) {
             //3. check the return code, if 0 then user profile successfully get or failed
             NSInteger retNumber = [[responseDict objectForKey:@"ret"] integerValue];
             switch (retNumber) {
                 case QQAPIConnectSuccess:
                     //get user profile informations
                     break;
                 default://otherwise connect failed
                     //output the error message
                     NSLog(@"failed to get user profile: %@",[responseDict objectForKey:@"msg"]);
                     break;
             }
             
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"error:%@",error.description);
         
     }];
    
    [operation start];

}

/**
 *  Verify access token by calling the QQ openAPI for getting openid under OAuth2.0
 *  http://wiki.connect.qq.com/%E8%8E%B7%E5%8F%96%E7%94%A8%E6%88%B7openid_oauth2-0
 *  @param accessToken accessToken gotten after user login by QQ account
 *  @param appID       after develoepr register an app on QQ developer portal
 *
 */
-(void)verifyAccessToken: (NSString *)accessToken appID:(NSString *)appID
{
    
    //1. GET request openid api https://graph.qq.com/oauth2.0/me?access_token=YOUR_ACCESS_TOKEN , access token as parameter
    NSDictionary *parameters = @{@"access_token":_accessToken};
    NSError *error;
    NSMutableURLRequest *request =[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"https://graph.qq.com/oauth2.0/me" parameters:parameters error:&error];
    
    //Add your request object to an AFHTTPRequestOperation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation,
       id responseObject) {
         //2. a callback string will return like: callback( {"client_id":"1103266634","openid":"304348DB949394F422CECD5AE27004BA"} );
         //if error happend will be like: callback( {"error":100016,"error_description":"access token check failed"} );
         NSLog(@"callback string:%@",operation.responseString);
         
         //3. parse the callback string
         NSDictionary *responseDict = [self parseCallBackPackage:operation.responseString];
         
         //4. if access token is illegal, error will be contained, or app id and open id will be returned
         if ([responseDict objectForKey:@"error"]) {
             NSLog(@"%@:%@",[responseDict objectForKey:@"error"], [responseDict objectForKey:@"error_description"]);
         }else{
             NSLog(@"app id:%@, open id:%@",[responseDict objectForKey:@"client_id"], [responseDict objectForKey:@"openid"]);
         }
         
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"error:%@",error.description);
         
     }];
    
    [operation start];


}
/**
 *  parse a callback string and extract the content to dictionary
 *  assume a callback string is: callback( {"client_id":"1103266634","openid":"304348DB949394F422CECD5AE27004BA"} );
 *  the parsed result will be a dictionary with keyvalue pars: "client_id":"1103266634", "openid":"304348DB949394F422CECD5AE27004BA"
 *  @param callbackString a callback string to be parsed
 *
 *  @return a parsed result in the dictionary
 */
-(NSDictionary *)parseCallBackPackage: (NSString *)callbackString{
   
    NSRange rangeOfCallback = [callbackString rangeOfString:@"callback("];
    if (rangeOfCallback.location == NSNotFound) {
        return nil;
    }else{
        //replace the header of "callback("
        NSString *string1 = [callbackString stringByReplacingCharactersInRange:rangeOfCallback withString:@""];
        
        NSRange rangeOfCallbackEnding = [string1 rangeOfString:@");"];
        if (rangeOfCallbackEnding.location == NSNotFound) {
            return nil;
        }else{
            //replace the ");" at the end
            NSString *resultString = [string1 stringByReplacingCharactersInRange:rangeOfCallbackEnding withString:@""];
            NSError *error;
            NSDictionary *parsedResult = [NSJSONSerialization JSONObjectWithData:[resultString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
            if (error) {
                return nil;
            }else{
                return parsedResult;
            }
        }
    }
}


@end
