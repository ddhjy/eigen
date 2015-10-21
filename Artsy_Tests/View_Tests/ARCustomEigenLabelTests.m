#import "ARTestHelper.h"

#import "ARCustomEigenLabels.h"

SpecBegin(ARCustomEigenLabels);

describe(@"ARArtworkTitleLabel", ^{
    __block ARArtworkTitleLabel *titleLabel;

    before(^{
        titleLabel = [[ARArtworkTitleLabel alloc] init];
    });

    it(@"formats title and date", ^{
        [titleLabel setTitle:@"Title" date:@"2014"];
        expect(titleLabel.text).to.equal(@"Title, 2014");
    });

    it(@"formats title and nil date", ^{
        [titleLabel setTitle:@"Title" date:nil];
        expect(titleLabel.text).to.equal(@"Title");
    });

    it(@"formats title and emptystring date", ^{
        [titleLabel setTitle:@"Title" date:@""];
        expect(titleLabel.text).to.equal(@"Title");
    });

    it(@"formats date and nil title", ^{
        [titleLabel setTitle:nil date:@"2014"];
        expect(titleLabel.text).to.equal(@"2014");
    });

    it(@"formats date and emptystring title", ^{
        [titleLabel setTitle:@"" date:@"2014"];
        expect(titleLabel.text).to.equal(@"2014");
    });

    it(@"is empty string with nil title and date", ^{
        [titleLabel setTitle:nil date:nil];
        expect(titleLabel.text).to.equal(@"");
    });

    it(@"is emptystring with emptystring title", ^{
        [titleLabel setTitle:@"" date:@""];
        expect(titleLabel.text).to.equal(@"");
    });
});

describe(@"ARWarningView", ^{
    it(@"looks correct", ^{
        ARWarningView *warningLabel = [[ARWarningView alloc] initWithFrame:CGRectMake(0, 0, 640, 40)];
        warningLabel.text = @"Life’s big changes rarely give advance warning.";
        expect(warningLabel).to.haveValidSnapshot();
    });
});

SpecEnd;
