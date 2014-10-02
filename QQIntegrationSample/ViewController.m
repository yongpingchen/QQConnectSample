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

@interface ViewController ()<TencentSessionDelegate>
{
    TencentOAuth *tencentOAuth;
    NSString *_accessToken;
    NSString *openID;
    NSDate *expirationDate;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginOutButton;
@property (weak, nonatomic) IBOutlet UIButton *requestUserInfoButton;

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
        [tencentOAuth authorize:@[@"get_user_info"] inSafari:NO];
        
    }else{//tap logout button
        [tencentOAuth logout:self];
    }

}

//after login and get the access token, code can request user info
- (IBAction)tapRequestUserInfo:(id)sender {
    
    //refer http://wiki.open.qq.com/wiki/mobile/get_simple_userinfo
    NSDictionary *parameters = @{@"access_token":_accessToken,
                                 @"oauth_consumer_key":@"1103266634",
                                 @"openid":openID, @"format":@"json"};
    
    NSError *error;
    NSMutableURLRequest *request =[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"https://graph.qq.com/user/get_simple_userinfo" parameters:parameters error:&error];

    //Add your request object to an AFHTTPRequestOperation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation,
       id responseObject) {
         NSLog(@"response after request:%@",operation.responseString);
        
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"error:%@",error.description);
         
     }];
    
    [operation start];
    
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
 *  Verify access token by calling the QQ openAPI for getting openid under OAuth2.0
 *  http://wiki.connect.qq.com/%E8%8E%B7%E5%8F%96%E7%94%A8%E6%88%B7openid_oauth2-0
 *  @param accessToken accessToken gotten after user login by QQ account
 *  @param appID       after develoepr register an app on QQ developer portal
 *
 *  @return if verify successfully reture true, or return false
 */
-(void)verifyAccessToken: (NSString *)accessToken appID:(NSString *)appID
{
    
    //1. request openid from the api https://graph.qq.com/oauth2.0/me?access_token=YOUR_ACCESS_TOKEN by the access token
    NSDictionary *parameters = @{@"access_token":_accessToken};
    NSError *error;
    NSMutableURLRequest *request =[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"https://graph.qq.com/oauth2.0/me" parameters:parameters error:&error];
    
    //Add your request object to an AFHTTPRequestOperation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:
     ^(AFHTTPRequestOperation *operation,
       id responseObject) {
         //2. a callback string will return like: callback( {"client_id":"1103266634","openid":"304348DB949394F422CECD5AE27004BA"} );
         //or error like: callback( {"error":100016,"error_description":"access token check failed"} );
         NSLog(@"callback string:%@",operation.responseString);
         
         //3. parse the callback string
         NSDictionary *responseDict = [self parseCallBackPackage:operation.responseString];
         
         //4. if error response
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
        NSString *string1 = [callbackString stringByReplacingCharactersInRange:rangeOfCallback withString:@""];
        
        NSRange rangeOfCallbackEnding = [string1 rangeOfString:@");"];
        if (rangeOfCallbackEnding.location == NSNotFound) {
            return nil;
        }else{
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
