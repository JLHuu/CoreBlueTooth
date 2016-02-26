/*
 外围设备管理器设置服务，特征 --> 外围设备管理器发出广播 --> 中心设备管理器发现外围设备 --> 找到需要的外围设备 --> 建立连接 --> 外围设备设置代理（这里在JLCentralViewController中设置）--> 外围设备寻找服务，特征这里在JLCentralViewController中设置） --> 外围设备发送通知，写，读等操作请求(这里在JLCentralViewController中设置） --> 外围设备管理器收到请求（didReceive...Requests），并调用代理方法 --> 外围设备管理器响应请求（respondToRequest）--> 外围设备接收到响应的回调（代理方法，这里在JLCentralViewController中设置）
 */
//  JLPeripheralViewController.m
//  CoreBlueToothDemo
//
//  Created by hujiele on 16/2/25.
//  Copyright © 2016年 JLHuu. All rights reserved.
//  外围设备通常用于发布服务、生成数据、保存数据。外围设备发布并广播服务，告诉周围的中央设备它的可用服务和特征
// 中心设备与外围相互交流的流程图

#import "JLPeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define ServiceUUID @"A48D3B5C-353D-4093-8821-DDDEBFEFEA32"
#define CharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC"

@interface JLPeripheralViewController ()<CBPeripheralManagerDelegate>

- (IBAction)Start:(UIButton *)sender;
- (IBAction)Send:(UIButton *)sender;

@end

@implementation JLPeripheralViewController
{
    CBPeripheralManager *_PeripheralManager;// 外围设备管理器
    CBMutableCharacteristic *_PerCharacteristic; // 特征值
    NSMutableArray <CBCentral *>*_centrals;// 存储订阅特征的中心设备
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _centrals = [NSMutableArray array];
}
- (IBAction)Start:(UIButton *)sender {
    _PeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (IBAction)Send:(UIButton *)sender {
    [self _updateCharacteristicValue];
}
#pragma mark - CBPeripheralManagerDelegate
// 外围设备状态发生变化
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"%ld",peripheral.state);
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"蓝牙打开");
        // 添加服务
        [self _addService];
    }else{
        NSLog(@"蓝牙未开启，或不支持");
    }
}
// 添加服务后调用
-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        NSLog(@"添加服务成功");
        // 服务添加后开始广播
        [peripheral startAdvertising:@{CBAdvertisementDataLocalNameKey:@"XIAOLE's Iphone"}];
    }else{
        NSLog(@"添加服务失败error：%@",error);
    }
}
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (!error) {
        NSLog(@"服务启动");
    }else{
        NSLog(@"服务启动失败:%@",error);
    }
}
// 中心设备订阅特征后调用
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"中心设备订阅特征central:%@,characteristic:%@",central,characteristic);
    if (central) {
        // 保存中心设备
        [_centrals addObject:central];
    }
}
// 中心设备取消订阅特征
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"中心设备取消订阅特征:central%@,characteristic:%@",central,characteristic);
}
// 接收到外围设备的Write请求
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(CBATTRequest *)request{
    NSLog(@"didReceiveWriteRequests");
    // 响应请求,也可以不响应
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}
// 接收到外围设备的Read请求
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest");
    // 响应
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dic{
    NSLog(@"willRestoreState");
}
// 再次更新特征时调用
-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"ReadyToUpdateSubscribers");
}
#pragma mark - -
- (void)_addService
{
    NSLog(@"添加服务");
    // 特征，这里我只写一个通知的特征
    _PerCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
    // 特征还可以包含很多描述，这里我就不写了，关系就是service--
    // 创建服务
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:ServiceUUID] primary:YES];
    // 设置服务的特征
    [service setCharacteristics:@[_PerCharacteristic]];
    // 外围设备添加服务
    [_PeripheralManager addService:service];
}

- (void)_updateCharacteristicValue
{
    NSLog(@"更新特征值");
    // 更新特征值
    NSString *str = [@"特征值:" stringByAppendingString:[NSString stringWithFormat:@"%@",[NSDate date]]];
    [_PeripheralManager updateValue:[str dataUsingEncoding:NSUTF8StringEncoding]  forCharacteristic:_PerCharacteristic onSubscribedCentrals:_centrals];
}
@end
