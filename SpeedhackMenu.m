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
// 1. WEATHER HEADER VIEW (CAM->VÀNG / CAM->ĐEN XÁM)
// ==========================================
@interface WeatherHeaderView : UIView
@property (nonatomic, strong) CAGradientLayer *headerGradient;
@property (nonatomic, strong) UIView *sunOrMoonView;
@property (nonatomic, strong) UIView *cloudContainer;
@property (nonatomic, strong) UIView *cloud1;
@property (nonatomic, strong) UIView *cloud2;
@end

@implementation WeatherHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;

        // Gradient nền trực tiếp
        _headerGradient = [CAGradientLayer layer];
        _headerGradient.frame = self.bounds;
        _headerGradient.startPoint = CGPointMake(0.0, 0.0);
        _headerGradient.endPoint = CGPointMake(1.0, 1.0);
        [self.layer addSublayer:_headerGradient];

        // Container cho Mây
        _cloudContainer = [[UIView alloc] initWithFrame:self.bounds];
        _cloudContainer.userInteractionEnabled = NO;
        [self addSubview:_cloudContainer];

        _cloud1 = [self createCloudWithWidth:48 height:16];
        _cloud2 = [self createCloudWithWidth:36 height:13];
        [_cloudContainer addSubview:_cloud1];
        [_cloudContainer addSubview:_cloud2];

        // Mặt trời / Mặt trăng
        _sunOrMoonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        _sunOrMoonView.userInteractionEnabled = NO;
        _sunOrMoonView.layer.cornerRadius = 13.0;
        [self addSubview:_sunOrMoonView];

        [self updateWeatherCycle];
        [self startCloudAnimation];
    }
    return self;
}

- (UIView *)createCloudWithWidth:(CGFloat)w height:(CGFloat)h {
    UIView *cloud = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    cloud.layer.cornerRadius = h / 2.0;
    return cloud;
}

- (void)updateWeatherCycle {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:[NSDate date]];

    if (hour >= 6 && hour < 18) {
        // BAN NGÀY: Cam tươi sáng -> Vàng nắng ấm
        _headerGradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.40 blue:0.15 alpha:0.95].CGColor,
            (id)[UIColor colorWithRed:1.0 green:0.75 blue:0.25 alpha:0.95].CGColor
        ];

        // Mặt trời vàng rực rỡ
        _sunOrMoonView.center = CGPointMake(self.bounds.size.width - 40, 52);
        _sunOrMoonView.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.4 alpha:1.0];
        _sunOrMoonView.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.2 alpha:0.9].CGColor;
        _sunOrMoonView.layer.shadowRadius = 8.0;
        _sunOrMoonView.layer.shadowOpacity = 0.9;

        // Mây trắng ban ngày
        _cloud1.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
        _cloud2.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];

    } else {
        // BAN ĐÊM: Cam sẫm -> Đen xám dịu mắt
        _headerGradient.colors = @[
            (id)[UIColor colorWithRed:0.75 green:0.25 blue:0.12 alpha:0.95].CGColor,
            (id)[UIColor colorWithRed:0.12 green:0.13 blue:0.16 alpha:0.98].CGColor
        ];

        // Mặt trăng khuyết phát sáng bạc dịu
        _sunOrMoonView.center = CGPointMake(self.bounds.size.width - 40, 50);
        _sunOrMoonView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.95];
        _sunOrMoonView.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:0.8].CGColor;
        _sunOrMoonView.layer.shadowRadius = 7.0;
        _sunOrMoonView.layer.shadowOpacity = 0.85;

        // Mây ánh đêm
        _cloud1.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.20];
        _cloud2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.15];
    }
}

- (void)startCloudAnimation {
    _cloud1.frame = CGRectMake(-60, 42, 48, 16);
    _cloud2.frame = CGRectMake(-90, 58, 36, 13);

    [self animateCloud:_cloud1 duration:36.0 delay:0];
    [self animateCloud:_cloud2 duration:46.0 delay:8.0];
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
// 2. NIGHT BODY OVERLAY (PHỦ ĐEN NỀN APP BAN ĐÊM)
// ==========================================
@interface NightBodyOverlay : UIView
@end

@implementation NightBodyOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Tông đen xám dịu mắt chống chói
        self.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.09 alpha:0.55];
        self.userInteractionEnabled = NO; // Không cản trở cảm ứng
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

@end

// ==========================================
// 3. FLY VIEW (RUỒI PHÁT SÁNG ĐOM ĐÓM BAN ĐÊM)
// ==========================================
@interface FlyView : UIView
@property (nonatomic, strong) UIView *leftWing;
@property (nonatomic, strong) UIView *rightWing;
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) UIView *glowTail;
@end

