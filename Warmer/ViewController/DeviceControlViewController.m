//
//  DeviceControlViewController.m
//  Warmer
//
//  Created by apple on 2016/12/6.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "DeviceControlViewController.h"
#import "AddDeviceViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#import "SendPacketModel.h"

#import "XLinkExportObject.h"

@interface DeviceControlViewController ()<UIGestureRecognizerDelegate>
{
    NSMutableData *pm25Data;
    NSMutableData *co2Data;
    
    NSMutableArray *hourArr;
    NSMutableArray *minuteArr;
    
    int closeHour,closeMinute,openHour,openMinute;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

//menuBtn
@property (weak, nonatomic) IBOutlet UIButton *menuBtn;
//menuView
@property (weak, nonatomic) IBOutlet UIView *menuView;

@property (weak, nonatomic) IBOutlet UIView *shadowView;

@property (nonatomic, assign) BOOL isLock;//童锁

@property (nonatomic, assign) BOOL isOpen;//设备开机

@property (nonatomic, assign) BOOL isShowMenu;//右上角菜单显示

//中部视图
@property (weak, nonatomic) IBOutlet UIButton *deviceOnBtn;//开机按钮
@property (weak, nonatomic) IBOutlet UILabel *deviceOnBtnLabel;//开机按钮

@property (weak, nonatomic) IBOutlet UIImageView *pm25Img;//pm2.5
@property (weak, nonatomic) IBOutlet UIImageView *pm25ugImg;//ug/m3
@property (weak, nonatomic) IBOutlet UIImageView *xinfengImg;//新风(左边的)
@property (weak, nonatomic) IBOutlet UIImageView *paifengImg;//排风(右边的)
@property (weak, nonatomic) IBOutlet UILabel *pm25Label;//pm2.5数值label

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pm25ViewHeightContant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgHeightContant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pm25LabelContant;

@property (weak, nonatomic) IBOutlet UIButton *tsOffBtn;//童锁关
@property (weak, nonatomic) IBOutlet UIButton *tsOnBtn;//童锁开

//dataViewLabel 四项数据视图
@property (weak, nonatomic) IBOutlet UILabel *inDoorTemp;
@property (weak, nonatomic) IBOutlet UILabel *outDoorTemp;

@property (weak, nonatomic) IBOutlet UILabel *inDoorHumidity;
@property (weak, nonatomic) IBOutlet UILabel *outDoorHumidity;

@property (weak, nonatomic) IBOutlet UILabel *co2Label;
@property (weak, nonatomic) IBOutlet UILabel *useredTime;

//底部view---------------------------
@property (weak, nonatomic) IBOutlet UIView *bottonView;
//功能视图
@property (weak, nonatomic) IBOutlet UIView *functionView;

@property (weak, nonatomic) IBOutlet UISlider *paifengSlider;
@property (weak, nonatomic) IBOutlet UILabel *paifengLabel;

@property (weak, nonatomic) IBOutlet UISlider *xinfengSlider;
@property (weak, nonatomic) IBOutlet UILabel *xinfengLabel;

@property (weak, nonatomic) IBOutlet UISlider *HumiditySlider;
@property (weak, nonatomic) IBOutlet UISwitch *HumiditySwitch;
@property (weak, nonatomic) IBOutlet UILabel *humiditySwitchLabel;

@property (weak, nonatomic) IBOutlet UISwitch *chushuangSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shajunSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fuliziSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *jiareSwitch;

@property (weak, nonatomic) IBOutlet UIButton *jingyinBtn;
@property (weak, nonatomic) IBOutlet UIButton *zidongBtn;
@property (weak, nonatomic) IBOutlet UIButton *shoudongBtn;

//定时视图
@property (weak, nonatomic) IBOutlet UIView *timingView;

@property (weak, nonatomic) IBOutlet UIPickerView *closeTimingHourPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *closeTimingMinPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *openTimingHourPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *openTimingMInutePicker;

//维护视图
@property (weak, nonatomic) IBOutlet UIView *maintainView;

@property (weak, nonatomic) IBOutlet UISlider *maintain1Slider;
@property (weak, nonatomic) IBOutlet UISlider *maintain2Slider;

@property (weak, nonatomic) IBOutlet UILabel *maintain1Label;
@property (weak, nonatomic) IBOutlet UILabel *maintain2Label;

@property (nonatomic,strong) UIAlertController *linkAlc;
@end

@implementation DeviceControlViewController

-(void)viewDidLayoutSubviews{
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!self.deviceModel.device.isConnected) {
        [[XLinkExportObject sharedObject] connectDevice:self.deviceModel.device andAuthKey:self.deviceModel.device.accessKey];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setPickerDataArray];
    
    closeHour = 0;
    closeMinute = 0;
    openHour = 0;
    openMinute = 0;
    
    pm25Data = [NSMutableData data];
    co2Data = [NSMutableData data];
    
