#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
extern "C" {
#endif
extern void set_speed_factor(float factor);
#ifdef __cplusplus
}
#endif

// ==========================================
// 1. WEATHER HEADER VIEW (MÂY, TRỜI, TRĂNG, MƯA, TIA SÁNG)
// ==========================================
@interface WeatherHeaderView : UIView
@property (nonatomic, strong) CAGradientLayer *skyGradient;
@property (nonatomic, strong) UIView *sunOrMoonView;
@property (nonatomic, strong) UIView *sunRaysView;
@property (nonatomic, strong) UIView *cloudContainer;
@property (nonatomic, strong) CAEmitterLayer *rainEmitter;
@property (nonatomic, strong) CAEmitterLayer *starEmitter;
@end

@implementation WeatherHeaderView

- (UIImage *)generateRainParticle {
    CGSize size = CGSizeMake(2, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.75].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, 2, 12));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)generateStarParticle {
    CGSize size = CGSizeMake(4, 4);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.9].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, 4, 4));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;

        // Bầu trời động (Sky Gradient)
        _skyGradient = [CAGradientLayer layer];
        _skyGradient.frame = self.bounds;
        _skyGradient.startPoint = CGPointMake(0.0, 0.0);
        _skyGradient.endPoint = CGPointMake(1.0, 1.0);
        [self.layer addSublayer:_skyGradient];

        // Container cho Mây & Gió
        _cloudContainer = [[UIView alloc] initWithFrame:self.bounds];
        _cloudContainer.userInteractionEnabled = NO;
        [self addSubview:_cloudContainer];

        // Tia sáng / Hào quang
        _sunRaysView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _sunRaysView.userInteractionEnabled = NO;
        [self addSubview:_sunRaysView];

        // Mặt trời / Mặt trăng
        _sunOrMoonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        _sunOrMoonView.userInteractionEnabled = NO;
        _sunOrMoonView.layer.cornerRadius = 16.0;
        [self addSubview:_sunOrMoonView];

        // Hạt mưa (Rainfall Emitter)
        _rainEmitter = [CAEmitterLayer layer];
        _rainEmitter.emitterPosition = CGPointMake(frame.size.width / 2.0, -10);
        _rainEmitter.emitterSize = CGSizeMake(frame.size.width * 1.5, 10);
        _rainEmitter.emitterShape = kCAEmitterLayerLine;

        CAEmitterCell *rainCell = [CAEmitterCell emitterCell];
        rainCell.birthRate = 22;
        rainCell.lifetime = 1.2;
        rainCell.velocity = 260;
        rainCell.velocityRange = 40;
        rainCell.emissionLongitude = (CGFloat)(M_PI_2 + M_PI / 12.0); // Rơi xiên theo gió
        rainCell.scale = 0.8;
        rainCell.alphaSpeed = -0.4;
        rainCell.contents = (id)[self generateRainParticle].CGImage;
        _rainEmitter.emitterCells = @[rainCell];
        [self.layer addSublayer:_rainEmitter];

        // Sao nhấp nháy ban đêm
        _starEmitter = [CAEmitterLayer layer];
        _starEmitter.emitterPosition = CGPointMake(frame.size.width / 2.0, frame.size.height / 2.0);
        _starEmitter.emitterSize = frame.size;
        _starEmitter.emitterShape = kCAEmitterLayerRectangle;

        CAEmitterCell *starCell = [CAEmitterCell emitterCell];
        starCell.birthRate = 6;
        starCell.lifetime = 3.0;
        starCell.scale = 0.6;
        starCell.scaleRange = 0.4;
        starCell.alphaSpeed = -0.3;
        starCell.contents = (id)[self generateStarParticle].CGImage;
        _starEmitter.emitterCells = @[starCell];
        [self.layer addSublayer:_starEmitter];

        [self updateWeatherCycle];
        [self startCloudAnimation];
    }
    return self;
}

