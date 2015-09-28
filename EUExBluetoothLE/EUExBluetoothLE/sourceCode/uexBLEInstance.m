//
//  uexBLEInstance.m
//  EUExBluetoothLE
//
//  Created by Cerino on 15/7/22.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import "uexBLEInstance.h"
#import "EUtility.h"
#import "JSON.h"





@interface uexBLEInstance()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong) CBCentralManager *BLEMgr;
@property(nonatomic,strong) NSMutableDictionary *discoveredPeripherals;
@property(nonatomic,strong)CBPeripheral* currentPeripheral;
@property(nonatomic,strong)NSString * readingCharacteristic;
@end

NSString *const uexBLEServiceKey=@"serviceUUID";
NSString *const uexBLECharacteristicKey=@"characteristicUUID";
NSString *const uexBLEDescripterKey=@"descriptorUUID";
NSString *const uexBLEValue=@"value";


@implementation uexBLEInstance
+ (instancetype)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static uexBLEInstance *sharedObject = nil;
    dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
        
        
    });
    return sharedObject;
}


-(instancetype)init{
    self=[super init];
    if(self){
        _BLEMgr=[[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredPeripherals=[NSMutableDictionary dictionary];
        self.readingCharacteristic=nil;
    }
    return self;
}
-(BOOL)isConnected:(CBPeripheral*)peripheral{
    if(peripheral.state == CBPeripheralStateConnected){
        NSLog(@"YES");
        return YES;
        
    }
    return NO;
}

//

#pragma mark - Public Method
-(void)scanDevice:(NSArray *)UUIDs{
    [self.discoveredPeripherals removeAllObjects];
    NSMutableArray *CBUUIDs=[NSMutableArray array];
    for(int i=0;i<[UUIDs count];i++){
        NSString* UUID=UUIDs[i];
        [CBUUIDs addObject:[CBUUID UUIDWithString:UUID]];
    }
    [_BLEMgr scanForPeripheralsWithServices:CBUUIDs options:nil];
}
-(void)stopScanDevice{
    [_BLEMgr stopScan];
}
-(void)connect:(NSString *)identifier{
    if([_discoveredPeripherals objectForKey:identifier]&&[[_discoveredPeripherals objectForKey:identifier] isKindOfClass:[CBPeripheral class]]){
        CBPeripheral *peripheral =[_discoveredPeripherals objectForKey:identifier];
        if(![self isConnected:peripheral]){
            [_BLEMgr connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
            [self log:@"start connection"];
            //开一个定时器监控连接超时的情况
            //connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(connectTimeout:) userInfo:peripheral repeats:NO];
        }
    }
}
-(void)disconnect{
    if(_currentPeripheral){
        if([self isConnected:_currentPeripheral]){
            [_BLEMgr cancelPeripheralConnection:_currentPeripheral];
            [self log:@"cancel connection"];
        }
        _currentPeripheral=nil;
    }
    
    
};



-(void)searchForCharacteristic:(NSString*)serviceUUID{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    CBService * service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(service){
        [self.currentPeripheral discoverCharacteristics:nil forService:service];
    }else{
        [self log:@"invalid service UUID"];
    }
    
}
-(void)searchForDescriptor:(NSString*)serviceUUID characteristic:(NSString*)characteristicUUID{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    
    CBService * service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(!service){
        [self log:@"invalid service UUID"];
        return;
    }
    CBCharacteristic *characteristic=[self searchCharacteristicInService:service ByUUID:characteristicUUID];
    if(!characteristic){
        [self log:@"invalid characteristic UUID"];
        return;
    }
    [self.currentPeripheral discoverDescriptorsForCharacteristic:characteristic];
}
-(void)readCharacteristic:(NSString*)characteristicUUID
                inService:(NSString *)serviceUUID{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    CBService* service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(!service){
        [self log:@"cannot find service"];
        return;
    }
    CBCharacteristic *characteristic=[self searchCharacteristicInService:service ByUUID:characteristicUUID];
    if(!characteristic) {
        [self log:@"cannot find characteristic"];
        return;
    }
    self.readingCharacteristic=characteristic.UUID.UUIDString;
    [self.currentPeripheral readValueForCharacteristic:characteristic];
    
}

-(void)writeCharacteristic:(NSString*)characteristicUUID
                 inService:(NSString *)serviceUUID
            withDataString:(NSString*)dataStr{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    CBService* service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(!service){
        [self log:@"cannot find service"];
        return;
    }
    CBCharacteristic *characteristic=[self searchCharacteristicInService:service ByUUID:characteristicUUID];
    if(!characteristic) {
        [self log:@"cannot find characteristic"];
        return;
    }
    CBCharacteristicWriteType type=CBCharacteristicWriteWithResponse;
    if(!(characteristic.properties & CBCharacteristicPropertyWrite)&&(characteristic.properties & CBCharacteristicWriteWithoutResponse)){
        type=CBCharacteristicWriteWithoutResponse;
    }
    [self.currentPeripheral writeValue:[self base64Decode:dataStr] forCharacteristic:characteristic type:type];
}

-(void)readDescriptor:(NSString*)descriptorUUID
     inCharacteristic:(NSString*)characteristicUUID
            inService:(NSString*)serviceUUID{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    CBService* service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(!service){
        [self log:@"cannot find service"];
        return;
    }
    CBCharacteristic *characteristic=[self searchCharacteristicInService:service ByUUID:characteristicUUID];
    if(!characteristic) {
        [self log:@"cannot find characteristic"];
        return;
    }
    CBDescriptor *descriptor =[self searchDescriptorInCharacteristic:characteristic ByUUID:descriptorUUID];
    if(!descriptor){
        [self log:@"cannot find descriptor"];
        return;
    }
    [self.currentPeripheral readValueForDescriptor:descriptor];

}

-(void)writeDescriptor:(NSString*)descriptorUUID
     inCharacteristic:(NSString*)characteristicUUID
             inService:(NSString*)serviceUUID
            dataString:(NSString *)dataStr{
    if(!self.currentPeripheral||![self isConnected:self.currentPeripheral]){
        [self log:@"not connect to a peripheral"];
        return;
    }
    CBService* service=[self searchServiceInPeripheral:self.currentPeripheral ByUUID:serviceUUID];
    if(!service){
        [self log:@"cannot find service"];
        return;
    }
    CBCharacteristic *characteristic=[self searchCharacteristicInService:service ByUUID:characteristicUUID];
    if(!characteristic) {
        [self log:@"cannot find characteristic"];
        return;
    }
    CBDescriptor *descriptor =[self searchDescriptorInCharacteristic:characteristic ByUUID:descriptorUUID];
    if(!descriptor){
        [self log:@"cannot find descriptor"];
        return;
    }
    [self.currentPeripheral writeValue:[self base64Decode:dataStr] forDescriptor:descriptor];
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    if( peripheral.identifier == NULL  ) return; //  ios6 added
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];

    if (!error) {
        [self log:[NSString stringWithFormat:@"====%@\n",peripheral.name]];
        [self log:[NSString stringWithFormat:@"=========== %ld of service for UUID %@ ===========\n",(long)[peripheral.services count],peripheral.identifier.UUIDString]];
        NSMutableArray *services=[NSMutableArray array];
        for (CBService *service in peripheral.services){
            [self log:[NSString stringWithFormat:@"Service found with UUID: %@\n", service.UUID]];
            [services addObject:service.UUID.UUIDString];
            //[peripheral discoverCharacteristics:nil forService:service];

        }
        [dict setValue:services forKey:@"services"];
    }else {
        [self log:[NSString stringWithFormat:@"discovering services failed for error:%@",[error localizedDescription]]];
    }
    [self callBackJsonWithName:@"cbConnect" Object:dict];
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:service.UUID.UUIDString forKey:uexBLEServiceKey];
    if(error){
        [self log:[NSString stringWithFormat:@"discovering characteristics failed for error:%@",[error localizedDescription]]];
    }else{
        NSMutableArray *characteristics=[NSMutableArray array];
        for(CBCharacteristic *characteristic in service.characteristics){
        [characteristics addObject:[self parseCharacteristics:characteristic]];
           [self.currentPeripheral setNotifyValue:YES forCharacteristic:characteristic];
            
        }
        [dict setValue:characteristics forKey:@"characteristics"];
    }
    [self callBackJsonWithName:@"cbSearchForCharacteristic" Object:dict];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:characteristic.UUID.UUIDString forKey:uexBLECharacteristicKey];
    [dict setValue:characteristic.service.UUID.UUIDString forKey:uexBLEServiceKey];
    if(error){
        [self log:[NSString stringWithFormat:@"discovering descriptors failed for error:%@",[error localizedDescription]]];
    }else{
        NSMutableArray *descriptors=[NSMutableArray array];
        for(CBDescriptor *descriptor in characteristic.descriptors){
            [descriptors addObject:[self parseDescriptor:descriptor]];
          
            
        }
        [dict setValue:descriptors forKey:@"descriptors"];

    }
    [self callBackJsonWithName:@"cbSearchForDescriptors" Object:dict];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if([self.readingCharacteristic isEqual:characteristic.UUID.UUIDString]) {
        NSMutableDictionary *cbReadCharacteristic=[NSMutableDictionary dictionary];
        NSNumber *result=@0;
        if(error) result=@1;
        [cbReadCharacteristic setValue:result forKey:@"result"];
        [cbReadCharacteristic setValue:[self parseCharacteristics:characteristic] forKey:@"data"];
        [self callBackJsonWithName:@"cbReadCharacteristic" Object:cbReadCharacteristic];
        self.readingCharacteristic=nil;
    }
    if(error) [self log:[NSString stringWithFormat:@"error:%@",[error localizedDescription]]];
    [self callBackJsonWithName:@"onCharacteristicChanged" Object:[self parseCharacteristics:characteristic]];
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSMutableDictionary *cbWriteCharacteristic=[NSMutableDictionary dictionary];
    NSNumber *result=@0;
    if(error){
        result=@1;
        [self log:[NSString stringWithFormat:@"write characteristic %@ failed:%@",characteristic.UUID.UUIDString,[error localizedDescription]]];
    }
    [cbWriteCharacteristic setValue:result forKey:@"result"];
    [cbWriteCharacteristic setValue:[self parseCharacteristics:characteristic] forKey:@"data"];
    [self callBackJsonWithName:@"cbWriteCharacteristic" Object:cbWriteCharacteristic];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSMutableDictionary *cbReadDescriptor=[NSMutableDictionary dictionary];
    NSNumber *result=@0;
    if(error){
        result=@1;
        [self log:[NSString stringWithFormat:@"read descriptor %@ failed:%@",descriptor.UUID.UUIDString,[error localizedDescription]]];
    }
    [cbReadDescriptor setValue:result forKey:@"result"];
    [cbReadDescriptor setValue:[self parseDescriptor:descriptor] forKey:@"data"];
    [self callBackJsonWithName:@"cbReadDescriptor" Object:cbReadDescriptor];
    self.readingCharacteristic=nil;
  
}
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSMutableDictionary *cbWriteDescriptor=[NSMutableDictionary dictionary];
    NSNumber *result=@0;
    if(error){
        result=@1;
        [self log:[NSString stringWithFormat:@"write descriptor %@ failed:%@",descriptor.UUID.UUIDString,[error localizedDescription]]];
    }
    [cbWriteDescriptor setValue:result forKey:@"result"];
    [cbWriteDescriptor setValue:[self parseDescriptor:descriptor] forKey:@"data"];
    [self callBackJsonWithName:@"cbWriteDescriptor" Object:cbWriteDescriptor];

}
#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSString *stateStr=nil;
    NSNumber *resultCode = @1;
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            stateStr=@"CentralManagerStatePoweredOff";
            break;
        case CBCentralManagerStatePoweredOn:
            stateStr=@"CentralManagerStatePoweredOn";
            resultCode=@0;
            break;
        case CBCentralManagerStateResetting:
            stateStr=@"CentralManagerStateResetting";
            break;
        case CBCentralManagerStateUnauthorized:
            stateStr=@"CentralManagerStateUnauthorized";
            break;
        case CBCentralManagerStateUnknown:
            stateStr=@"CentralManagerStateUnknown";
            break;
        case CBCentralManagerStateUnsupported:
            stateStr=@"CentralManagerStateUnsupported";
            break;

    }
    NSMutableDictionary *dict =[NSMutableDictionary dictionary];
    [dict setValue:resultCode forKey:@"resultCode:"];
    [dict setValue:stateStr forKey:@"info"];
    [self callBackJsonWithName:@"cbInit" Object:dict];
    [self log:[NSString stringWithFormat:@"BLEMgr status change to %@",stateStr]];
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    peripheral.delegate=self;
    self.currentPeripheral=peripheral;
    [_BLEMgr stopScan];
    [_currentPeripheral discoverServices:nil];
    [self callBackJsonWithName:@"onConnectionStateChange" Object:@{@"resultCode":@0}];


    
}
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI  {
    [self log:[NSString stringWithFormat:@"discover a peripheral name:%@  address:%@ RSSI:%@",peripheral.name,peripheral.identifier.UUIDString,RSSI]];
    if(![[_discoveredPeripherals allValues] containsObject:peripheral]){
        [_discoveredPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];//发现新设备
        
        NSMutableDictionary *onLeScan=[NSMutableDictionary dictionary];
        [onLeScan setValue:peripheral.identifier.UUIDString forKey:@"address"];
        [onLeScan setValue:peripheral.name forKey:@"name"];
        [self callBackJsonWithName:@"onLeScan" Object:onLeScan];
    }
    

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self log:[NSString stringWithFormat:@"BLEMgr fail to connect peripheral for error:%@",[error localizedDescription]]];
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
     if(error){
         [self log:[NSString stringWithFormat:@"BLEMgr disconnected for error:%@",[error localizedDescription]]];
         if([_BLEMgr respondsToSelector:@selector(retrievePeripheralsWithIdentifiers:)]&&self.currentPeripheral){
             [_BLEMgr retrievePeripheralsWithIdentifiers:@[self.currentPeripheral.identifier]];
             [self log:@"try to retrieve peripgeral"];
         }

     }else{
         [self log:[NSString stringWithFormat:@"BLEMgr disconnected"]];
              }
    [self callBackJsonWithName:@"onConnectionStateChange" Object:@{@"resultCode":@1}];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    if([peripherals count]>0){
        [self log:@"retrieving peripgeral successfully"];
        for(CBPeripheral *peripheral in peripherals){
            [_BLEMgr connectPeripheral:peripheral options:nil];
            [self log:[NSString stringWithFormat:@"try to reconnect peripheral:%@",peripheral.identifier.UUIDString]];

        }
    }
    
    
}


