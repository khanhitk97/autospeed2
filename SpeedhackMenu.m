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
// 1. FLY VIEW (VẼ VÀ TẠO ANIMATION BÉ RUỒI)
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
        self.userInteractionEnabled = NO; // Không chặn cảm ứng game

        // Thân ruồi
        _bodyView = [[UIView alloc] initWithFrame:CGRectMake(9, 3, 6, 18)];
        _bodyView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:0.95];
        _bodyView.layer.cornerRadius = 3.0;

        // Mắt ruồi (Đỏ sẫm)
        UIView *leftEye = [[UIView alloc] initWithFrame:CGRectMake(8, 2, 2.5, 2.5)];
        leftEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        leftEye.layer.cornerRadius = 1.25;

        UIView *rightEye = [[UIView alloc] initWithFrame:CGRectMake(13.5, 2, 2.5, 2.5)];
        rightEye.backgroundColor = [UIColor colorWithRed:0.75 green:0.1 blue:0.1 alpha:0.9];
        rightEye.layer.cornerRadius = 1.25;

        // Cánh trái (Trong suốt mờ)
        _leftWing = [[UIView alloc] initWithFrame:CGRectMake(1, 6, 9, 14)];
        _leftWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.65];
        _leftWing.layer.cornerRadius = 4.5;
        _leftWing.layer.anchorPoint = CGPointMake(1.0, 0.2);
        _leftWing.layer.borderWidth = 0.5;
        _leftWing.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:0.4].CGColor;

        // Cánh phải (Trong suốt mờ)
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

// Animation vỗ cánh liên tục
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

// AI tự bò / bay ngẫu nhiên trên màn hình
- (void)startAI {
    [self scheduleNextMove];
}

- (void)scheduleNextMove {
    float delay = (arc4random_uniform(15) + 5) / 10.0f; // Nghỉ từ 0.5s - 2.0s
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
// 2. SPEEDHACK MENU OVERLAY (QUẢN LÝ GESTURE)
// ==========================================
@interface SpeedhackMenu : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) FlyView *fly;
@property (nonatomic, assign) BOOL isSpeedEnabled;
@end

@implementation SpeedhackMenu

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow) {
            SpeedhackMenu *overlay = [[SpeedhackMenu alloc] initWithFrame:keyWindow.bounds];
            [keyWindow addSubview:overlay];
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
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;

        // Mặc định BẬT 5.0x và hiển thị bé ruồi
        _isSpeedEnabled = YES;
        set_speed_factor(5.0f);

        _fly = [[FlyView alloc] initWithFrame:CGRectMake(frame.size.width / 2.0, frame.size.height / 2.0, 24, 24)];
        [self addSubview:_fly];

        // Cử chỉ chạm 3 ngón 2 lần (3 touches, 2 taps)
        UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecretGesture:)];
        tripleTap.numberOfTouchesRequired = 3;
        tripleTap.numberOfTapsRequired = 2;
        tripleTap.cancelsTouchesInView = NO;
        tripleTap.delegate = self;
        [self addGestureRecognizer:tripleTap];
    }
    return self;
}

// Bỏ chặn cảm ứng để game nhận 100% thao tác
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// Chuyển đổi trạng thái Bật / Tắt
- (void)handleSecretGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;

    _isSpeedEnabled = !_isSpeedEnabled;

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:_isSpeedEnabled ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleRigid];
        [feedback prepare];
        [feedback impactOccurred];
    }

    if (_isSpeedEnabled) {
        // BẬT: 5x và hiện ruồi
        set_speed_factor(5.0f);
        _fly.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.fly.alpha = 1.0;
            self.fly.transform = CGAffineTransformIdentity;
        }];
        [_fly scheduleNextMove];
    } else {
        // TẮT: 1x gốc và ẩn ruồi
        set_speed_factor(1.0f);
        [UIView animateWithDuration:0.3 animations:^{
            self.fly.alpha = 0.0;
            self.fly.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            self.fly.hidden = YES;
        }];
    }
}

@end
