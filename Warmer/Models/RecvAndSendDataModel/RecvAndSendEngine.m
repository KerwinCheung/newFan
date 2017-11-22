//
//  RecvAndSendEngine.m
//  lightify
//
//  Created by xtmac on 19/1/16.
//  Copyright © 2016年 xtmac. All rights reserved.
//

#import "RecvAndSendEngine.h"
#import "PacketModel.h"
#import "XLinkExportObject.h"
#import "DeviceEntity.h"
#import "NSTools.h"


#define DATAPACKETHEAD  (0xaaaa)
#define PACKETTAIL  (0x5555)

@implementation RecvAndSendEngine{
    NSMutableArray  *_recvDeviceDataArr;
    NSThread        *_recvThread;
    NSMutableArray  *_packetList;
    
    NSThread        *_timeOutThread;
    NSTimer         *_timeOutTimer;
}

+(RecvAndSendEngine *)shareEngine{
    static dispatch_once_t once;
    static RecvAndSendEngine *recvAndSendEngine;
    dispatch_once(&once, ^{
        recvAndSendEngine = [[RecvAndSendEngine alloc] init];
    });
    return recvAndSendEngine;
}

-(void)initProperty{
    _recvThread = [[NSThread alloc] initWithTarget:self selector:@selector(breakUpPacketThread) object:nil];
    [_recvThread start];
}

-(void)recvData:(NSData *)data withDevice:(DeviceEntity *)device{
    
    if (!_recvThread) {
        [self initProperty];
    }
    NSString *address = [device getMacAddressSimple];
    NSDictionary *oldDataDic = nil;
    for (NSUInteger i = 0; i < _recvDeviceDataArr.count; i++) {
        NSDictionary *dic = _recvDeviceDataArr[i];
        DeviceEntity *temp = [dic objectForKey:@"device"];
        if ([address isEqualToString:[temp getMacAddressSimple]]) {
            oldDataDic = dic;
            break;
        }
    }
    if (!oldDataDic) {
        oldDataDic = @{@"device" : device, @"data" : [NSMutableData data]};
        [_recvDeviceDataArr addObject:oldDataDic];
    }
    NSMutableData *oldData = [oldDataDic objectForKey:@"data"];
    [oldData performSelector:@selector(appendData:) onThread:_recvThread withObject:data waitUntilDone:YES];
//    [_recvData performSelector:@selector(appendData:) onThread:_recvThread withObject:data waitUntilDone:YES];
}

-(void)checkTimeOut{
    
    for (NSInteger i = _packetList.count - 1; i >= 0; i--) {
        NSMutableDictionary *packetDic = _packetList[i];
        NSInteger time = [[packetDic objectForKey:@"time"] integerValue];
        time--;
        if (!time) {
            //超时
            PacketModel *sendPacketModel = [packetDic objectForKey:@"packetModel"];
            PacketModel *tempPacketModel = [[PacketModel alloc] init];
            tempPacketModel.command = sendPacketModel.command | 0b10000000;
//            [ParsingPacketModel parsingPacketWithRecvPacket:tempPacketModel withSendPacket:sendPacketModel withDevice:[packetDic objectForKey:@"device"]];
            [_packetList removeObjectAtIndex:i];
        }else{
            [packetDic setObject:@(time) forKey:@"time"];
        }
    }
    
    if (!_packetList.count) {
        [_timeOutTimer invalidate];
        _timeOutTimer = nil;
    }
    
}

-(PacketModel *)removePacketWithSerial:(unsigned short)serial{
    PacketModel *sendPacketModel = nil;
    for (NSInteger i = _packetList.count - 1; i >= 0; i--) {
        PacketModel *packetModel = [_packetList[i] objectForKey:@"packetModel"];
        if (serial == packetModel.serial) {
            sendPacketModel = packetModel;
            [_packetList removeObjectAtIndex:i];
            break;
        }
    }
    return sendPacketModel;
}

+(void)ignore:(id)_{}

-(void)breakUpPacketThread{
    
    NSLog(@"Recv Data Thread Start");
    
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(ignore:) userInfo:nil repeats:YES];
    
    _recvDeviceDataArr = [NSMutableArray array];
    
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        NSLog(@"%@", _recvDeviceDataArr);
        [self breakUpPacket];
    }
    
    _recvThread = nil;
    _recvDeviceDataArr = nil;
    
    NSLog(@"Recv Data Thread End");
    
}

