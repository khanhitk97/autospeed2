#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
extern void set_speed_factor(float factor);
#ifdef __cplusplus
}
#endif

@interface SpeedhackMenu : UIView
@property (nonatomic, strong) UIButton *mainBtn;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *btnOff;
@property (nonatomic, strong) UIButton *btnOn;
@property (nonatomic, strong) NSTimer *fadeTimer;
@property (nonatomic, assign) BOOL isEnabled;
@end

@implementation SpeedhackMenu

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                        if (w.isKeyWindow) { window = w; break; }
                    }
                }
            }
        }
        if (window) [window addSubview:[[SpeedhackMenu alloc] initWithFrame:CGRectMake(20, 150, 50, 50)]];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isEnabled = YES; // Mặc định mở game là BẬT 5x
        set_speed_factor(5.0f);

        // Nút tròn chính
        _mainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _mainBtn.frame = CGRectMake(0, 0, 50, 50);
        _mainBtn.layer.cornerRadius = 25;
        _mainBtn.layer.borderWidth = 2;
        _mainBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _mainBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        [_mainBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_mainBtn];

        // Gesture kéo thả
        [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];

        // Thanh mở rộng
        _panel = [[UIView alloc] initWithFrame:CGRectMake(55, 2.5, 175, 45)];
        _panel.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.95];
        _panel.layer.cornerRadius = 12;
        _panel.layer.borderWidth = 1.5;
        _panel.layer.borderColor = [UIColor colorWithRed:0.1 green:0.55 blue:1.0 alpha:1.0].CGColor;
        _panel.hidden = YES;
        _panel.alpha = 0.0;

        _btnOff = [self makeBtn:@"1: TẮT" tag:1 frame:CGRectMake(8, 7.5, 75, 30)];
        _btnOn = [self makeBtn:@"2: BẬT" tag:2 frame:CGRectMake(91, 7.5, 75, 30)];
        [_panel addSubview:_btnOff];
        [_panel addSubview:_btnOn];
        [self addSubview:_panel];

        [self updateUI];
        self.alpha = 0.15;
    }
    return self;
}

// XỬ LÝ NHẬN DIỆN CẢM ỨNG NGOÀI PHẠM VI 50x50
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha < 0.01) return nil;

    CGPoint mainPoint = [self convertPoint:point toView:self.mainBtn];
    if ([self.mainBtn pointInside:mainPoint withEvent:event]) {
        return self.mainBtn;
    }

    if (!self.panel.hidden && self.panel.alpha > 0.01) {
        CGPoint panelPoint = [self convertPoint:point toView:self.panel];
        if ([self.panel pointInside:panelPoint withEvent:event]) {
            return [self.panel hitTest:panelPoint withEvent:event];
        }
    }
    return nil;
}

- (UIButton *)makeBtn:(NSString *)title tag:(NSInteger)tag frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.tag = tag;
    btn.layer.cornerRadius = 8;
    btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)updateUI {
    if (_isEnabled) {
        [_mainBtn setTitle:@"⚡️5x" forState:UIControlStateNormal];
        _mainBtn.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.38 alpha:0.9];
        _btnOn.backgroundColor = [UIColor colorWithRed:0.15 green:0.68 blue:0.38 alpha:1.0];
        [_btnOn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnOff.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.25 alpha:1.0];
        [_btnOff setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else {
        [_mainBtn setTitle:@"OFF" forState:UIControlStateNormal];
        _mainBtn.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.20 alpha:0.9];
        _btnOff.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.20 alpha:1.0];
        [_btnOff setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnOn.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.25 alpha:1.0];
        [_btnOn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (void)btnTapped:(UIButton *)sender {
    [self resetTimer];
    self.alpha = 1.0;
    _isEnabled = (sender.tag == 2);
    set_speed_factor(_isEnabled ? 5.0f : 1.0f);
    [self updateUI];
}

- (void)toggleMenu {
    [self resetTimer];
    self.alpha = 1.0;
    BOOL willShow = _panel.hidden;
    if (willShow) _panel.hidden = NO;

    [UIView animateWithDuration:0.25 animations:^{
        self.panel.alpha = willShow ? 1.0 : 0.0;
    } completion:^(BOOL f) {
        if (!willShow) self.panel.hidden = YES;
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    [self resetTimer];
    self.alpha = 1.0;
    CGPoint trans = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + trans.x, self.center.y + trans.y);
    [pan setTranslation:CGPointZero inView:self.superview];

    if (pan.state == UIGestureRecognizerStateEnded) {
        CGFloat screenW = self.superview.bounds.size.width;
        CGFloat targetX = (self.center.x < screenW / 2.0) ? 35 : (screenW - 35);
        _panel.frame = (targetX > screenW / 2.0) ? CGRectMake(-180, 2.5, 175, 45) : CGRectMake(55, 2.5, 175, 45);

        [UIView animateWithDuration:0.25 animations:^{
            self.center = CGPointMake(targetX, self.center.y);
        }];
        [self resetTimer];
    }
}

- (void)resetTimer {
    [_fadeTimer invalidate];
    _fadeTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(dim) userInfo:nil repeats:NO];
}

- (void)dim {
    if (!_panel.hidden) [self toggleMenu];
    [UIView animateWithDuration:0.4 animations:^{ self.alpha = 0.15; }];
}

@end