    self.jingyinBtn.layer.borderColor = [UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00].CGColor;
    self.zidongBtn.layer.borderColor = [UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00].CGColor;
    self.shoudongBtn.layer.borderColor = [UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00].CGColor;
    
    self.isOpen = NO;
    self.isLock = NO;
    self.isShowMenu = NO;
    
    self.automaticallyAdjustsScrollViewInsets = false;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    //设备数据改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceChange:) name:kDeviceChange object:nil];
    //设备连接状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceStateChange:) name:kOnConnectDevice object:nil];
    
    [self setUpConstant];

    [self performSelectorOnMainThread:@selector(setUI) withObject:nil waitUntilDone:NO];

}

-(void)setUpConstant{
    
    if (MainWidth == 375) {
        //6
        self.pm25ViewHeightContant.constant = 244;
        self.bgHeightContant.constant = 340;
        self.pm25LabelContant.constant = 60;
    }else if (MainWidth > 375){
        //6+
        self.pm25ViewHeightContant.constant = 264;
        self.bgHeightContant.constant = 350;
        self.pm25LabelContant.constant = 65;
    }else if (MainWidth < 375){
        //5
        self.pm25ViewHeightContant.constant = 204;
        self.bgHeightContant.constant = 290;
        self.pm25LabelContant.constant = 40;
    }
    
}

