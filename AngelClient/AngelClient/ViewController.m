//
//  ViewController.m
//  AngelClient
//
//  Created by lby on 16/12/29.
//  Copyright © 2016年 lby. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>

// 客户端socket
@property (strong, nonatomic) GCDAsyncSocket *clientSocket;
// 主机
@property (weak, nonatomic) IBOutlet UITextField *addressTextF;
// 端口号
@property (weak, nonatomic) IBOutlet UITextField *portTextF;
// 信息展示
@property (weak, nonatomic) IBOutlet UITextField *messageTextF;
// 信息展示
@property (weak, nonatomic) IBOutlet UITextView *showMessageTextV;
@property (nonatomic, assign) BOOL connected;
 // 计时器
@property (nonatomic, strong) NSTimer *connectTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// 添加计时器
- (void)addTimer
{
     // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
     // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}
// 开始连接
- (IBAction)connectAction:(id)sender
{
    // 链接服务器
    if (!self.connected)
    {
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSLog(@"开始连接%@",self.clientSocket);
        
        NSError *error = nil;
    self.connected = [self.clientSocket connectToHost:self.addressTextF.text onPort:[self.portTextF.text integerValue] viaInterface:nil withTimeout:-1 error:&error];
        
        if(self.connected)
        {
            [self showMessageWithStr:@"客户端尝试连接"];
        }
        else
        {
            self.connected = NO;
            [self showMessageWithStr:@"客户端未创建连接"];
        }
    }
    else
    {
        [self showMessageWithStr:@"与服务器连接已建立"];
    }
}

// 发送数据
- (IBAction)sendMessageAction:(id)sender
{
    NSData *data = [self.messageTextF.text dataUsingEncoding:NSUTF8StringEncoding];
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

#pragma mark - GCDAsyncSocketDelegate

/**
 连接主机对应端口号

 @param sock 客户端socket
 @param host 主机
 @param port 端口号
 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
//    NSLog(@"连接主机对应端口%@", sock);
    [self showMessageWithStr:@"链接成功"];
    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@-------端口: %d", host,port]];
    
    // 连上马上发一条信息给服务器
//    float version = [[UIDevice currentDevice] systemVersion].floatValue;
//    NSString *firstMes = [NSString stringWithFormat:@"123%f",version];
//    NSData  *data = [firstMes dataUsingEncoding:NSUTF8StringEncoding];
//    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
    
    // 连接成功开启定时器
    [self addTimer];
    // 连接后,可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
    self.connected = YES;
}

// 心跳连接
- (void)longConnectToSocket
{
    // 发送固定格式的数据,指令@"longConnect"
    float version = [[UIDevice currentDevice] systemVersion].floatValue;
    NSString *longConnect = [NSString stringWithFormat:@"123%f",version];
    
    NSData  *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

/**
 读取数据

 @param sock 客户端socket
 @param data 读取到的数据
 @param tag 当前读取的标记
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:text];
    
    // 读取到服务器数据值后,能再次读取
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

// 信息展示
- (void)showMessageWithStr:(NSString *)str
{
    self.showMessageTextV.text = [self.showMessageTextV.text stringByAppendingFormat:@"%@\n", str];
}

/**
 客户端socket断开

 @param sock 客户端socket
 @param err 错误描述
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
//    NSLog(@"断开的sock:%@",sock);
//    NSLog(@"断开的sock:%@",self.clientSocket);
    [self showMessageWithStr:@"断开连接"];
    self.clientSocket.delegate = nil;
//    [self.clientSocket disconnect];
    self.clientSocket = nil;
    self.connected = NO;
    [self.connectTimer invalidate];
}

@end
