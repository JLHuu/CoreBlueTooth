//
//  JLCentralViewController.m
//  CoreBlueToothDemo
//
//  Created by hujiele on 16/2/25.
//  Copyright © 2016年 JLHuu. All rights reserved.
//  中央设备使用外围设备的数据。中央设备扫描到外围设备后会就会试图建立连接，一旦连接成功就可以使用这些服务和特征

#import "JLCentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define ServiceUUID @"A48D3B5C-353D-4093-8821-DDDEBFEFEA32"
#define CharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC"
@interface JLCentralViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>//中央设备管理器代理,外围设备代理
- (IBAction)Start:(UIButton *)sender;

@end

@implementation JLCentralViewController
{
    CBCentralManager *_CentralManager;// 中央设备管理器
    NSMutableArray *_peripherals;// 发现的外围设备
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _peripherals = [NSMutableArray array];
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
        [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:ServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
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
    if (![_peripherals containsObject:peripheral]) {
        [_peripherals addObject:peripheral];
    }
    // 与外围设备建立连接
    [central connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES}];
    NSLog(@"开始连接外围设备");
}
// 连接上外围设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接上外围设备");
    // 设置外围设备的代理
    peripheral.delegate = self;
    // 外围设备搜寻服务,serviceUUIDs设为nil为搜索全部服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:ServiceUUID]]];
    NSLog(@"外围设备搜寻服务");
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
#pragma mark - CBPeripheralDelegate
// 发现服务调用
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        NSLog(@"发现服务");
        // 找到指定服务，因为我前面已经写了搜寻指定服务，所以services应该有一个我指定的服务。写遍历，只是更好的认识外围设备--服务--特征之间的关系，后面搜索特征亦如此
        for (CBService *service in peripheral.services) {
            if ([service.UUID.UUIDString isEqualToString:ServiceUUID]) {
                NSLog(@"找到指定服务");
                // 寻找服务中的指定特征，characteristicUUIDs=nil则搜寻服务的所有特征
                [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CharacteristicUUID]] forService:service];
            }
        }
    }else{
        NSLog(@"未发现服务:%@",error);
    }
}
// 发现特征调用
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error
{
    if (!error) {
        NSLog(@"发现特征");
        // 查找指定特征
        for (CBCharacteristic *charcter in service.characteristics) {
            if ([charcter.UUID.UUIDString isEqualToString:CharacteristicUUID]) {
                NSLog(@"找到指定特征");
                // 去到指定特征，根据特征值的属性（可通知，可读，可写。。），可以做相应的事
                /**  通知  调用代理peripheral:didUpdateNotificationStateForCharacteristic:error
**/
                [peripheral setNotifyValue:YES forCharacteristic:charcter];
                /**  读  调用代理peripheral:didUpdateValueForCharacteristic:error**/
                [peripheral readValueForCharacteristic:charcter];
                /**  写  调用peripheral:didWriteValueForCharacteristic:error **/
                /*
                 typedef NS_ENUM(NSInteger, CBCharacteristicWriteType) {
                 CBCharacteristicWriteWithResponse = 0,// 写入成功有返回
                 CBCharacteristicWriteWithoutResponse,//写入成功无返回
                 };
                 */
                [peripheral writeValue:[@"CoreBlueTooth Demo" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:charcter type:CBCharacteristicWriteWithResponse];
            }
        }
    }
}
//  外围设备管理器接收到中心设备是否订阅特征值后的回调
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"特征值:%@",characteristic);
}
// 调用readValueForCharacteristic或外围设备更新特征值都会调用
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"特征值:%@",characteristic);
}
//调用writeValue:forCharacteristic:type且type的值为CBCharacteristicWriteWithResponse 后的回调
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

}
@end
