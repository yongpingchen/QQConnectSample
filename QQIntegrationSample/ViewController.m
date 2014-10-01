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
    NSString *accessToken;
    NSString *openID;
    NSDate *expirationDate;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginOutButton;
@property (weak, nonatomic) IBOutlet UIButton *requestUserInfoButton;

- (IBAction)tapBarButton:(id)sender;
- (IBAction)tapRequestUserInfo:(id)sender;
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
    NSDictionary *parameters = @{@"access_token":accessToken,
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

-(void)tencentDidLogin{
    if (tencentOAuth.accessToken && 0 != [tencentOAuth.accessToken length])
    {
        // can get appid, accesstoken and expiereddate
        _loginOutButton.title = @"Logout";
        _requestUserInfoButton.enabled = true;
        accessToken = tencentOAuth.accessToken;
        openID = tencentOAuth.openId;
        expirationDate = tencentOAuth.expirationDate;
        
        NSLog(@"accessToken:%@, openID:%@, expirationDate:%@",accessToken,openID,expirationDate);
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


@end
