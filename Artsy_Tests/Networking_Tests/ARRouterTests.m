#import "ARRouter.h"
#import "AROptions.h"
#import "ARNetworkConstants.h"

SpecBegin(ARRouter);

describe(@"requestForURL", ^{
    describe(@"with auth token", ^{
        beforeEach(^{
            [ARRouter setAuthToken:@"token"];
        });
        
        afterEach(^{
            [ARRouter setAuthToken:nil];
        });

        it(@"sets router auth token for Artsy URLs", ^{
            NSURLRequest *request = [ARRouter requestForURL:[NSURL URLWithString:@"http://m.artsy.net"]];
            expect([request valueForHTTPHeaderField:ARAuthHeader]).to.equal(@"token");
        });

        it(@"doesn't set auth token for external URLs", ^{
            NSURLRequest *request = [ARRouter requestForURL:[NSURL URLWithString:@"http://example.com"]];
            expect([request valueForHTTPHeaderField:ARAuthHeader]).to.beNil();
        });
    });
    
    describe(@"with xapp token", ^{
        beforeEach(^{
            [ARRouter setXappToken:@"token"];
        });
        
        afterEach(^{
            [ARRouter setXappToken:nil];
        });
        
        it(@"sets router xapp token for Artsy URLs", ^{
            NSURLRequest *request = [ARRouter requestForURL:[NSURL URLWithString:@"http://m.artsy.net"]];
            expect([request valueForHTTPHeaderField:ARXappHeader]).to.equal(@"token");
        });
        
        it(@"doesn't set xapp token for external URLs", ^{
            NSURLRequest *request = [ARRouter requestForURL:[NSURL URLWithString:@"http://example.com"]];
            expect([request valueForHTTPHeaderField:ARXappHeader]).to.beNil();
        });
    });
});

describe(@"isInternalURL", ^{
    it(@"returns true with a touch link", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"applewebdata://internal"];
        expect([ARRouter isInternalURL:url]).to.beTruthy();
    });

    it(@"returns true with an artsy link", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"artsy://internal"];
        expect([ARRouter isInternalURL:url]).to.beTruthy();
    });

    it(@"returns true with an artsy www", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"http://www.artsy.net/thing"];
        expect([ARRouter isInternalURL:url]).to.beTruthy();
    });

    it(@"returns true for any artsy url", ^{
        NSSet *artsyHosts = [ARRouter artsyHosts];
        for (NSString *host in artsyHosts){
            NSURL *url = [[NSURL alloc] initWithString:NSStringWithFormat(@"%@/some/path", host)];
            expect([ARRouter isInternalURL:url]).to.beTruthy();
        }
    });
    
    it(@"returns false for external urls", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"http://externalurl.com/path"];
        expect([ARRouter isInternalURL:url]).to.beFalsy();
    });
    
    it(@"returns true for relative urls", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"/relative/url"];
        expect([ARRouter isInternalURL:url]).to.beTruthy();
    });
});

describe(@"isWebURL", ^{
    it(@"returns true with a http link", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"http://internal"];
        expect([ARRouter isWebURL:url]).to.beTruthy();
    });
    
    it(@"returns true with a link without a scheme", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"internal"];
        expect([ARRouter isWebURL:url]).to.beTruthy();
    });
    
    it(@"returns true with a https link", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"https://internal"];
        expect([ARRouter isWebURL:url]).to.beTruthy();
    });
    
    it(@"returns false for mailto: urls", ^{
        NSURL *url = [[NSURL alloc] initWithString:@"mailto:orta.therox@gmail.com"];
        expect([ARRouter isWebURL:url]).to.beFalsy();
    });
});

describe(@"User-Agent", ^{
    __block NSString *userAgent = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserAgent"];

    it(@"uses Artsy-Mobile hard-coded in Microgravity", ^{
        expect(userAgent).to.contain(@"Artsy-Mobile/");
    });
    
    it(@"contains compatibility strings", ^{
        expect(userAgent).to.contain(@"AppleWebKit/");
        expect(userAgent).to.contain(@"KHTML");
    });

    it(@"uses Eigen", ^{
        expect(userAgent).to.contain(@"Eigen/");
    });
    
    it(@"contains version number", ^{
        expect(userAgent).to.contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
    });
    
    it(@"contains build number", ^{
        expect(userAgent).to.contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
    });

    it(@"is contained in requests sent out from router", ^{

        Artwork *artwork = [Artwork modelWithJSON:@{ @"id": @"artwork_id" }];
        NSURLRequest *request = [ARRouter newArtworkInquiryRequestForArtwork:artwork name:@"name" email:@"email.com" message:@"message" analyticsDictionary:@{} shouldContactGallery:NO];

        expect([request.allHTTPHeaderFields objectForKey:@"User-Agent"]).to.beTruthy();
        expect(request.allHTTPHeaderFields[@"User-Agent"]).to.equal(userAgent);

        request = [ARRouter newOnDutyRepresentativeRequest];
        expect(request.allHTTPHeaderFields[@"User-Agent"]).to.equal(userAgent);

        request = [ARRouter newGenesFromPersonalCollectionAtPage:0];
        expect(request.allHTTPHeaderFields[@"User-Agent"]).to.equal(userAgent);

        request = [ARRouter newShowsRequestForArtist:@"orta"];
        expect(request.allHTTPHeaderFields[@"User-Agent"]).to.equal(userAgent);
    });
});

describe(@"baseWebURL", ^{
    beforeEach(^{
        [AROptions setBool:false forOption:ARUseStagingDefault];
        [ARRouter setup];
    });
    
    it(@"points to artsy mobile on iphone", ^{
        expect([ARRouter baseWebURL]).to.equal([NSURL URLWithString:@"https://m.artsy.net"]);
    });
    
    it(@"points to artsy web on ipad", ^{
        [ARTestContext stubDevice:ARDeviceTypePad];
        expect([ARRouter baseWebURL]).to.equal([NSURL URLWithString:@"https://www.artsy.net"]);
        [ARTestContext stopStubbing];
    });
});

SpecEnd;