#pragma mark - Debug

-(void)log:(NSString *)str{
    NSLog(@"%@",str);
    [self callBackJsonWithName:@"log" Object:str];
}


#pragma mark - Callback


-(void)callBackJsonWithName:(NSString *)name Object:(id)obj{
    const NSString *kPluginName = @"uexBluetoothLE";
    NSString *result=[obj JSONFragment];
    NSString *jsStr = [NSString stringWithFormat:@"if(%@.%@ != null){%@.%@('%@');}",kPluginName,name,kPluginName,name,result];
    
    if(self.callback){
        [EUtility brwView:self.callback evaluateScript:jsStr];

    }else{
        [EUtility evaluatingJavaScriptInRootWnd:jsStr];
    }
    
}

#pragma mark - Parse

-(NSDictionary*)parseDescriptor:(CBDescriptor*)descriptor{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [self log:[NSString stringWithFormat:@"parse descriptor:%@",descriptor.UUID.UUIDString]];
    [dict setValue:descriptor.UUID.UUIDString forKey:@"UUID"];
    [dict setValue:descriptor.characteristic.UUID.UUIDString forKey:uexBLECharacteristicKey];
    [dict setValue:descriptor.characteristic.service.UUID.UUIDString forKey:uexBLEServiceKey];
    NSString* valueStr=nil;
    id value=descriptor.value;
    if([value isKindOfClass:[NSNumber class]]){
        valueStr=[value stringValue];
        [dict setValue:@(NO) forKey:@"needDecode"];
    }
    if([value isKindOfClass:[NSString class]]){
      
        valueStr=(NSString *)value;
        [dict setValue:@(NO) forKey:@"needDecode"];
    }
    if([value isKindOfClass:[NSData class]]){
        valueStr=[self base64Encode:(NSData*)value];
        [dict setValue:@(YES) forKey:@"needDecode"];
    }
    [dict setValue:valueStr forKey:uexBLEValue];
    
    return dict;
    
}