#pragma mark - switchBtnAction 开机
- (IBAction)openDevice:(UIButton *)sender {
    
    if (self.deviceModel.device.isConnected || self.deviceModel.isExpDevice.intValue == 1) {

        self.isOpen = YES;
        self.shadowView.hidden = YES;
        
        UInt8 Status = 0x01;
        [self.deviceModel.dataPoint[0] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[0] Command:0x03];
        
        [self setUI];
    }else{
        
        [[XLinkExportObject sharedObject] connectDevice:self.deviceModel.device andAuthKey:self.deviceModel.device.accessKey];
        
        
        self.linkAlc = [UIAlertController alertControllerWithTitle:nil message:@"正在连接设备" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        }];

        [self.linkAlc addAction:ok];
        
        [self presentViewController:self.linkAlc animated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.linkAlc != nil) {
                [self.linkAlc dismissViewControllerAnimated:YES completion:^{
                    UIAlertController *faultAC = [UIAlertController alertControllerWithTitle:nil message:@"设备连接失败" preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                    }];
                    
                    [faultAC addAction:ok];
                    
                    [self presentViewController:faultAC animated:YES completion:nil];
                }];
                self.linkAlc = nil;
            }
        });
    }
    
    
}
#pragma mark - childLockBtnAction 童锁
-(IBAction)childLockingBtnAtion:(UIButton *)sender{

    UInt8 Status = ((const UInt8 *)_deviceModel.dataPoint[1].bytes)[0];
    
    Status = !Status;
    
    [self.deviceModel.dataPoint[1] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
    
    [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[1] Command:0x04];
    
    [self setUI];

}
#pragma mark - bottonViewAction 底部视图动作
- (IBAction)bottonViewAction:(UIView *)sender {
    
//    self.menuBtn.hidden = YES;
    self.isShowMenu = NO;
    
    switch (sender.tag) {
        case 1:
        {
            //开关
            self.isOpen = NO;
            self.shadowView.hidden = NO;
            
            UInt8 Status = 0x00;
            [self.deviceModel.dataPoint[0] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
            [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[0] Command:0x03];
            
            [self setUI];
        }
            break;
        case 2:
        {
            //功能
            self.functionView.hidden = NO;
            self.menuBtn.userInteractionEnabled = NO;
            self.shadowView.hidden = NO;
            
        }
            break;
        case 3:
        {
            //定时
            self.menuBtn.userInteractionEnabled = NO;
            self.shadowView.hidden = NO;
            self.timingView.hidden = NO;
        }
            break;
        case 4:
        {
            //维护
            self.menuBtn.userInteractionEnabled = NO;
            self.shadowView.hidden = NO;
            self.maintainView.hidden = NO;
        }
            break;
            
        default:
            break;
    }
}

#pragma mark 功能相关
#pragma mark 功能返回
- (IBAction)functionBack:(id)sender {
    self.functionView.hidden = YES;
    self.menuBtn.userInteractionEnabled = YES;
    self.shadowView.hidden = YES;
}

#pragma mark SliderChange 底部视图所有滑块变化
- (IBAction)paifengSliderValeChange:(UISlider *)sender {
    NSLog(@"%f",sender.value);
    
    if (sender == self.paifengSlider) {
        if ((int)sender.value==0) {
            self.paifengLabel.text = [NSString stringWithFormat:@"排风:关"];
            return;
        }
        self.paifengLabel.text = [NSString stringWithFormat:@"排风:%d",(int)sender.value];
        
        UInt8 Status = (int)sender.value;
        [self.deviceModel.dataPoint[5] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[5] Command:0x07];
        
    }else if(sender == self.xinfengSlider){
        if ((int)sender.value==0) {
            self.xinfengLabel.text = [NSString stringWithFormat:@"新风:关"];
            return;
        }
        self.xinfengLabel.text = [NSString stringWithFormat:@"新风:%d",(int)sender.value];
        
        UInt8 Status = (int)sender.value;
        [self.deviceModel.dataPoint[4] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[4] Command:0x06];
        
    }else if (sender == self.HumiditySlider){
        if ((int)sender.value==0) {
            self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(关闭)"];
            return;
        }
        self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(%d%@)",(int)sender.value*5,@"%"];
        
        UInt8 Status = (int)sender.value;
        [self.deviceModel.dataPoint[11] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[11] Command:0x0d];
        
    }else if (sender == self.maintain2Slider){
         self.maintain2Label.text = [NSString stringWithFormat:@"维护2(%d天)",(int)sender.value*5];
        
        UInt8 value = (int)sender.value;
        [self.deviceModel.dataPoint[22] replaceBytesInRange:NSMakeRange(0,1) withBytes:&value length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[22] Command:0x16];
        
        
    }else if (sender == self.maintain1Slider){
         self.maintain1Label.text = [NSString stringWithFormat:@"维护1(%d天)",(int)sender.value*5];
        
        UInt8 value = (int)sender.value;
        [self.deviceModel.dataPoint[21] replaceBytesInRange:NSMakeRange(0,1) withBytes:&value length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[21] Command:0x15];
    }
//    MaintainSlider 维护
    
    
    
    
}

#pragma mark SwitchChange 开关变化
- (IBAction)functionSwitchValueChange:(UISwitch *)sender {
    
    UInt8 Status;
    
    if (sender == self.HumiditySwitch) {
        if (sender.isOn) {
            Status = 0x01;
            self.HumiditySlider.userInteractionEnabled = YES;
            self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(%d%@)",(int)self.HumiditySlider.value,@"%"];
        }else{
            Status = 0x00;
            self.HumiditySlider.userInteractionEnabled = NO;
            self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(关闭)"];
        }
        
        [self.deviceModel.dataPoint[10] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[10] Command:0x0c];
    }else if (sender == self.chushuangSwitch){
        
        if (sender.isOn) {
            Status = 0x01;
        }else{
            Status = 0x00;
        }
        
        [self.deviceModel.dataPoint[12] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[12] Command:0x0e];
        
    }else if (sender == self.shajunSwitch){
        
        if (sender.isOn) {
            Status = 0x01;
        }else{
            Status = 0x00;
        }
        
        [self.deviceModel.dataPoint[9] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[9] Command:0x0b];
        
    }else if (sender == self.fuliziSwitch){
        
        if (sender.isOn) {
            Status = 0x01;
        }else{
            Status = 0x00;
        }
        
        [self.deviceModel.dataPoint[8] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[8] Command:0x0a];
        
    }else if (sender == self.jiareSwitch){
        
        if (sender.isOn) {
            Status = 0x01;
        }else{
            Status = 0x00;
        }
        
        [self.deviceModel.dataPoint[7] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Status length:1];
        [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[7] Command:0x09];
        
    }
    
}

#pragma mark funciton MoedeButtonAction 模式按钮动作
- (IBAction)devieModeBtnAction:(UIButton *)sender {
   
    [self setModeBtnUI:(int)sender.tag];

    UInt8 Value = (int)sender.tag;
    [self.deviceModel.dataPoint[6] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Value length:1];
    [SendPacketModel controlDevice:self.deviceModel.device withSendData:self.deviceModel.dataPoint[6] Command:0x08];
}

-(void)setModeBtnUI:(int)tag{
     //0手动 1自动 2静音
    switch (tag) {
        case 0:
        {
            [self.jingyinBtn setBackgroundColor:[UIColor whiteColor]];
            [self.zidongBtn setBackgroundColor:[UIColor whiteColor]];
            [self.shoudongBtn setBackgroundColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00]];

            [self.jingyinBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.zidongBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.shoudongBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
            
        case 1:
        {
            [self.jingyinBtn setBackgroundColor:[UIColor whiteColor]];
            [self.shoudongBtn setBackgroundColor:[UIColor whiteColor]];
            [self.zidongBtn setBackgroundColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00]];
            
            [self.jingyinBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.shoudongBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.zidongBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
            
        case 2:
        {
            [self.shoudongBtn setBackgroundColor:[UIColor whiteColor]];
            [self.zidongBtn setBackgroundColor:[UIColor whiteColor]];
            [self.jingyinBtn setBackgroundColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00]];
            
            [self.shoudongBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.zidongBtn setTitleColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.89 alpha:1.00] forState:UIControlStateNormal];
            [self.jingyinBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark 定时相关
#pragma mark timingBtnAction 定时按钮动作
- (IBAction)timingAction:(id)sender {
    self.menuBtn.userInteractionEnabled = YES;
    self.shadowView.hidden = YES;
    self.timingView.hidden = YES;
    //启动定时
    NSLog(@"定时关 %d小时 %d分钟",closeHour,closeMinute);
    NSLog(@"定时开 %d小时 %d分钟",openHour,openMinute);
    
    //定时开
    UInt8 openHourData = (const UInt8)openHour;
    UInt8 openMinuteData = (const UInt8)openMinute;
    [self.deviceModel.dataPoint[13] replaceBytesInRange:NSMakeRange(0,1) withBytes:&openHourData length:1];
    [self.deviceModel.dataPoint[14] replaceBytesInRange:NSMakeRange(0,1) withBytes:&openMinuteData length:1];
    [SendPacketModel controlDeviceTiming:self.deviceModel.device withHourData:self.deviceModel.dataPoint[13] MinuteData:self.deviceModel.dataPoint[14] Command:0x0f];
    
    //定时开
    UInt8 closeHourData = (const UInt8)closeHour;
    UInt8 closeminuteData = (const UInt8)closeMinute;
    [self.deviceModel.dataPoint[15] replaceBytesInRange:NSMakeRange(0,1) withBytes:&closeHourData length:1];
     [self.deviceModel.dataPoint[16] replaceBytesInRange:NSMakeRange(0,1) withBytes:&closeminuteData length:1];
    [SendPacketModel controlDeviceTiming:self.deviceModel.device withHourData:self.deviceModel.dataPoint[15] MinuteData:self.deviceModel.dataPoint[16] Command:0x10];
}

- (IBAction)cancleTiming:(id)sender {
    self.menuBtn.userInteractionEnabled = YES;
    self.shadowView.hidden = YES;
    self.timingView.hidden = YES;

}


#pragma mark 维护视图相关
- (IBAction)resetBtnAction:(UIButton *)sender{
    //复位1 tag =1   复位2 tag = 2;
    
//    UInt8 Value = 0x01;
//    [self.deviceModel.dataPoint[11] replaceBytesInRange:NSMakeRange(0,1) withBytes:&Value length:1];
    
    unsigned char cmd;
    
    switch (sender.tag) {
        case 1:
        {
            cmd = 0x11;
        }
            break;
        case 2:
        {
            cmd = 0x12;
        }
            break;
        case 3:
        {
            cmd = 0x13;
        }
            break;
        case 4:
        {
            cmd = 0x14;
        }
            break;
        default:
        {
            cmd = 0x00;
        }
            break;
    }
    NSMutableData *data = [NSMutableData data];
    unsigned char value = 0x01;
    [data appendBytes:&value length:1];
    [SendPacketModel controlDevice:self.deviceModel.device withSendData:data Command:cmd];
}


- (IBAction)cancleMaintain:(id)sender {
    self.menuBtn.userInteractionEnabled = YES;
    self.shadowView.hidden = YES;
    self.maintainView.hidden = YES;
}



#pragma mark - menuBtnAction 右上角菜单函数
- (IBAction)menuBtnAction:(UIButton *)sender {
    NSLog(@"菜单%zd",sender.tag);
    switch (sender.tag) {
        case 1:
        {
            //修改名称
            __weak typeof(self) weakself = self;
            
            UIAlertController *alc = [UIAlertController alertControllerWithTitle:NSLocalStr(@"设备名称") message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [alc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull nameField) {
                nameField.placeholder = @"请输入用户名";
                [[NSNotificationCenter defaultCenter]addObserver:weakself selector:@selector(handleTextFieldDidChanged:) name:UITextFieldTextDidChangeNotification object:nil];
            }];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                UITextField *deviceName = alc.textFields.firstObject;
                
                [[NSNotificationCenter defaultCenter] removeObserver:weakself name:UITextFieldTextDidChangeNotification object:nil];
                
                self.deviceModel.name = deviceName.text;
                
                [DATASOURCE saveUserWithIsUpload:NO];
                
                self.titleLabel.text = self.deviceModel.name;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateDeviceList object:nil];

                
                
                
            }];
            ok.enabled = NO;
            
            UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSNotificationCenter defaultCenter]removeObserver:weakself name:UITextFieldTextDidChangeNotification object:nil];
            }];
            
            [alc addAction:cancle];
            [alc addAction:ok];
            
            [self presentViewController:alc animated:YES completion:nil];
        }
            break;
        case 2:
        {
            //重新配网
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AddDevice" bundle:nil];
            
            AddDeviceViewController *vc =[storyboard instantiateViewControllerWithIdentifier:@"AddDeviceViewController"];
            vc.justLink = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 3:
        {
            //删除设备
            UIAlertController *alc = [UIAlertController alertControllerWithTitle:NSLocalStr(@"删除设备") message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteDevice object:_deviceModel];
                
                [self performSelectorOnMainThread:@selector(goBack:) withObject:nil waitUntilDone:NO];
            }];
            
            UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alc addAction:cancle];
            [alc addAction:ok];
            
            [self presentViewController:alc animated:YES completion:nil];
        }
            break;
        case 4:
        {
            [self menuBtn:_menuBtn];
        }
            break;
            
        default:
            break;
    }
}