- (void)updateWeatherCycle {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:[NSDate date]];

    if (hour >= 6 && hour < 17) {
        // BAN NGÀY: Nắng rực rỡ (Gradient Cam - Vàng)
        _skyGradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.42 blue:0.18 alpha:0.95].CGColor,
            (id)[UIColor colorWithRed:1.0 green:0.62 blue:0.25 alpha:0.95].CGColor
        ];

        // Mặt trời
        _sunOrMoonView.center = CGPointMake(self.bounds.size.width - 45, 52);
        _sunOrMoonView.backgroundColor = [UIColor colorWithRed:1.0 green:0.92 blue:0.4 alpha:1.0];
        _sunOrMoonView.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.2 alpha:1.0].CGColor;
        _sunOrMoonView.layer.shadowRadius = 12.0;
        _sunOrMoonView.layer.shadowOpacity = 0.95;

        // Tia sáng mặt trời quay chậm
        _sunRaysView.center = _sunOrMoonView.center;
        _sunRaysView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _sunRaysView.layer.cornerRadius = 40.0;
        [self startRaysRotation];

        _starEmitter.birthRate = 0;
        _rainEmitter.birthRate = 0;

    } else if (hour >= 17 && hour < 19) {
        // HOÀNG HÔN: Gradient Tím - Đỏ Cam
        _skyGradient.colors = @[
            (id)[UIColor colorWithRed:0.85 green:0.25 blue:0.35 alpha:0.95].CGColor,
            (id)[UIColor colorWithRed:0.98 green:0.48 blue:0.22 alpha:0.95].CGColor
        ];

        _sunOrMoonView.center = CGPointMake(self.bounds.size.width - 45, 62);
        _sunOrMoonView.backgroundColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.2 alpha:1.0];
        _sunOrMoonView.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.1 alpha:0.9].CGColor;
        _sunOrMoonView.layer.shadowRadius = 14.0;
        _sunOrMoonView.layer.shadowOpacity = 0.9;

        _sunRaysView.hidden = YES;
        _starEmitter.birthRate = 0;
        _rainEmitter.birthRate = 0;

    } else {
        // BAN ĐÊM: Gradient Xanh Đen Midnight + Ánh Cam Đáy
        _skyGradient.colors = @[
            (id)[UIColor colorWithRed:0.08 green:0.10 blue:0.18 alpha:0.96].CGColor,
            (id)[UIColor colorWithRed:0.18 green:0.14 blue:0.24 alpha:0.96].CGColor
        ];

        // Mặt trăng khuyết phát sáng bạc dịu
        _sunOrMoonView.center = CGPointMake(self.bounds.size.width - 45, 50);
        _sunOrMoonView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.95];
        _sunOrMoonView.layer.shadowColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:0.8].CGColor;
        _sunOrMoonView.layer.shadowRadius = 10.0;
        _sunOrMoonView.layer.shadowOpacity = 0.9;

        _sunRaysView.hidden = YES;
        _starEmitter.birthRate = 5;
        _rainEmitter.birthRate = 18; // Mưa đêm li ti mờ ảo
    }
}

- (void)startRaysRotation {
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotate.toValue = @(M_PI * 2.0);
    rotate.duration = 18.0;
    rotate.repeatCount = HUGE_VALF;
    [_sunRaysView.layer addAnimation:rotate forKey:@"sunRays"];
}

// Mây bồng bềnh trôi ngang theo gió
- (void)startCloudAnimation {
    UIView *cloud1 = [self createCloudViewWithWidth:50 height:18];
    cloud1.frame = CGRectMake(-60, 38, 50, 18);
    [_cloudContainer addSubview:cloud1];

    UIView *cloud2 = [self createCloudViewWithWidth:38 height:14];
    cloud2.frame = CGRectMake(-100, 56, 38, 14);
    [_cloudContainer addSubview:cloud2];

    [self animateCloud:cloud1 duration:22.0 delay:0];
    [self animateCloud:cloud2 duration:28.0 delay:5.0];
}

