//
//  SendPacketModel.m
//  lightify
//
//  Created by xtmac on 22/1/16.
//  Copyright © 2016年 xtmac. All rights reserved.
//

#import "SendPacketModel.h"
#import "PacketModel.h"
#import "DeviceEntity.h"
#import "DeviceModel.h"
#import "RecvAndSendEngine.h"

@implementation SendPacketModel

+(void)queryDeviceDataPoint:(DeviceEntity *)device{
    PacketModel *packetModel = [[PacketModel alloc] init];
    packetModel.command = 0xca;
    
    NSMutableData *data = [NSMutableData data];

    unsigned char cmd = 0x02;
    [data appendBytes:&cmd length:1];
    
    unsigned char Value = 0x00;
    [data appendBytes:&Value length:1];

    packetModel.data = [NSData dataWithData:data];
    
    [[RecvAndSendEngine shareEngine] sendPacket:packetModel withDevice:device];
}

+(void)controlDevice:(DeviceEntity *)device withSendData:(NSData *)sendData Command:(unsigned char)cmd{
    /*           控制命令
     功能         命令字                  参数                 备注
     型号查询     0x01(length_l=0x07)     0x00
     状态查询     0x02(length_l=0x07)     0x00
     开关机      0x03(length_l=0x07)     0=关，1=开
     童锁        0x04(length_l=0x07)     0=关，1=开
     Pm2.5设置	0x05(length_l=0x08)     Byte0=Pm2.5高字节   0~999
     Byte1=Pm2.5低字节
     新风设置     0x06(length_l=0x07)    0=关 1~12  步长为1
     排风设置     0x07(length_l=0x07)    0=关 1~12  步长为1
     模式	     0x08(length_l=0x07)	0=手动，1=自动，2=静音
     加热         0x09(length_l=0x07)	0=关，1=开
     负离子        0x0a(length_l=0x07)	0=关，1=开
     杀菌         0x0b(length_l=0x07)	0=关，1=开
     加湿         0x0c(length_l=0x07)	0=关，1=开
     湿度设定      0x0d(length_l=0x07)	5~95  步长为5
     除霜         0x0e(length_l=0x07)	0=关，1=开
     定时开        0x0f(length_l=0x08)	Byte0=小时	0-23	时间为=00：00则为定时开关闭
     Byte1=分钟	0-59
     定时关        0x10(length_l=0x08)	Byte0=小时	0-23	时间为=00：00则为定时关关闭
     Byte1=分钟	0-59
     维护1复位	  0x11(length_l=0x07)	0=无操作，1=复位
     维护2复位	  0x12(length_l=0x07)	0=无操作，1=复位
     维护3复位	  0x13(length_l=0x07)	0=无操作，1=复位
     维护4复位	  0x14(length_l=0x07)	0=无操作，1=复位
     维护1时间设定	  0x15(length_l=0x07)	1~199  步长为1	实际为5-995天，参数值放大5倍
     维护2时间设定	  0x16(length_l=0x07)	1~199  步长为1	实际为5-995天，参数值放大5倍
     */
    PacketModel *packetModel = [[PacketModel alloc] init];
    packetModel.command = 0xc5;
    
    NSMutableData *data = [NSMutableData data];

    [data appendBytes:&cmd length:1];

    [data appendBytes:sendData.bytes length:sendData.length];
    
    
    packetModel.data = [NSData dataWithData:data];
    
    [[RecvAndSendEngine shareEngine] sendPacket:packetModel withDevice:device];
}

+(void)controlDeviceTiming:(DeviceEntity *)device withHourData:(NSData *)hourData MinuteData:(NSData *)minuteData Command:(unsigned char)cmd{
    /*           控制命令
     定时开        0x0f(length_l=0x08)	Byte0=小时	0-23	时间为=00：00则为定时开关闭
     Byte1=分钟	0-59
     定时关        0x10(length_l=0x08)	Byte0=小时	0-23	时间为=00：00则为定时关关闭
     Byte1=分钟	0-59
     */
    PacketModel *packetModel = [[PacketModel alloc] init];
    packetModel.command = 0xc5;
    
    NSMutableData *data = [NSMutableData data];
    
    [data appendBytes:&cmd length:1];
    
    [data appendBytes:hourData.bytes length:hourData.length];
    [data appendBytes:minuteData.bytes length:minuteData.length];
    
    
    packetModel.data = [NSData dataWithData:data];
    
    [[RecvAndSendEngine shareEngine] sendPacket:packetModel withDevice:device];
}

+(BOOL)isSend{
    static NSTimeInterval time = 0;
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    BOOL isSend = false;
    if (curTime - time >= SendPacketTime) {
        time = curTime;
        isSend = true;
    }
    return isSend;
}

@end
