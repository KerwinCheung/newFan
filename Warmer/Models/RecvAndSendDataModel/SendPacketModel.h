//
//  SendPacketModel.h
//  lightify
//
//  Created by xtmac on 22/1/16.
//  Copyright © 2016年 xtmac. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DeviceEntity, DeviceModel, ActionModel;


typedef enum : unsigned char {
    SwitchStatusOFF,
    SwitchStatusON
}SwitchStatus;

@interface SendPacketModel : NSObject

//查询设备状态
+(void)queryDeviceDataPoint:(DeviceEntity *)device;

/**
 *  控制设备
 *  @param sendData 发送的数据
 *  @param cmd      命令字
 *  @param device   要控制的设备
 */
+(void)controlDevice:(DeviceEntity *)device withSendData:(NSData *)sendData Command:(unsigned char)cmd;

+(void)controlDeviceTiming:(DeviceEntity *)device withHourData:(NSData *)hourData MinuteData:(NSData *)minuteData Command:(unsigned char)cmd;

+(BOOL)isSend;

@end