- (void)handleTextFieldDidChanged:(NSNotification *)notification{
    
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    
    if (alertController) {
        
        UITextField *login = alertController.textFields.firstObject;
        
        UIAlertAction *okAction = alertController.actions.lastObject;
        
        okAction.enabled = login.text.length > 0;
        
    }
    
}

#pragma mark  - pickview delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.closeTimingHourPicker) {
        return [hourArr count]*10;
    }else if(pickerView == self.closeTimingMinPicker){
        return [minuteArr count]*10;
    }else if (pickerView == self.openTimingHourPicker){
        return [hourArr count]*10;
    }else{
       return [minuteArr count]*10;
    }
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == self.closeTimingHourPicker) {
        NSNumber *hourNum = [hourArr objectAtIndex:(row%[hourArr count])];
        int hour = hourNum.intValue;
        NSString *title = [NSString stringWithFormat:@"%.2d",hour];
        return title;
    }else if(pickerView == self.closeTimingMinPicker){
        NSNumber *minuteNum = [minuteArr objectAtIndex:(row%[minuteArr count])];
        int minute = minuteNum.intValue;
        NSString *title = [NSString stringWithFormat:@"%.2d",minute];
        return title;
    }else  if (pickerView == self.openTimingHourPicker){
        NSNumber *hourNum = [hourArr objectAtIndex:(row%[hourArr count])];
        int hour = hourNum.intValue;
        NSString *title = [NSString stringWithFormat:@"%.2d",hour];
        return title;
    }else{
        NSNumber *minuteNum = [minuteArr objectAtIndex:(row%[minuteArr count])];
        int minute = minuteNum.intValue;
        NSString *title = [NSString stringWithFormat:@"%.2d",minute];
        return title;
    }
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    NSUInteger max = 0;
    NSUInteger base10 = 0;
    if (pickerView == self.closeTimingHourPicker) {
        
        if(component == 0)
        {
            max = [hourArr count]*10;
            base10 = (max/2)-(max/2)%[hourArr count];
            [pickerView selectRow:[pickerView selectedRowInComponent:component]%[hourArr count]+base10 inComponent:component animated:false];
            
            NSNumber *hour = hourArr[row%hourArr.count];
            closeHour = hour.intValue;
            
        }
        
    }else if(pickerView == self.closeTimingMinPicker){
        
        if(component == 0)
        {
            max = [minuteArr count]*10;
            base10 = (max/2)-(max/2)%[minuteArr count];
            [pickerView selectRow:[pickerView selectedRowInComponent:component]%[minuteArr count]+base10 inComponent:component animated:false];
            
            NSNumber *minute = minuteArr[row%minuteArr.count];
            closeMinute = minute.intValue;
        }
        
    }else if(pickerView == self.openTimingHourPicker){
        if(component == 0)
        {
            max = [hourArr count]*10;
            base10 = (max/2)-(max/2)%[hourArr count];
            [pickerView selectRow:[pickerView selectedRowInComponent:component]%[hourArr count]+base10 inComponent:component animated:false];
            
            NSNumber *hour = hourArr[row%hourArr.count];
            openHour = hour.intValue;
            
        }
    }else{
        if(component == 0)
        {
            max = [minuteArr count]*10;
            base10 = (max/2)-(max/2)%[minuteArr count];
            [pickerView selectRow:[pickerView selectedRowInComponent:component]%[minuteArr count]+base10 inComponent:component animated:false];
            
            NSNumber *minute = minuteArr[row%minuteArr.count];
            openMinute = minute.intValue;
        }
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0f, 0.0f, [pickerView rowSizeForComponent:component].width-12, [pickerView rowSizeForComponent:component].height)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    NSString *title;
    if (pickerView == self.closeTimingHourPicker) {
        NSNumber *hourNum = [hourArr objectAtIndex:(row%[hourArr count])];
        int hour = hourNum.intValue;
        title = [NSString stringWithFormat:@"%d",hour];
        
    }else if(pickerView == self.closeTimingMinPicker){
        NSNumber *minuteNum = [minuteArr objectAtIndex:(row%[minuteArr count])];
        int minute = minuteNum.intValue;
        title = [NSString stringWithFormat:@"%.2d",minute];
        
    }else if(pickerView == self.openTimingHourPicker){
        NSNumber *hourNum = [hourArr objectAtIndex:(row%[hourArr count])];
        int hour = hourNum.intValue;
        title = [NSString stringWithFormat:@"%d",hour];
    }else{
        NSNumber *minuteNum = [minuteArr objectAtIndex:(row%[minuteArr count])];
        int minute = minuteNum.intValue;
        title = [NSString stringWithFormat:@"%.2d",minute];
    }
    label.text = title;
    
    return label;
}

