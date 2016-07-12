//
//  EUExBluetoothLE.m
//  EUExBluetoothLE
//
//  Created by CeriNo on 15/6/12.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import "EUExBluetoothLE.h"
#import "uexBLEInstance.h"
@interface EUExBluetoothLE()

@property(nonatomic,weak)uexBLEInstance *BLE;

@end




@implementation EUExBluetoothLE


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        
    }
    return self;
}


- (void)clean{
}
- (void)dealloc{
    [self clean];
}


- (void)init:(NSMutableArray *)inArgumrnts{
    self.BLE = [uexBLEInstance sharedInstance];

}

- (void)scanDevice:(NSMutableArray *)inArgumrnts{

    ACArgsUnpack(NSArray *services) = inArgumrnts;
    [self.BLE scanDevice:services];
}


- (void)stopScanDevice:(NSMutableArray *)inArgumrnts{
    [self.BLE stopScanDevice];
}

- (void)connect:(NSMutableArray *)inArgumrnts{
    
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *UUID = stringArg(info[@"address"]);
    if (UUID) {
        [self.BLE connect:UUID];
    }

}

- (void)disconnect:(NSMutableArray *)inArgumrnts{
    [self.BLE disconnect];

}
- (void)searchForCharacteristic:(NSMutableArray *)inArgumrnts{
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *UUID = stringArg(info[uexBLEServiceKey]);
    if (UUID) {
        [self.BLE searchForCharacteristic:UUID];
    }
}

- (void)searchForDescriptor:(NSMutableArray *)inArgumrnts{
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    if (!serviceUUID || !characteristicUUID) {
        return;
    }
    [self.BLE searchForDescriptor:serviceUUID characteristic:characteristicUUID];
 
}
- (void)readCharacteristic:(NSMutableArray *)inArgumrnts{
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    if (!serviceUUID || !characteristicUUID) {
        return;
    }
    [self.BLE readCharacteristic:characteristicUUID inService:serviceUUID];
}
- (void)writeCharacteristic:(NSMutableArray *)inArgumrnts{
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    NSString *dataStr = stringArg(info[uexBLEValue]);
    if (!serviceUUID || !characteristicUUID || !dataStr) {
        return;
    }
    [self.BLE writeCharacteristic:characteristicUUID inService:serviceUUID withDataString:dataStr];
}

- (void)readDescriptor:(NSMutableArray *)inArgumrnts{
    
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    NSString *descriptorUUID = stringArg(info[uexBLEDescriptorKey]);
    if (!serviceUUID || !characteristicUUID || !descriptorUUID) {
        return;
    }
    [self.BLE readDescriptor:descriptorUUID inCharacteristic:characteristicUUID inService:serviceUUID];

    
}
- (void)writeDescriptor:(NSMutableArray *)inArgumrnts{
    ACArgsUnpack(NSDictionary *info) = inArgumrnts;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    NSString *descriptorUUID = stringArg(info[uexBLEDescriptorKey]);
    NSString *dataStr = stringArg(info[uexBLEValue]);
    if (!serviceUUID || !characteristicUUID || !descriptorUUID || !dataStr) {
        return;
    }
    [self.BLE writeDescriptor:descriptorUUID inCharacteristic:characteristicUUID inService:serviceUUID dataString:dataStr];
    
}


- (void)readRemoteRssi:(NSMutableArray *)inArguments{
    [self.BLE readRSSI];
}

- (void)setCharacteristicNotification:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *serviceUUID = stringArg(info[uexBLEServiceKey]);
    NSString *characteristicUUID = stringArg(info[uexBLECharacteristicKey]);
    NSNumber *enableNum = numberArg(info[@"enable"]);
    if (!serviceUUID || !characteristicUUID || !enableNum) {
        return;
    }
    [self.BLE setNotifyEnable:enableNum.boolValue forCharacteristic:characteristicUUID inService:serviceUUID];
    
}

@end
