//
//  JLCentralViewController.m
//  CoreBlueToothDemo
//
//  Created by hujiele on 16/2/25.
//  Copyright © 2016年 JLHuu. All rights reserved.
//  中央设备使用外围设备的数据。中央设备扫描到外围设备后会就会试图建立连接，一旦连接成功就可以使用这些服务和特征

#import "JLCentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface JLCentralViewController ()<CBCentralManagerDelegate>//中央设备代理
- (IBAction)Start:(UIButton *)sender;

@end

@implementation JLCentralViewController
{
    CBCentralManager *_CentralManager;// 中央设备管理器
    CBPeripheral *_peripheral;// 外围设备
}
- (void)viewDidLoad {
    [super viewDidLoad];
 
}

- (IBAction)Start:(UIButton *)sender {
    // 设置代理为self，并将代理回调放在主线程中
    _CentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
#pragma mark - CBCentralManagerDelegate
// 必须实现的代理方法，中央设备管理器的状态发生改变时调用
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    // 在这里判断CBCentralManager的stutas，并作出相应处理
    /*
     stutas为枚举值，有以下几种
     typedef NS_ENUM(NSInteger, CBCentralManagerState) {
     CBCentralManagerStateUnknown = 0,
     CBCentralManagerStateResetting,
     CBCentralManagerStateUnsupported,
     CBCentralManagerStateUnauthorized,
     CBCentralManagerStatePoweredOff,
     CBCentralManagerStatePoweredOn,
     };
     */
    NSLog(@"%ld",central.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙设备已打开");
        // 扫描外围设备,serviceUUIDs设为nil会返回所有能扫描到的设备
        [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        NSLog(@"正在扫描...");
    }else{
        NSLog(@"蓝牙未开启，或不支持");
    }
}
-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
    NSLog(@"RestoreState%@",dict);
}
// 发现外围设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"发现外围设备");
    // 停止扫描
    [central stopScan];
    NSLog(@"扫描停止");
    // 与外围设备建立连接
    [central connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES}];
}
// 连接上外围设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接上外围设备");
}
// 丢失与外围设备的连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"丢失连接");
}
// 连接外围设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败,%@",error);
}

@end
