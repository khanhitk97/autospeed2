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
// 1. FLY VIEW CỰC ĐẸP (CÓ VỆT SÁNG PARTICLE)
// ==========================================
@interface FlyView : UIView
@property (nonatomic, strong) UIView *leftWing;
@property (nonatomic, strong) UIView *rightWing;
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) CAEmitterLayer *trailEmitter;
@end

@implementation FlyView

// Tạo hạt phát sáng từ mã nguồn thuần
- (UIImage *)generateParticleImage {
    CGSize size = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat colors[] = {
        0.2, 0.9, 1.0, 1.0,  // Cyan sáng ở tâm
        0.0, 0.5, 1.0, 0.0   // Trong suốt ở viền
    };
    CGFloat locations[] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 2);
    
    CGContextDrawRadialGradient(ctx, gradient, CGPointMake(6, 6), 0, CGPointMake(6, 6), 6, 0);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    return img;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 26, 26)];
    if (self) {
        self.userInteractionEnabled = NO;

        // Vệt hạt sáng lấp lánh sau đuôi ruồi (Trail Particle)
        _trailEmitter = [CAEmitterLayer layer];
        _trailEmitter.emitterPosition = CGPointMake(13, 22);
        _trailEmitter.emitterSize = CGSizeMake(4, 4);
        _trailEmitter.emitterShape = kCAEmitterLayerPoint;
        
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.birthRate = 25;
        cell.lifetime = 0.35;
        cell.velocity = 15;
        cell.velocityRange = 5;
        cell.scale = 0.6;
        cell.scaleRange = 0.3;
        cell.scaleSpeed = -1.2;
        cell.alphaSpeed = -2.5;
        cell.contents = (id)[self generateParticleImage].CGImage;
        _trailEmitter.emitterCells = @[cell];
        [self.layer addSublayer:_trailEmitter];

        // Thân ruồi (Có bóng sáng Glow Aura)
        _bodyView = [[UIView alloc] initWithFrame:CGRectMake(10, 4, 6, 18)];
        _bodyView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.12 alpha:0.95];
        _bodyView.layer.cornerRadius = 3.0;
        _bodyView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8].CGColor;
        _bodyView.layer.shadowOffset = CGSizeZero;
        _bodyView.layer.shadowRadius = 4.0;
        _bodyView.layer.shadowOpacity = 0.8;

        // Mắt phát sáng Cyber
        UIView *leftEye = [[UIView alloc] initWithFrame:CGRectMake(9, 3, 2.5, 2.5)];
        leftEye.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.3 alpha:1.0];
        leftEye.layer.cornerRadius = 1.25;

        UIView *rightEye = [[UIView alloc] initWithFrame:CGRectMake(14.5, 3, 2.5, 2.5)];
        rightEye.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.3 alpha:1.0];
        rightEye.layer.cornerRadius = 1.25;

        // Cánh trái (Glow cánh mờ)
        _leftWing = [[UIView alloc] initWithFrame:CGRectMake(2, 7, 9, 14)];
        _leftWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.7];
        _leftWing.layer.cornerRadius = 4.5;
        _leftWing.layer.anchorPoint = CGPointMake(1.0, 0.2);
        _leftWing.layer.borderWidth = 0.5;
        _leftWing.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.6].CGColor;

        // Cánh phải
        _rightWing = [[UIView alloc] initWithFrame:CGRectMake(15, 7, 9, 14)];
        _rightWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.7];
        _rightWing.layer.cornerRadius = 4.5;
        _rightWing.layer.anchorPoint = CGPointMake(0.0, 0.2);
        _rightWing.layer.borderWidth = 0.5;
        _rightWing.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.6].CGColor;

        [self addSubview:_leftWing];
        [self addSubview:_rightWing];
        [self addSubview:_bodyView];
        [self addSubview:leftEye];
        [self addSubview:rightEye];

        [self startWingFlapping];
        [self startBreathingGlow];
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

// Hiệu ứng thở hào quang xung quanh ruồi
- (void)startBreathingGlow {
    CABasicAnimation *glow = [CABasicAnimation animationWithKeyPath:@"layer.shadowRadius"];
    glow.fromValue = @(2.0);
    glow.toValue = @(7.0);
    glow.duration = 1.0;
    glow.autoreverses = YES;
    glow.repeatCount = HUGE_VALF;
    [_bodyView.layer addAnimation:glow forKey:@"glow"];
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
// 2. SPEEDHACK MANAGER + HIỆU ỨNG SÓNG NĂNG LƯỢNG
// ==========================================
@interface SpeedhackManager : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) FlyView *fly;
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

    _fly = [[FlyView alloc] initWithFrame:CGRectMake(window.bounds.size.width / 2.0, window.bounds.size.height / 2.0, 26, 26)];
    [window addSubview:_fly];

    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecretGesture:)];
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.numberOfTapsRequired = 2;
    tripleTap.cancelsTouchesInView = NO;
    tripleTap.delaysTouchesBegan = NO;
    tripleTap.delaysTouchesEnded = NO;
    tripleTap.delegate = self;
    [window addGestureRecognizer:tripleTap];
}

// Hiệu ứng sóng lan tỏa Shockwave khi gõ 3 ngón tay
- (void)playShockwaveAtCenter:(CGPoint)pos inView:(UIView *)view isEnabled:(BOOL)enabled {
    UIView *wave = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    wave.center = pos;
    wave.userInteractionEnabled = NO;
    wave.layer.cornerRadius = 5;
    wave.layer.borderWidth = 2.5;
    
    // Xanh Neon khi Bật, Đỏ Cam khi Tắt
    UIColor *themeColor = enabled ? [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:0.9] : [UIColor colorWithRed:1.0 green:0.3 blue:0.2 alpha:0.9];
    wave.layer.borderColor = themeColor.CGColor;
    wave.layer.shadowColor = themeColor.CGColor;
    wave.layer.shadowRadius = 8;
    wave.layer.shadowOpacity = 0.9;
    
    [view addSubview:wave];

    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        wave.transform = CGAffineTransformMakeScale(18.0, 18.0);
        wave.alpha = 0.0;
    } completion:^(BOOL finished) {
        [wave removeFromSuperview];
    }];
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
    CGPoint touchPos = [gesture locationInView:gesture.view];

    // Phát hiệu ứng vòng sóng Shockwave tại điểm gõ ngón tay
    [self playShockwaveAtCenter:touchPos inView:gesture.view isEnabled:_isSpeedEnabled];

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:_isSpeedEnabled ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleRigid];
        [feedback prepare];
        [feedback impactOccurred];
    }

    if (_isSpeedEnabled) {
        set_speed_factor(5.0f);
        _fly.hidden = NO;
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:0 animations:^{
            self.fly.alpha = 1.0;
            self.fly.transform = CGAffineTransformIdentity;
        } completion:nil];
        [_fly scheduleNextMove];
    } else {
        set_speed_factor(1.0f);
        [UIView animateWithDuration:0.3 animations:^{
            self.fly.alpha = 0.0;
            self.fly.transform = CGAffineTransformMakeScale(0.01, 0.01);
        } completion:^(BOOL finished) {
            self.fly.hidden = YES;
        }];
    }
}

@end
