#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

extern void set_speed_factor(float factor);
extern float get_speed_factor(void);

#ifdef __cplusplus
}
#endif

@interface SpeedhackMenu : UIView

@property (nonatomic, strong) UIButton *mainButton;
@property (nonatomic, strong) UIView *presetPanel;
@property (nonatomic, strong) UIButton *btnOff;
@property (nonatomic, strong) UIButton *btnOn;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, strong) NSTimer *fadeTimer;
@property (nonatomic, assign) BOOL isSpeedEnabled;

@end

@implementation SpeedhackMenu

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow) {
            SpeedhackMenu *menu = [[SpeedhackMenu alloc] initWithFrame:CGRectMake(20, 150, 50, 50)];
            [keyWindow addSubview:menu];
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
        _isExpanded = NO;
        _isSpeedEnabled = YES; // Mặc định mở app là BẬT 5.0x
        set_speed_factor(5.00f);

        // 1. Nút bong bóng chính
        _mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mainButton.frame = CGRectMake(0, 0, 50, 50);
        _mainButton.layer.cornerRadius = 25.0;
        _mainButton.layer.borderWidth = 2.0;
        _mainButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _mainButton.layer.shadowColor = [UIColor blackColor].CGColor;
        _mainButton.layer.shadowOffset = CGSizeMake(0, 2);
        _mainButton.layer.shadowOpacity = 0.3;
        _mainButton.layer.shadowRadius = 4.0;
        
        [self updateMainButtonTitle];
        _mainButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        [_mainButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_mainButton];

        // Gesture kéo thả
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        // 2. Bảng điều khiển chọn 1 hoặc 2
        _presetPanel = [[UIView alloc] initWithFrame:CGRectMake(55, 2.5, 175, 45)];
        _presetPanel.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.95];
        _presetPanel.layer.cornerRadius = 12.0;
        _presetPanel.layer.borderWidth = 1.5;
        _presetPanel.layer.borderColor = [UIColor colorWithRed:0.1 green:0.55 blue:1.0 alpha:1.0].CGColor;
        _presetPanel.alpha = 0.0;
        _presetPanel.hidden = YES;

        // Nút 1: TẮT (1.0x)
        _btnOff = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnOff.frame = CGRectMake(8, 7.5, 75, 30);
        _btnOff.layer.cornerRadius = 8.0;
        _btnOff.tag = 1;
        [_btnOff setTitle:@"1: TẮT" forState:UIControlStateNormal];
        _btnOff.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [_btnOff addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_presetPanel addSubview:_btnOff];

        // Nút 2: BẬT (5.0x)
        _btnOn = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnOn.frame = CGRectMake(91, 7.5, 75, 30);
        _btnOn.layer.cornerRadius = 8.0;
        _btnOn.tag = 2;
        [_btnOn setTitle:@"2: BẬT" forState:UIControlStateNormal];
        _btnOn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [_btnOn addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_presetPanel addSubview:_btnOn];

        [self updateButtonStates];
        [self addSubview:_presetPanel];

        self.alpha = 0.15;
    }
    return self;
}

- (void)updateMainButtonTitle {
    if (_isSpeedEnabled) {
        [_mainButton setTitle:@"⚡️5x" forState:UIControlStateNormal];
        _mainButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.38 alpha:0.9]; // Xanh lá
    } else {
        [_mainButton setTitle:@"OFF" forState:UIControlStateNormal];
        _mainButton.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.20 alpha:0.9]; // Đỏ cam
    }
}

- (void)updateButtonStates {
    if (_isSpeedEnabled) {
        _btnOn.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.38 alpha:1.0];
        [_btnOn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _btnOff.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.25 alpha:1.0];
        [_btnOff setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else {
        _btnOff.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.20 alpha:1.0];
        [_btnOff setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        _btnOn.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.25 alpha:1.0];
        [_btnOn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha < 0.01) return nil;

    CGPoint mainPoint = [self convertPoint:point toView:self.mainButton];
    if ([self.mainButton pointInside:mainPoint withEvent:event]) {
        return self.mainButton;
    }

    if (self.isExpanded) {
        CGPoint panelPoint = [self convertPoint:point toView:self.presetPanel];
        if ([self.presetPanel pointInside:panelPoint withEvent:event]) {
            return [self.presetPanel hitTest:panelPoint withEvent:event];
        }
    }
    return nil;
}

- (void)triggerHaptic {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void)actionButtonTapped:(UIButton *)sender {
    [self triggerHaptic];
    [self resetFadeTimer];
    self.alpha = 1.0;

    if (sender.tag == 1) {
        // NÚT 1: TẮT -> Trả về 1.0x gốc
        _isSpeedEnabled = NO;
        set_speed_factor(1.00f);
    } else if (sender.tag == 2) {
        // NÚT 2: BẬT -> Kích hoạt 5.0x
        _isSpeedEnabled = YES;
        set_speed_factor(5.00f);
    }

    [self updateButtonStates];
    [self updateMainButtonTitle];
}

- (void)toggleMenu {
    [self triggerHaptic];
    [self resetFadeTimer];
    self.alpha = 1.0;
    
    _isExpanded = !_isExpanded;
    
    if (_isExpanded) {
        _presetPanel.hidden = NO;
    }

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if (self.isExpanded) {
            self.presetPanel.alpha = 1.0;
            self.presetPanel.transform = CGAffineTransformIdentity;
        } else {
            self.presetPanel.alpha = 0.0;
            self.presetPanel.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }
    } completion:^(BOOL finished) {
        if (!self.isExpanded) {
            self.presetPanel.hidden = YES;
        }
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    [self resetFadeTimer];
    self.alpha = 1.0;
    
    CGPoint translation = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.superview];

    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            insets = self.superview.safeAreaInsets;
        }
        
        CGFloat screenWidth = self.superview.bounds.size.width;
        CGFloat screenHeight = self.superview.bounds.size.height;
        CGFloat halfWidth = self.bounds.size.width / 2.0;
        
        CGFloat targetX = (self.center.x < screenWidth / 2.0) ? (insets.left + halfWidth + 10) : (screenWidth - insets.right - halfWidth - 10);
        CGFloat targetY = MIN(MAX(self.center.y, insets.top + halfWidth + 10), screenHeight - insets.bottom - halfWidth - 10);
        
        if (targetX > screenWidth / 2.0) {
            self.presetPanel.frame = CGRectMake(-180, 2.5, 175, 45);
        } else {
            self.presetPanel.frame = CGRectMake(55, 2.5, 175, 45);
        }
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.center = CGPointMake(targetX, targetY);
        } completion:nil];

        [self startFadeTimer];
    }
}

- (void)resetFadeTimer {
    [_fadeTimer invalidate];
    _fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(dimMenu) userInfo:nil repeats:NO];
}

- (void)startFadeTimer {
    [self resetFadeTimer];
}

- (void)dimMenu {
    if (self.isExpanded) {
        [self toggleMenu];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0.15;
    }];
}

@end