-(NSDictionary *)parseCharacteristics:(CBCharacteristic *)characteristic{
    [self log:[NSString stringWithFormat:@"parse characteristic:%@",characteristic.UUID.UUIDString]];
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:@(characteristic.properties) forKey:@"permissions"];
    if([characteristic isKindOfClass:[CBMutableCharacteristic class]]){
        CBMutableCharacteristic * mCharacteristic=(CBMutableCharacteristic*)characteristic;
        [dict setValue:@(mCharacteristic.permissions) forKey:@"writeType"];
    }

    [dict setValue:characteristic.service.UUID.UUIDString forKey:uexBLEServiceKey];
    [dict setValue:characteristic.UUID.UUIDString forKey:@"UUID"];
    NSString *valueStr=[self base64Encode:characteristic.value];
    [dict setValue:valueStr forKey:uexBLEValue];
    NSMutableArray *descriptorList=[NSMutableArray array];
    for(CBDescriptor *descriptor in characteristic.descriptors){
        [descriptorList addObject:[self parseDescriptor:descriptor]];
    }
    [dict setValue:descriptorList forKey:@"descriptors"];
    
    return dict;
}

-(NSDictionary *)parseService:(CBService *)service{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [self log:[NSString stringWithFormat:@"parse service:%@",service.UUID.UUIDString]];
    [dict setValue:service.UUID.UUIDString forKey:@"UUID"];
    NSMutableArray *characteristicList=[NSMutableArray array];
    for(CBCharacteristic *characteristic in service.characteristics){
        [characteristicList addObject:[self parseCharacteristics:characteristic]];
    }
    [dict setValue:characteristicList forKey:@"characteristics"];
    
    
    return dict;
}