-(void)setPickerDataArray{
    hourArr = [NSMutableArray array];
    for (int i = 0; i<24; i++) {
        [hourArr addObject:@(i)];
    }
    [self.closeTimingHourPicker selectRow:hourArr.count inComponent:0 animated:YES];
    [self.openTimingHourPicker selectRow:hourArr.count inComponent:0 animated:YES];
    
    minuteArr = [NSMutableArray array];
    for (int i = 0; i< 60; i++) {
        [minuteArr addObject:@(i)];
    }
    [self.closeTimingMinPicker selectRow:minuteArr.count inComponent:0 animated:YES];
    [self.openTimingMInutePicker selectRow:minuteArr.count inComponent:0 animated:YES];
}

#pragma mark - NavigationBarAction
- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)menuBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (self.menuView.hidden) {

        self.isShowMenu = YES;
        
        self.menuView.hidden = NO;

        if (self.isOpen) {
            self.shadowView.hidden = NO;
        }
        

    }else{
        
        self.isShowMenu = NO;
        
        if (!self.isLock && self.isOpen) {
            self.shadowView.hidden = YES;
            
        }
        self.menuView.hidden = YES;
        ;
    }

}

#pragma mark - other
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (self.menuBtn.isSelected) {
        [self menuBtn:self.menuBtn];
    }
    
}