@implementation FlyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 24, 24)];
    if (self) {
        self.userInteractionEnabled = NO;

        // Đuôi phát sáng dạ quang neon
        _glowTail = [[UIView alloc] initWithFrame:CGRectMake(9.5, 12, 5, 8)];
        _glowTail.backgroundColor = [UIColor colorWithRed:0.35 green:1.0 blue:0.2 alpha:0.95];
        _glowTail.layer.cornerRadius = 2.5;
        _glowTail.layer.shadowColor = [UIColor colorWithRed:0.3 green:1.0 blue:0.2 alpha:1.0].CGColor;
        _glowTail.layer.shadowRadius = 8.0;
        _glowTail.layer.shadowOpacity = 0.95;

        // Thân ruồi
        _bodyView = [[UIView alloc] initWithFrame:CGRectMake(9, 3, 6, 18)];
        _bodyView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:0.95];
        _bodyView.layer.cornerRadius = 3.0;

        // Mắt ruồi
        UIView *leftEye = [[UIView alloc] initWithFrame:CGRectMake(8, 2, 2.5, 2.5)];
        leftEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        leftEye.layer.cornerRadius = 1.25;

        UIView *rightEye = [[UIView alloc] initWithFrame:CGRectMake(13.5, 2, 2.5, 2.5)];
        rightEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        rightEye.layer.cornerRadius = 1.25;

        // Cánh
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

        [self addSubview:_glowTail];
        [self addSubview:_leftWing];
        [self addSubview:_rightWing];
        [self addSubview:_bodyView];
        [self addSubview:leftEye];
        [self addSubview:rightEye];

        [self updateGlowState];
        [self startWingFlapping];
        [self startAI];
    }
    return self;
}

- (void)updateGlowState {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:[NSDate date]];

    if (hour >= 6 && hour < 18) {
        // BAN NGÀY: Tắt phát sáng
        _glowTail.hidden = YES;
        [_glowTail.layer removeAnimationForKey:@"glowPulse"];
    } else {
        // BAN ĐÊM: Bật phát sáng dạ quang neon
        _glowTail.hidden = NO;
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        pulse.fromValue = @(0.4);
        pulse.toValue = @(1.0);
        pulse.duration = 1.2;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        [_glowTail.layer addAnimation:pulse forKey:@"glowPulse"];
    }
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
// 4. SPEEDHACK MANAGER
// ==========================================
@interface SpeedhackManager : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) FlyView *fly;
@property (nonatomic, strong) WeatherHeaderView *weatherHeader;
@property (nonatomic, strong) NightBodyOverlay *nightBody;
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

    CGFloat headerHeight = 98.0;

    // 1. Phủ đen nền thân app (chỉ kích hoạt ban đêm)
    _nightBody = [[NightBodyOverlay alloc] initWithFrame:CGRectMake(0, headerHeight, window.bounds.size.width, window.bounds.size.height - headerHeight)];
    _nightBody.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:_nightBody];

    // 2. Header gradient ngày/đêm
    _weatherHeader = [[WeatherHeaderView alloc] initWithFrame:CGRectMake(0, 0, window.bounds.size.width, headerHeight)];
    [window addSubview:_weatherHeader];

    // 3. Bé Ruồi
    _fly = [[FlyView alloc] initWithFrame:CGRectMake(window.bounds.size.width / 2.0, window.bounds.size.height / 2.0, 24, 24)];
    [window addSubview:_fly];

    [self syncDayNightTheme];

    // 4. Gắn cử chỉ chạm 3 ngón 2 lần
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecretGesture:)];
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.numberOfTapsRequired = 2;
    tripleTap.cancelsTouchesInView = NO;
    tripleTap.delaysTouchesBegan = NO;
    tripleTap.delaysTouchesEnded = NO;
    tripleTap.delegate = self;
    [window addGestureRecognizer:tripleTap];
}

- (void)syncDayNightTheme {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:[NSDate date]];
    BOOL isNight = (hour < 6 || hour >= 18);

    _nightBody.hidden = !isNight;
    [_weatherHeader updateWeatherCycle];
    [_fly updateGlowState];
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
        set_speed_factor(5.0f);

        _weatherHeader.hidden = NO;
        _fly.hidden = NO;

        [self syncDayNightTheme];

        [UIView animateWithDuration:0.35 animations:^{
            self.weatherHeader.alpha = 1.0;
            self.nightBody.alpha = 1.0;
            self.fly.alpha = 1.0;
            self.fly.transform = CGAffineTransformIdentity;
        }];
        [_fly scheduleNextMove];

    } else {
        set_speed_factor(1.0f);

        [UIView animateWithDuration:0.3 animations:^{
            self.weatherHeader.alpha = 0.0;
            self.nightBody.alpha = 0.0;
            self.fly.alpha = 0.0;
            self.fly.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            self.weatherHeader.hidden = YES;
            self.nightBody.hidden = YES;
            self.fly.hidden = YES;
        }];
    }
}

@end
