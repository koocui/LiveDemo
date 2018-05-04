//
//  PlcLobbyViewController.m
//  LiveDemo
//
//  Created by 小崔 on 2018/5/4.
//  Copyright © 2018年 CJW. All rights reserved.
//

#import "PlcLobbyViewController.h"
#import "PlcBroadcastRoomViewController.h"
@implementation PlcLobbyViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setUI];
}
-(void)setUI {
    self.navigationItem.titleView = ({
        UILabel * title = [[UILabel alloc]init];
        title.text = @"大厅";
        [title sizeToFit];
        title;
    });
    
    self.navigationItem.rightBarButtonItem = ({
        UIBarButtonItem * button = [[UIBarButtonItem alloc]init];
        button.title = @"开播";
        button.target = self;
        button.action = @selector(onPressedBenginButton:);
        button;
    });
}

-(void)onPressedBenginButton:(id)sender{
    PlcBroadcastRoomViewController * viewC = [[PlcBroadcastRoomViewController alloc]init];
    [self.navigationController pushViewController:viewC animated:YES];
}
@end
