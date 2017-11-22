//
//  DeviceModel.m
//  lightify
//
//  Created by xtmac on 20/1/16.
//  Copyright © 2016年 xtmac. All rights reserved.
//

#import "DeviceModel.h"
#import "DeviceEntity.h"

@implementation DeviceModel

-(instancetype)init{
    if (self = [super init]) {
        _actionList = [NSMutableArray array];
        _timedTaskIDList = [NSMutableArray array];
        _uploadTime = @"0";
        _isSubscription = @(0);
        _isSelect = @(0);
        _isExpDevice = @(0);
        [self initDataPoint];
    }
    return self;
}

+(DeviceModel *)creatExpDevice{
    
    DeviceModel *deviceModel = [[DeviceModel alloc]init];

    deviceModel.isExpDevice = @(1);
    deviceModel.device = [[DeviceEntity alloc]init];
    deviceModel.name = @"新风系统-演示机";
    [deviceModel setDefaultDataPoint];
    return deviceModel;
    
}

-(instancetype)initWithDictionary:(NSDictionary *)dic{
    
    if (self = [self init]) {
        _device = [[DeviceEntity alloc] initWithDictionary:[dic objectForKey:@"deviceEntity"]];
        _accessKey = [dic objectForKey:@"accessKey"];
        _isSubscription = [dic objectForKey:@"isSubscription"];
        _isSelect = [dic objectForKey:@"isSelect"];
        _isExpDevice = [dic objectForKey:@"isExpDevice"];
        _name = [dic objectForKey:@"name"];
        
        NSDictionary *propertyDic = [dic objectForKey:@"Property"];
        
        if ([propertyDic.allKeys containsObject:@"uploadTime"]) {
            _uploadTime = [propertyDic objectForKey:@"uploadTime"];
        }else{
            _uploadTime = @"0";
        }
        
//        _name = [propertyDic objectForKey:@"name"];
        
        
        _curFirmwareVersion = [propertyDic[@"curFirmwareVersion"] integerValue];
        _newestFirmwareVersion = [propertyDic[@"newestFirmwareVersion"] integerValue];
        
        [self initDataPoint];
    }
    return self;
    
}

-(void)initDataPoint{
    /*
     a2
     00 Byte0：开机状态	0=关，1=开
     00 Byte1：童锁状态	0=关，1=开
     00 Byte2：Pm2.5设定高字节	0-999
     00 Byte3：Pm2.5设定低字节
     00 Byte4：新风	0=关 1~12  步长为1
     00 Byte5：排风	0=关 1~12  步长为1
     00 Byte6：模式	0=手动，1=自动，2=静音
     00 Byte7：加热	0=关，1=开
     01 Byte8：负离子	0=关，1=开
     00 Byte9：杀菌	0=关，1=开
     00 Byte10：加湿	0=关，1=开
     00 Byte11：湿度设定	5~95  步长为5
     00 Byte12：除霜	0=关，1=开
     00 Byte13：定时开小时	0-23
     00 Byte14：定时开分钟	0-59
     00 Byte15：定时关小时	0-23
     00 Byte16：定时关分钟	0-59
     00 Byte17：维护1提示	0=无提示，1=提示触发
     00 Byte18：维护2提示	0=无提示，1=提示触发
     00 Byte19：维护3提示	0=无提示，1=提示触发
     00 Byte20：维护4提示	0=无提示，1=提示触发
     00 Byte21：维护1时间设定值	1~199  步长为1
     00 Byte22：维护2时间：设定值	1~199  步长为1
     00 Byte23：室内温度值	0~99
     00 Byte24：室内湿度值	0~99
     00 Byte25：室外温度值	0~99
     00 Byte26：室外湿度值	0~9
     00 Byte27：Pm2.5高字节	0~999
     05 Byte28：Pm2.5低字节
     05 Byte29：CO2显示高字节	0-9999
     e4 Byte30：CO2显示低字节
     00 Byte31：Esp显示	0=无异常，1=异常
     00 Byte32：缺水提示	0=无提示，1=缺水
     */
    UInt8 value = 0x00;

    _dataPoint = [NSMutableArray array];
    for (int i =0 ; i<33; i++) {
        [_dataPoint addObject:[NSMutableData dataWithBytes:&value length:1]];
    }
    
}

-(void)setDefaultDataPoint{
    UInt8 setTemp = 0x01;
    [_dataPoint[0] replaceBytesInRange:NSMakeRange(0, 1) withBytes:&setTemp length:1];
    
}

-(NSDictionary *)getDictionary{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    if (_device) [dic setObject:[_device getDictionaryFormat] forKey:@"deviceEntity"];
    if (_accessKey) [dic setObject:_accessKey forKey:@"accessKey"];
    if (_isSubscription) [dic setObject:_isSubscription forKey:@"isSubscription"];

    if (_isSelect) [dic setObject:_isSelect forKey:@"isSelect"];
    
    if (_isExpDevice) [dic setObject:_isExpDevice forKey:@"isExpDevice"];
    
    if (_name) [dic setObject:_name forKey:@"name"];
    
    
    NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
    [propertyDic setObject:_uploadTime forKey:@"uploadTime"];
//    if (_name) [propertyDic setObject:_name forKey:@"name"];
    if (_curFirmwareVersion) {
        [propertyDic setObject:@(_curFirmwareVersion) forKey:@"curFirmwareVersion"];
    }
    if (_newestFirmwareVersion) {
        [propertyDic setObject:@(_newestFirmwareVersion) forKey:@"newestFirmwareVersion"];
    }
    [dic setObject:propertyDic forKey:@"Property"];
    
    return dic;
}

-(NSString *)name{
    if (!_name.length) {
        if (_isExpDevice.intValue == 1) {
            _name = @"新风系统-演示机";
        }else{
            NSString *macStr = [_device getMacAddressSimple];
            NSString *nameStr = [macStr substringWithRange:NSMakeRange(macStr.length-4, 4)];
            _name =[NSString stringWithFormat:@"新风系统-%@",nameStr];
        }
    }
    return _name;
}

-(NSNumber *)getValidTimedTaskID{
    NSUInteger timedTaskID = 0;
    BOOL isHas;
    do {
        timedTaskID++;
        isHas = false;
        for (NSNumber *tid in _timedTaskIDList) {
            if ([tid isEqualToNumber:@(timedTaskID)]) {
                isHas = YES;
                break;
            }
        }
    } while (isHas);
    return @(timedTaskID);
}

@end