#pragma mark - DeviceChange 设备变化
-(void)onDeviceChange:(NSNotification *)noti{
    DeviceEntity *tempDevice = noti.object;
    if (tempDevice == _deviceModel.device && tempDevice != nil) {
        [self performSelectorOnMainThread:@selector(deviceOnlineLabelSet:) withObject:tempDevice waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(setUI) withObject:nil waitUntilDone:NO];
    }
}

-(void)onDeviceStateChange:(NSNotification *)noti{
    DeviceEntity *tempDevice = noti.object;
    if (tempDevice == self.deviceModel.device && tempDevice != nil) {
        [self performSelectorOnMainThread:@selector(deviceOnlineLabelSet:) withObject:tempDevice waitUntilDone:NO];
    }
}

-(void)deviceOnlineLabelSet:(DeviceEntity *)device{

    if (device.isConnected) {
        
        if (self.linkAlc != nil) {
            [self.linkAlc dismissViewControllerAnimated:YES completion:nil];
            self.linkAlc = nil;
        }
        
    }else if (device.isConnecting){
   
    }else{

        if (self.linkAlc != nil) {
            [self.linkAlc dismissViewControllerAnimated:YES completion:^{
                UIAlertController *faultAC = [UIAlertController alertControllerWithTitle:nil message:@"设备连接失败" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                
                [faultAC addAction:ok];
                
                [self presentViewController:faultAC animated:YES completion:nil];
            }];
            
            self.linkAlc = nil;

        }
        
    }
}

#pragma mark setUI 设置UI
-(void)setUI{
    self.titleLabel.text = self.deviceModel.name;
    
    if (self.deviceModel == nil) {
        return;
    }
    
    //Byte0：开机状态 0=关，1=开
    UInt8 deviceSwitch = ((const UInt8 *)_deviceModel.dataPoint[0].bytes)[0];
    switch (deviceSwitch) {
        case 0:
        {
           self.isOpen = NO;
            self.deviceOnBtn.hidden = NO;
            self.deviceOnBtnLabel.hidden = NO;
            self.shadowView.hidden = NO;
            
            self.bottonView.userInteractionEnabled = NO;
            self.tsOffBtn.userInteractionEnabled = NO;
            self.tsOnBtn.userInteractionEnabled = NO;
        }
            break;
        case 1:
        {
            self.isOpen = YES;
            self.deviceOnBtn.hidden = YES;
            self.deviceOnBtnLabel.hidden = YES;
            self.shadowView.hidden = YES;
            
            self.bottonView.userInteractionEnabled = YES;
            self.tsOffBtn.userInteractionEnabled = YES;
            self.tsOnBtn.userInteractionEnabled = YES;
        }
            break;
        default:
            break;
    } 

    if (self.isOpen) {
        //Byte1：童锁状态 0=关，1=开
        UInt8 childLock = ((const UInt8 *)_deviceModel.dataPoint[1].bytes)[0];
        switch (childLock) {
            case 0:
            {
                self.isLock = NO;
                self.shadowView.hidden = YES;
                self.tsOnBtn.hidden = YES;
                self.bottonView.userInteractionEnabled = YES;
            }
                break;
            case 1:
            {
                self.isLock = YES;
                self.shadowView.hidden = NO;
                self.tsOnBtn.hidden = NO;
                self.bottonView.userInteractionEnabled = NO;
            }
                break;
            default:
                break;
        }
    }

    if (self.isShowMenu) {
        self.shadowView.hidden = NO;
    }
    
//    Byte2：Pm2.5设定高字节	0-999 设定值
//    Byte3：Pm2.5设定低字节
    
//    Byte4：新风	0=关 1~12  步长为1
    UInt8 xinfeng = ((const UInt8 *)_deviceModel.dataPoint[4].bytes)[0];
    [self.xinfengSlider setValue:xinfeng];
    switch (xinfeng) {
        case 0:
        {
            self.xinfengImg.image = [UIImage imageNamed:@"bg_xinfeng_off"];
            self.xinfengLabel.text = [NSString stringWithFormat:@"排风:关"];
        }
            break;
            
        default:
        {
            self.xinfengImg.image = [UIImage imageNamed:@"bg_xinfeng_on"];
            self.xinfengLabel.text = [NSString stringWithFormat:@"排风:%d",xinfeng];
        }
            break;
    }

//    Byte5：排风	0=关 1~12  步长为1
    UInt8 paifeng = ((const UInt8 *)_deviceModel.dataPoint[5].bytes)[0];
    [self.paifengSlider setValue:paifeng];
    switch (paifeng) {
        case 0:
        {
            self.paifengImg.image = [UIImage imageNamed:@"bg_paifeng_off"];
            self.paifengLabel.text = [NSString stringWithFormat:@"排风:关"];
        }
            break;
            
        default:
        {
            self.paifengImg.image = [UIImage imageNamed:@"bg_paifeng_off"];
            self.paifengLabel.text = [NSString stringWithFormat:@"排风:%d",paifeng];
        }
            break;
    }

//    Byte6：模式	0=手动，1=自动，2=静音
    UInt8 deviceMode = ((const UInt8 *)_deviceModel.dataPoint[6].bytes)[0];
    [self setModeBtnUI:deviceMode];
//    Byte7：加热	0=关，1=开
    UInt8 jiare = ((const UInt8 *)_deviceModel.dataPoint[7].bytes)[0];
    switch (jiare) {
        case 0:
            [self.jiareSwitch setOn:NO];
            break;
        case 1:
            [self.jiareSwitch setOn:YES];
            break;
        default:
            break;
    }
//    Byte8：负离子	0=关，1=开
    UInt8 fulizi = ((const UInt8 *)_deviceModel.dataPoint[8].bytes)[0];
    switch (fulizi) {
        case 0:
            [self.fuliziSwitch setOn:NO];
            break;
        case 1:
            [self.fuliziSwitch setOn:YES];
            break;
        default:
            break;
    }
//    Byte9：杀菌	0=关，1=开
    UInt8 shajun = ((const UInt8 *)_deviceModel.dataPoint[9].bytes)[0];
    switch (shajun) {
        case 0:
            [self.HumiditySwitch setOn:NO];
            break;
        case 1:
            [self.HumiditySwitch setOn:YES];
            break;
        default:
            break;
    }
//    Byte10：加湿	0=关，1=开
    UInt8 jiashi = ((const UInt8 *)_deviceModel.dataPoint[10].bytes)[0];
    switch (jiashi) {
        case 0:
            [self.HumiditySwitch setOn:NO];
            break;
        case 1:
            [self.HumiditySwitch setOn:YES];
            break;
        default:
            break;
    }
    if (self.HumiditySwitch.isOn) {
        self.HumiditySlider.userInteractionEnabled = YES;
        self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(%d%@)",(int)self.HumiditySlider.value,@"%"];
    }else{
        self.HumiditySlider.userInteractionEnabled = NO;
        self.humiditySwitchLabel.text = [NSString stringWithFormat:@"加湿(关闭)"];
    }
//    Byte11：湿度设定	5~95  步长为5
    UInt8 jiashiValue = ((const UInt8 *)_deviceModel.dataPoint[11].bytes)[0];
    [self.HumiditySlider setValue:jiashiValue/5];
    
//    Byte12：除霜	0=关，1=开
    UInt8 chu = ((const UInt8 *)_deviceModel.dataPoint[12].bytes)[0];
    switch (chu) {
        case 0:
            [self.chushuangSwitch setOn:NO];
            break;
        case 1:
            [self.chushuangSwitch setOn:YES];
            break;
        default:
            break;
    }
//    Byte13：定时开小时	0-23	时间为=00：00则为定时开关闭
//    Byte14：定时开分钟	0-59
//    Byte15：定时关小时	0-23	时间为=00：00则为定时关关闭
//    Byte16：定时关分钟	0-59
//    Byte17：维护1提示	0=无提示，1=提示触发
//    Byte18：维护2提示	0=无提示，1=提示触发
//    Byte19：维护3提示	0=无提示，1=提示触发
//    Byte20：维护4提示	0=无提示，1=提示触发
    
//    Byte21：维护1时间设定值	1~199  步长为1	实际为5-995天，参数值放大5倍
    UInt8 maintain1Value = ((const UInt8 *)self.deviceModel.dataPoint[21].bytes)[0];
    [self.maintain1Slider setValue:maintain1Value];
    self.maintain1Label.text = [NSString stringWithFormat:@"维护1(%d天)",maintain1Value*5];
    
//    Byte22：维护2时间：设定值	1~199  步长为1	实际为5-995天，参数值放大5倍
    UInt8 maintain2Value = ((const UInt8 *)self.deviceModel.dataPoint[22].bytes)[0];
    [self.maintain2Slider setValue:maintain2Value];
    self.maintain2Label.text = [NSString stringWithFormat:@"维护2(%d天)",maintain2Value*5];
    
//    Byte23：室内温度值
    UInt8 inDoorTempValue = ((const UInt8 *)_deviceModel.dataPoint[23].bytes)[0];
    self.inDoorTemp.text = [NSString stringWithFormat:@"%d ℃",inDoorTempValue];
//    Byte24：室内湿度值
    UInt8 inDoorHumidity = ((const UInt8 *)_deviceModel.dataPoint[24].bytes)[0];
    self.inDoorHumidity.text = [NSString stringWithFormat:@"%d %@",inDoorHumidity,@"%"];
    
//    Byte25：室外温度值
    UInt8 outDoorTempValue = ((const UInt8 *)_deviceModel.dataPoint[25].bytes)[0];
    self.outDoorTemp.text = [NSString stringWithFormat:@"%d ℃",outDoorTempValue];
//    Byte26：室外湿度值
    UInt8 outDoorHumidity = ((const UInt8 *)_deviceModel.dataPoint[26].bytes)[0];
    self.outDoorHumidity.text = [NSString stringWithFormat:@"%d %@",outDoorHumidity,@"%"];
    
//    Byte27：Pm2.5高字节	0~999 实际值
//    Byte28：Pm2.5低字节
    UInt8 pm25HightBit = ((const UInt8 *)_deviceModel.dataPoint[27].bytes)[0];
    UInt8 pm25LowBit = ((const UInt8 *)_deviceModel.dataPoint[28].bytes)[0];
    
//    NSMutableData *pm25Data = [NSMutableData data];
    [pm25Data appendBytes:&pm25HightBit length:1];
    [pm25Data appendBytes:&pm25LowBit length:1];
    
    unsigned char pm25Value;
    [pm25Data getBytes:&pm25Value length:2];
    
    /*
     绿色：PM数值0-35  颜色值：44af35
     蓝色：36-75         颜色值：009fe8
     黄色：大于75       颜色值：f08200
     */
    if (pm25Value <36) {
        [self.pm25Img setImage:[UIImage imageNamed:@"bg_lv"]];
        [self.pm25ugImg setImage:[UIImage imageNamed:@"bg_ug_lv"]];
        [self.pm25Label setTextColor:[UIColor colorWithRed:0.28 green:0.68 blue:0.24 alpha:1.00]];
    }else if (pm25Value < 76){
        [self.pm25Img setImage:[UIImage imageNamed:@"bg_lan"]];
        [self.pm25ugImg setImage:[UIImage imageNamed:@"bg_ug_lan"]];
        [self.pm25Label setTextColor:[UIColor colorWithRed:0.10 green:0.63 blue:0.90 alpha:1.00]];
        
    }else{
        [self.pm25Img setImage:[UIImage imageNamed:@"bg_huang"]];
        [self.pm25ugImg setImage:[UIImage imageNamed:@"bg_ug_huang"]];
        [self.pm25Label setTextColor:[UIColor colorWithRed:0.93 green:0.51 blue:0.13 alpha:1.00]];
    }
    self.pm25Label.text = [NSString stringWithFormat:@"%d",pm25Value];
    pm25Data = nil;
//    Byte29：CO2显示高字节	0-9999
//    Byte30：CO2显示低字节
    UInt8 co2HightBit = ((const UInt8 *)self.deviceModel.dataPoint[29].bytes)[0];
    UInt8 co2LowBit = ((const UInt8 *)self.deviceModel.dataPoint[30].bytes)[0];

//    NSMutableData *co2 = [NSMutableData data];
    [co2Data appendBytes:&co2HightBit length:1];
    [co2Data appendBytes:&co2LowBit length:1];
    
    unsigned char co2Value;
    [co2Data getBytes:&co2Value length:2];
    
    co2Data = nil;
    
//    Byte31：Esp显示	0=无异常，1=异常
//    Byte32：缺水提示	0=无提示，1=缺水
    UInt8 error = ((const UInt8 *)self.deviceModel.dataPoint[32].bytes)[0];
    NSLog(@"缺水提示%d",error);
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceChange object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
