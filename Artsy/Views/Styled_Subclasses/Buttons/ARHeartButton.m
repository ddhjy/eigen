#import "ARHeartButton.h"


@interface ARHeartButton ()
// Front = Active, back = inactive
@property (nonatomic, strong) UIImageView *frontView;
@property (nonatomic, strong) UIImageView *backView;
@end


@implementation ARHeartButton

- (instancetype)init
{
    self = [super initWithImageName:nil];
    if (!self) {
        return nil;
    }

    [self setImage:nil forState:UIControlStateNormal];

    CGFloat dimension = [self.class buttonSize];

    UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Heart_Black"]];
    backView.frame = CGRectMake(0, 0, dimension, dimension);
    backView.contentMode = UIViewContentModeCenter;
    _backView = backView;

    CALayer *whiteLayer = _backView.layer;
    whiteLayer.borderColor = [UIColor artsyLightGrey].CGColor;
    whiteLayer.borderWidth = 1;
    whiteLayer.cornerRadius = dimension * .5f;
    whiteLayer.backgroundColor = [UIColor whiteColor].CGColor;

    UIImageView *frontView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Heart_White"]];
    frontView.frame = CGRectMake(0, 0, dimension, dimension);
    frontView.contentMode = UIViewContentModeCenter;
    _frontView = frontView;

    CALayer *purpleLayer = _frontView.layer;
    purpleLayer.backgroundColor = [UIColor artsyPurple].CGColor;
    purpleLayer.borderColor = [UIColor whiteColor].CGColor;
    purpleLayer.cornerRadius = dimension * .5f;

    _status = ARHeartStatusNotFetched;

    self.enabled = NO;

    [self addSubview:self.backView];
    self.layer.borderWidth = 1;

    return self;
}

- (BOOL)isHearted
{
    return (self.status == ARHeartStatusYes);
}

- (void)setHearted:(BOOL)hearted
{
    [self setHearted:hearted animated:NO];
}

- (void)setHearted:(BOOL)hearted animated:(BOOL)animated
{
    [self setStatus:(hearted ? ARHeartStatusYes : ARHeartStatusNo)animated:animated];
}

- (void)setStatus:(ARHeartStatus)status
{
    [self setStatus:status animated:NO];
}

- (void)setStatus:(ARHeartStatus)status animated:(BOOL)animated
{
    if (_status == status) {
        return;
    }

    self.enabled = (status != ARHeartStatusNotFetched);

    // only animate when changing from unset/no -> yes or yes -> unset/no
    if (_status != ARHeartStatusYes && status != ARHeartStatusYes) {
        _status = status;
        return;
    }

    _status = status;

   @weakify(self);
    void (^animation)() = ^() {
        @strongify(self);
        if (status == ARHeartStatusYes) {
            [self.backView removeFromSuperview];
            [self addSubview:self.frontView];
            self.layer.borderWidth = 0;
        } else {
            [self.frontView removeFromSuperview];
            [self addSubview:self.backView];
            self.layer.borderWidth = 1;
        }
    };

    if (animated) {
        [UIView transitionWithView:self
                          duration:ARAnimationDuration
                           options:UIViewAnimationOptionTransitionFlipFromBottom
                        animations:animation
                        completion:NULL];
    } else {
        animation();
    }
}

@end
