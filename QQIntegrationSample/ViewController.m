//
//  ViewController.m
//  QQIntegrationSample
//
//  Created by Yongping on 10/1/14.
//  Copyright (c) 2014 Kii Corporation. All rights reserved.
//

#import "ViewController.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface ViewController ()<TencentSessionDelegate>
{
    TencentOAuth *tencentOAuth;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginOutButton;

- (IBAction)tapBarButton:(id)sender;
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
    
    if ([barButton.title isEqualToString:@"Login"]) {
        tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"1103266634" andDelegate:self];
        [tencentOAuth authorize:@[@"get_user_info"] inSafari:NO];
    }else{
        [tencentOAuth logout:self];
    }

    
}

-(void)tencentDidLogin{
    if (tencentOAuth.accessToken && 0 != [tencentOAuth.accessToken length])
    {
        //  记录登录用户的OpenID、Token以及过期时间
        NSLog(tencentOAuth.accessToken);
        _loginOutButton.title = @"Logout";
        
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
}


@end