- (UIView *)createCloudViewWithWidth:(CGFloat)w height:(CGFloat)h {
    UIView *cloud = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    cloud.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    cloud.layer.cornerRadius = h / 2.0;
    return cloud;
}

- (void)animateCloud:(UIView *)cloud duration:(NSTimeInterval)dur delay:(NSTimeInterval)del {
    CGFloat startX = -cloud.bounds.size.width - 10;
    CGFloat endX = self.bounds.size.width + 20;

    cloud.frame = CGRectMake(startX, cloud.frame.origin.y, cloud.bounds.size.width, cloud.bounds.size.height);

    [UIView animateWithDuration:dur delay:del options:UIViewAnimationOptionCurveLinear animations:^{
        cloud.frame = CGRectMake(endX, cloud.frame.origin.y, cloud.bounds.size.width, cloud.bounds.size.height);
    } completion:^(BOOL finished) {
        if (finished) {
            [self animateCloud:cloud duration:dur delay:0];
        }
    }];
}

@end

// ==========================================
// 2. FLY VIEW (BÉ RUỒI ĐẬP CÁNH & BAY LƯỢN)
// ==========================================
@interface FlyView : UIView
@property (nonatomic, strong) UIView *leftWing;
@property (nonatomic, strong) UIView *rightWing;
@property (nonatomic, strong) UIView *bodyView;
@end

@implementation FlyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 24, 24)];
    if (self) {
        self.userInteractionEnabled = NO;

        _bodyView = [[UIView alloc] initWithFrame:CGRectMake(9, 3, 6, 18)];
        _bodyView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:0.95];
        _bodyView.layer.cornerRadius = 3.0;

        UIView *leftEye = [[UIView alloc] initWithFrame:CGRectMake(8, 2, 2.5, 2.5)];
        leftEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        leftEye.layer.cornerRadius = 1.25;

        UIView *rightEye = [[UIView alloc] initWithFrame:CGRectMake(13.5, 2, 2.5, 2.5)];
        rightEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        rightEye.layer.cornerRadius = 1.25;

        _leftWing = [[UIView alloc] initWithFrame:CGRectMake(1, 6, 9, 14)];
        _leftWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.65];
        _leftWing.layer.cornerRadius = 4.5;
        _leftWing.layer.anchorPoint = CGPointMake(1.0, 0.2);
        _leftWing.layer.borderWidth = 0.5;
        _leftWing.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:0.4].CGColor;

        _rightWing = [[UIView alloc] initWithFrame:CGRectMake(14, 6, 9, 14)];
        _rightWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.65];
        _rightWing.layer.cornerRadius = 4.5;
        _rightWing.layer.anchorPoint = CGPointMake(0.0, 0.2);
        _rightWing.layer.borderWidth = 0.5;
        _rightWing.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:0.4].CGColor;

        [self addSubview:_leftWing];
        [self addSubview:_rightWing];
        [self addSubview:_bodyView];
        [self addSubview:leftEye];
        [self addSubview:rightEye];

        [self startWingFlapping];
        [self startAI];
    }
    return self;
}

- (void)startWingFlapping {
    CABasicAnimation *leftFlap = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    leftFlap.fromValue = @(-M_PI / 10.0);
    leftFlap.toValue = @(-M_PI / 2.2);
    leftFlap.duration = 0.04;
    leftFlap.autoreverses = YES;
    leftFlap.repeatCount = HUGE_VALF;
    [_leftWing.layer addAnimation:leftFlap forKey:@"leftFlap"];

    CABasicAnimation *rightFlap = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rightFlap.fromValue = @(M_PI / 10.0);
    rightFlap.toValue = @(M_PI / 2.2);
    rightFlap.duration = 0.04;
    rightFlap.autoreverses = YES;
    rightFlap.repeatCount = HUGE_VALF;
    [_rightWing.layer addAnimation:rightFlap forKey:@"rightFlap"];
}

- (void)startAI {
    [self scheduleNextMove];
}

- (void)scheduleNextMove {
    float delay = (arc4random_uniform(15) + 5) / 10.0f;
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(performMove) userInfo:nil repeats:NO];
}

