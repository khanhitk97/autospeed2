#import <UIKit/UIKit.h>
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
@property (nonatomic, strong) NSTimer *crawlTimer;
@property (nonatomic, assign) BOOL isCrawling;
@end

@implementation FlyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 24, 24)];
    if (self) {
        self.userInteractionEnabled = NO; // Cho phép bấm xuyên qua ruồi, không cản trở game

        // Thân ruồi (Bao gồm đầu, ngực, bụng)
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
        _leftWing.layer.anchorPoint = CGPointMake(1.0, 0.2); // Tâm vẫy cánh sát thân
        _leftWing.layer.borderWidth = 0.5;
        _leftWing.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:0.4].CGColor;

        // Cánh phải (Trong suốt mờ)
        _rightWing = [[UIView alloc] initWithFrame:CGRectMake(14, 6, 9, 14)];
        _rightWing.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.65];
        _rightWing.layer.cornerRadius = 4.5;
        _rightWing.layer.anchorPoint = CGPointMake(0.0, 0.2); // Tâm vẫy cánh sát thân
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

// Animation đập cánh siêu tốc
- (void)startWingFlapping {
    CABasicAnimation *leftFlap = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    leftFlap.fromValue = @(-M_PI / 10.0);
    leftFlap.toValue = @(-M_PI / 2.2);
    leftFlap.duration = 0.04; // Tần số đập cực nhanh
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

// Trí tuệ nhân tạo (AI) cho ruồi tự bò, chuyển hướng và bay lượn
- (void)startAI {
    [self scheduleNextMove];
}

- (void)scheduleNextMove {
    float delay = (arc4random_uniform(15) + 5) / 10.0f; // Nghỉ ngẫu nhiên từ 0.5s - 2.0s
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(performMove) userInfo:nil repeats:NO];
}

- (void)performMove {
    if (!self.superview || self.hidden) return;

    CGSize parentSize = self.superview.bounds.size;
    CGFloat currentX = self.center.x;
    CGFloat currentY = self.center.y;

    // Chọn điểm đến ngẫu nhiên trong màn hình
    CGFloat targetX = arc4random_uniform((uint32_t)(parentSize.width - 60)) + 30;
    CGFloat targetY = arc4random_uniform((uint32_t)(parentSize.height - 100)) + 50;

    CGFloat deltaX = targetX - currentX;
    CGFloat deltaY = targetY - currentY;
    CGFloat distance = sqrtf(deltaX * deltaX + deltaY * deltaY);

    // Tính góc xoay đầu hướng về điểm đến (Góc mặc định của sprite hướng lên trên -Y)
    CGFloat angle = atan2f(deltaY, deltaX) + M_PI_2;

    // 70% là bò ngắn, 30% là bay vọt đi xa
    CGFloat duration = (distance > 200) ? 0.35f : (distance / 80.0f);
    if (duration < 0.2f) duration = 0.2f;

    // Xoay đầu trước khi di chuyển
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeRotation(angle);
    } completion:^(BOOL finished) {
        // Bắt đầu di chuyển / bay tới đích
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.center = CGPointMake(targetX, targetY);
        } completion:^(BOOL fin) {
            [self scheduleNextMove];
        }];
    }];
}

@end

// ==========================================
// 2. OVERLAY QUẢN LÝ CỬ CHỈ 3 NGÓN CHẠM 2 LẦN
// ==========================================
@interface FlyOverlayWindow : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, strong) FlyView *fly;
@property (nonatomic, assign) BOOL isSpeedEnabled;
@end

@implementation FlyOverlayWindow

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow) {
            FlyOverlayWindow *overlay = [[FlyOverlayWindow alloc] initWithFrame:keyWindow.bounds];
            [keyWindow addSubview:overlay];
        }
    });
}

+ (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) return w;
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

        // Mặc định BẬT Speed 5x và BẬT Bé Ruồi
        _isSpeedEnabled = YES;
        set_speed_factor(5.0f);

        // Tạo bé ruồi
        _fly = [[FlyView alloc] initWithFrame:CGRectMake(frame.size.width / 2.0, frame.size.height / 2.0, 24, 24)];
        [self addSubview:_fly];

        // Gắn cử chỉ: Chạm 3 ngón tay (3 touches), gõ 2 lần (2 taps)
        UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSecretGesture:)];
        tripleTap.numberOfTouchesRequired = 3;
        tripleTap.numberOfTapsRequired = 2;
        tripleTap.cancelsTouchesInView = NO;
        tripleTap.delegate = self;
        [self addGestureRecognizer:tripleTap];
    }
    return self;
}

// Bấm xuyên qua lớp Overlay để không bao giờ bị liệt cảm ứng chơi game
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil; // Trả về nil để game bên dưới nhận trọn vẹn 100% cảm ứng
}

// Cho phép nhận diện cử chỉ song song với các thao tác trong game
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// Xử lý bật / tắt khi chạm 3 ngón 2 lần
- (void)handleSecretGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;

    _isSpeedEnabled = !_isSpeedEnabled;

    // Rung phản hồi tinh tế (Haptic Feedback)
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:_isSpeedEnabled ? UIImpactFeedbackStyleHeavy : UIImpactFeedbackStyleRigid];
        [feedback prepare];
        [feedback impactOccurred];
    }

    if (_isSpeedEnabled) {
        // BẬT: Đặt tốc độ 5x và Hiện bé ruồi bay ra
        set_speed_factor(5.0f);
        _fly.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.fly.alpha = 1.0;
            self.fly.transform = CGAffineTransformIdentity;
        }];
        [_fly scheduleNextMove];
    } else {
        // TẮT: Đặt tốc độ 1x gốc và Ẩn bé ruồi đi
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