#pragma mark - Base64 Encode & Decode
-(NSString *)base64Encode:(NSData*)data{
    
    
    //NSData *base64Data=[data base64EncodedDataWithOptions:0];
    NSString *resultStr= [data base64EncodedStringWithOptions:0];
    return resultStr;
}

-(NSData *)base64Decode:(NSString *)dataStr{
    NSData *data=[[NSData alloc] initWithBase64EncodedString:dataStr options:0];
    return data;
}

#pragma mark - Search


-(CBService *)searchServiceInPeripheral:(CBPeripheral*)peripheral
                                 ByUUID:(NSString*)uuid
{
    if(!peripheral||![self isConnected:peripheral]) return nil;
    for (CBService *service in peripheral.services){
        
        if([service.UUID.UUIDString isEqual:uuid]){
            return service;
        }
    }
    return nil;
}




-(CBCharacteristic *)searchCharacteristicInService:(CBService*)service
                                            ByUUID:(NSString*)uuid{
    if(!service)return nil;
    for(CBCharacteristic* characteristic in service.characteristics){
        if([characteristic.UUID.UUIDString isEqual:uuid]){
            return characteristic;
        }
    }
    return nil;
}

-(CBDescriptor *)searchDescriptorInCharacteristic:(CBCharacteristic*)characteristic
                                        ByUUID:(NSString*)uuid{
    if(!characteristic)return nil;
    for(CBDescriptor *descriptor in characteristic.descriptors){
        if([descriptor.UUID.UUIDString isEqual:uuid]){
            return descriptor;
        }
    }
    return nil;
}

@end
