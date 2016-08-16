//
//  EUExBluetoothLE.m
//  EUExBluetoothLE
//
//  Created by CeriNo on 15/6/12.
//  Copyright (c) 2015年 AppCan. All rights reserved.
//

#import "EUExBluetoothLE.h"
#import "EUtility.h"
#import "uexBLEInstance.h"
@interface EUExBluetoothLE()
@property(nonatomic,weak)uexBLEInstance *BLE;
@end




@implementation EUExBluetoothLE
-(id)initWithBrwView:(EBrowserView *)eInBrwView
{
    self = [super initWithBrwView:eInBrwView];
    if (self) {
        
        
    }
    return self;
}


-(void)clean{
    _BLE.callback=nil;
}
-(void)dealloc{
    [self clean];
}


-(void)init:(NSMutableArray *)inArgumrnts{
    _BLE=[uexBLEInstance sharedInstance];
    _BLE.callback=self.meBrwView;
}

-(void)scanDevice:(NSMutableArray *)inArgumrnts{
    NSArray *services=nil;
    if([inArgumrnts count]>0){
        id info =[self getDataFromJson:inArgumrnts[0]];
        if([info isKindOfClass:[NSArray class]]) services=info;
            
        
    }
    [_BLE scanDevice:services];
}


-(void)stopScanDevice:(NSMutableArray *)inArgumrnts{
    [_BLE stopScanDevice];
}

-(void)connect:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if([info isKindOfClass:[NSDictionary class]]&&[info objectForKey:@"address"]){
        [_BLE connect:[info objectForKey:@"address"]];
    }
}

-(void)disconnect:(NSMutableArray *)inArgumrnts{
    [_BLE disconnect];

}
-(void)searchForCharacteristic:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    [_BLE searchForCharacteristic:sUUID];

}

-(void)searchForDescriptor:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    NSString *cUUID=[info objectForKey:uexBLECharacteristicKey];
    if(!cUUID)return;
    [_BLE searchForDescriptor:sUUID characteristic:cUUID];
 
}
-(void)readCharacteristic:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    NSString *cUUID=[info objectForKey:uexBLECharacteristicKey];
    if(!cUUID)return;
    [_BLE readCharacteristic:cUUID inService:sUUID];
}
-(void)writeCharacteristic:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    NSString *cUUID=[info objectForKey:uexBLECharacteristicKey];
    if(!cUUID)return;
    NSString *value=[info objectForKey:uexBLEValue];
    if(!value)return;
    [_BLE writeCharacteristic:cUUID inService:sUUID withDataString:value];
}

-(void)readDescriptor:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    NSString *cUUID=[info objectForKey:uexBLECharacteristicKey];
    if(!cUUID)return;
    NSString *dUUID=[info objectForKey:uexBLEDescripterKey];
    if(!dUUID)return;
    [_BLE readDescriptor:dUUID inCharacteristic:cUUID inService:sUUID];
    
}
-(void)writeDescriptor:(NSMutableArray *)inArgumrnts{
    if([inArgumrnts count]<1) return;
    id info =[self getDataFromJson:inArgumrnts[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *sUUID=[info objectForKey:uexBLEServiceKey];
    if(!sUUID)return;
    NSString *cUUID=[info objectForKey:uexBLECharacteristicKey];
    if(!cUUID)return;
    NSString *dUUID=[info objectForKey:uexBLEDescripterKey];
    if(!dUUID)return;
    NSString *value=[info objectForKey:uexBLEValue];
    if(!value)return;
    [_BLE writeDescriptor:dUUID inCharacteristic:cUUID inService:sUUID dataString:value];
    
}


- (void)readRemoteRssi:(NSMutableArray *)inArguments{
    [self.BLE readRSSI];
}

- (void)setCharacteristicNotification:(NSMutableArray *)inArguments{
    if([inArguments count]<1) return;
    id info =[self getDataFromJson:inArguments[0]];
    if(![info isKindOfClass:[NSDictionary class]])return;
    NSString *serviceUUID = info[uexBLEServiceKey];
    NSString *characteristicUUID = info[uexBLECharacteristicKey];
    NSNumber *enableNum = info[@"enable"];
    if (!serviceUUID || !characteristicUUID || !enableNum) {
        return;
    }
    [self.BLE setNotifyEnable:enableNum.boolValue forCharacteristic:characteristicUUID inService:serviceUUID];
    
}


#pragma mark - Private Method

- (id)getDataFromJson:(NSString *)jsonStr{
    
    NSError *error = nil;
    
    
    
    NSData *jsonData= [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    
    if (jsonObject != nil && error == nil){
        
        return jsonObject;
    }else{
        
        // 解析錯誤
        
        return nil;
    }
    
}




@end