- (void)performMove {
    if (!self.superview || self.hidden) return;

    CGSize parentSize = self.superview.bounds.size;
    CGFloat currentX = self.center.x;
    CGFloat currentY = self.center.y;

    CGFloat targetX = arc4random_uniform((uint32_t)(parentSize.width - 60)) + 30;
    CGFloat targetY = arc4random_uniform((uint32_t)(parentSize.height - 100)) + 50;

    CGFloat deltaX = targetX - currentX;
    CGFloat deltaY = targetY - currentY;
    CGFloat distance = sqrtf(deltaX * deltaX + deltaY * deltaY);

    CGFloat angle = atan2f(deltaY, deltaX) + M_PI_2;
    CGFloat duration = (distance > 200) ? 0.35f : (distance / 80.0f);
    if (duration < 0.2f) duration = 0.2f;

    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeRotation(angle);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.center = CGPointMake(targetX, targetY);
        } completion:^(BOOL fin) {
            [self scheduleNextMove];
        }];
    }];
}

@end

// ==========================================
// 3. SPEEDHACK MANAGER (ĐỒNG BỘ HIỆU ỨNG VÀ GESTURE)
// ==========================================
@interface SpeedhackManager : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) FlyView *fly;
@property (nonatomic, strong) WeatherHeaderView *weatherHeader;
@property (nonatomic, assign) BOOL isSpeedEnabled;
@end

@implementation SpeedhackManager

static SpeedhackManager *sharedManager = nil;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow) {
            sharedManager = [[SpeedhackManager alloc] init];
            [sharedManager setupInWindow:keyWindow];
        }
    });
}

+ (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (void)setupInWindow:(UIWindow *)window {
    _isSpeedEnabled = YES;
    set_speed_factor(5.0f);

    // 1. Khởi tạo Weather Header bao phủ đúng vùng thanh tiêu đề cam
    CGFloat headerHeight = 98.0; // Chiều cao chuẩn bao phủ từ tai thỏ tới mép dưới thanh cam
    _weatherHeader = [[WeatherHeaderView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, headerHeight)];
    [window addSubview:_weatherHeader];

    // 2. Khởi tạo Bé Ruồi
    _fly = [[FlyView alloc] initWithFrame:CGRectMake(window.bounds.size.width / 2.0, window.bounds.size.height / 2.0, 24, 24)];
    [window addSubview:_fly];

    // 3. Gắn cử chỉ chạm 3 ngón 2 lần
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecretGesture:)];
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.numberOfTapsRequired = 2;
    tripleTap.cancelsTouchesInView = NO;
    tripleTap.delaysTouchesBegan = NO;
    tripleTap.delaysTouchesEnded = NO;
    tripleTap.delegate = self;
    [window addGestureRecognizer:tripleTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)handleSecretGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;

    _isSpeedEnabled = !_isSpeedEnabled;

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:_isSpeedEnabled ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleRigid];
        [feedback prepare];
        [feedback impactOccurred];
    }

    if (_isSpeedEnabled) {
        // BẬT: 5.0x + Hiện Bé Ruồi + Kích hoạt Weather Header
        set_speed_factor(5.0f);

        _weatherHeader.hidden = NO;
        _fly.hidden = NO;

        [UIView animateWithDuration:0.35 animations:^{
            self.weatherHeader.alpha = 1.0;
            self.fly.alpha = 1.0;
            self.fly.transform = CGAffineTransformIdentity;
        }];
        [_weatherHeader updateWeatherCycle];
        [_fly scheduleNextMove];

    } else {
        // TẮT: 1.0x chuẩn gốc + Ẩn hoàn toàn Weather Header & Bé Ruồi
        set_speed_factor(1.0f);

        [UIView animateWithDuration:0.3 animations:^{
            self.weatherHeader.alpha = 0.0;
            self.fly.alpha = 0.0;
            self.fly.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            self.weatherHeader.hidden = YES;
            self.fly.hidden = YES;
        }];
    }
}

@end