-(void)breakUpPacket{
    
    unsigned short headIndex;
    
    for (NSDictionary *recvDataDic in _recvDeviceDataArr) {
        NSMutableData *recvData = [recvDataDic objectForKey:@"data"];

        while (recvData.length >= 1) {
            
            NSData *headData = [recvData subdataWithRange:NSMakeRange(0, 1)];
            unsigned char head;
            [headData getBytes:&head length:1];
            if (head == 0xa1) {
                //型号返回
                [recvData replaceBytesInRange:NSMakeRange(0, recvData.length) withBytes:nil length:0];
            }else if(head == 0xa2){
                //状态回复
                
                UInt8 value = 0x00;
                
                NSMutableArray *dataPoint = [NSMutableArray array];
                for (int i =0 ; i<33; i++) {
                    [dataPoint addObject:[NSMutableData dataWithBytes:&value length:1]];
                }
                
                [self getDataPoint:dataPoint RecvData:recvData];

                [recvData replaceBytesInRange:NSMakeRange(0, recvData.length) withBytes:nil length:0];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kQueryDeviceDataPoint object:@{@"result" : @(0), @"device" : [recvDataDic objectForKey:@"device"], @"dataPoint" : dataPoint}];

            }
            
            /*
             //现在的数据没有包头 所以不解析包头 以后有的话再在下面改
             headIndex = 0;
             UInt16 recvDataChar[recvData.length];
             [recvData getBytes:recvDataChar length:recvData.length];
             //找到包头
             while (headIndex < recvData.length && (recvDataChar[headIndex] != DATAPACKETHEAD)) {
             headIndex++;
             }
             
             //如果找不到包头
             if (headIndex >= recvData.length) {
             recvData.length = 0;
             return;
             }
             
             //如果包头不是第一位，把包头前面的数据删掉
             if (headIndex != 0) {
             [recvData replaceBytesInRange:NSMakeRange(0, headIndex) withBytes:nil length:0];
             [recvData getBytes:recvDataChar length:recvData.length];
             }
             
             //获取头
             NSData *headData = [NSMutableData dataWithData:[recvData subdataWithRange:NSMakeRange(0, 1)]];
             UInt16 head;
             [headData getBytes:&head length:1];
             
             if (head == DATAPACKETHEAD) {
             //分析数据
             }else{
             return;
             }
             */
        }

    }
    
    
}

-(void)getDataPoint:(NSMutableArray *)dataPoint RecvData:(NSMutableData *)recvData{
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
    for (int i = 0; i<33; i++) {
        [dataPoint replaceObjectAtIndex:i withObject:[NSMutableData dataWithData:[recvData subdataWithRange:NSMakeRange(i+1, 1)]]];
    }
}

-(void)sendPacket:(PacketModel *)packetModel withDevice:(DeviceEntity *)deviceEntity{
    
    static unsigned short serial = 0;
    
    serial++;
    
    packetModel.serial = serial;
    
    if (!_packetList) {
        _packetList = [NSMutableArray array];
    }
    
    [_packetList addObject:[NSMutableDictionary dictionaryWithDictionary:@{@"device" : deviceEntity, @"time" : @(3), @"packetModel" : packetModel}]];
    
    [self performSelectorOnMainThread:@selector(createTimeOutThread) withObject:nil waitUntilDone:YES];
    
    NSLog(@"%@", [packetModel getData]);
    
    if (deviceEntity.isLANOnline) {
        
        [[XLinkExportObject sharedObject] sendLocalPipeData:deviceEntity andPayload:[packetModel getData]];
        
    }else if (deviceEntity.isWANOnline){
        
        [[XLinkExportObject sharedObject] sendPipeData:deviceEntity andPayload:[packetModel getData]];

    }else{

    }
    
}

-(void)createTimeOutThread{
    if (!_timeOutThread) {
        NSLog(@"startTime_1");
        _timeOutThread = [[NSThread alloc] initWithTarget:self selector:@selector(startTimeOutThread) object:nil];
        [_timeOutThread start];
    }
}

-(void)startTimeOutThread{
    _timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkTimeOut) userInfo:nil repeats:YES];
    NSLog(@"startTime_2");
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        
    }
    _timeOutThread = nil;
}

@end
