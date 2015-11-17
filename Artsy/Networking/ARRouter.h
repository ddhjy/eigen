


@interface ARRouter : NSObject

+ (void)setup;
+ (NSSet *)artsyHosts;
+ (NSURL *)baseApiURL;
+ (NSURL *)baseWebURL;
+ (NSURL *)baseDesktopWebURL;

+ (AFHTTPSessionManager *)httpClient;
+ (void)setupWithBaseApiURL:(NSURL *)baseApiURL;

+ (void)setupUserAgent;
+ (BOOL)isWebURL:(NSURL *)url;

+ (BOOL)isInternalURL:(NSURL *)url;

+ (NSURLRequest *)requestForURL:(NSURL *)url;

#pragma mark - OAuth

+ (void)setAuthToken:(NSString *)token;
+ (NSURLRequest *)newOAuthRequestWithUsername:(NSString *)username password:(NSString *)password;
+ (NSURLRequest *)newTwitterOAuthRequestWithToken:(NSString *)token andSecret:(NSString *)secret;
+ (NSURLRequest *)newFacebookOAuthRequestWithToken:(NSString *)token;

#pragma mark - XApp
+ (void)setXappToken:(NSString *)token;
+ (NSURLRequest *)newXAppTokenRequest;

#pragma mark - User creation

+ (NSURLRequest *)newCreateUserRequestWithName:(NSString *)name email:(NSString *)email password:(NSString *)password;
+ (NSURLRequest *)newCreateUserViaFacebookRequestWithToken:(NSString *)token email:(NSString *)email name:(NSString *)name;
+ (NSURLRequest *)newCreateUserViaTwitterRequestWithToken:(NSString *)token secret:(NSString *)secret email:(NSString *)email name:(NSString *)name;

#pragma mark - User

+ (NSURLRequest *)newUserInfoRequest;
+ (NSURLRequest *)newUserEditRequestWithParams:(NSDictionary *)params;
+ (NSURLRequest *)newCheckFollowingProfileHeadRequest:(NSString *)profileID;
+ (NSURLRequest *)newMyFollowProfileRequest:(NSString *)profileID;
+ (NSURLRequest *)newMyUnfollowProfileRequest:(NSString *)profileID;
+ (NSURLRequest *)newFollowingProfilesRequestWithFair:(Fair *)fair;

#pragma mark - Feed

+ (NSURLRequest *)newFeedRequestWithCursor:(NSString *)cursor pageSize:(NSInteger)size;
+ (NSURLRequest *)newShowFeedRequestWithCursor:(NSString *)cursor pageSize:(NSInteger)size;
+ (NSURLRequest *)newFairShowFeedRequestWithFair:(Fair *)fair partnerID:(NSString *)partnerID cursor:(NSString *)cursor pageSize:(NSInteger)size;
+ (NSURLRequest *)newPostsRequestForProfileID:(NSString *)profileID WithCursor:(NSString *)cursor pageSize:(NSInteger)size;
+ (NSURLRequest *)newPostsRequestForProfile:(Profile *)profile WithCursor:(NSString *)cursor pageSize:(NSInteger)size;
+ (NSURLRequest *)newPostsRequestForFairOrganizer:(FairOrganizer *)fairOrganizer WithCursor:(NSString *)cursor pageSize:(NSInteger)size;

#pragma mark - Artworks

+ (NSURLRequest *)newArtworkInfoRequestForArtworkID:(NSString *)artworkID;
+ (NSURLRequest *)newArtworksRelatedToArtworkRequest:(Artwork *)artwork;
+ (NSURLRequest *)newArtworksRelatedToArtwork:(Artwork *)artwork inFairRequest:(Fair *)fair;
+ (NSURLRequest *)newPostsRelatedToArtwork:(Artwork *)artwork;
+ (NSURLRequest *)newPostsRelatedToArtist:(Artist *)artist;
+ (NSURLRequest *)newArtworkComparablesRequest:(Artwork *)artwork;
+ (NSURLRequest *)newAdditionalImagesRequestForArtworkWithID:(NSString *)artworkID;
+ (NSURLRequest *)newNewArtworksRequestWithParams:(NSDictionary *)params;
+ (NSURLRequest *)newArtistArtworksRequestWithParams:(NSDictionary *)params andArtistID:(NSString *)artistID;


#pragma mark - Artwork Favorites (items in the saved-artwork collection)

+ (NSURLRequest *)newArtworkFavoritesRequestWithFair:(Fair *)fair;
+ (NSURLRequest *)newSetArtworkFavoriteRequestForArtwork:(Artwork *)artwork status:(BOOL)status;
+ (NSURLRequest *)newArtworksFromUsersFavoritesRequestWithID:(NSString *)userID page:(NSInteger)page;
+ (NSURLRequest *)newCheckFavoriteStatusRequestForArtwork:(Artwork *)artwork;
+ (NSURLRequest *)newCheckFavoriteStatusRequestForArtworks:(NSArray *)artworks;
+ (NSURLRequest *)newFairsRequestForArtwork:(Artwork *)artwork;
+ (NSURLRequest *)newShowsRequestForArtworkID:(NSString *)artworkID andFairID:(NSString *)fairID;
+ (NSURLRequest *)newPendingOrderWithArtworkID:(NSString *)artworkID editionSetID:(NSString *)editionSetID;

#pragma mark - Artist

+ (NSURLRequest *)newArtistsFromSampleAtPage:(NSInteger)page;
+ (NSURLRequest *)newArtistsFromPersonalCollectionAtPage:(NSInteger)page;
+ (NSURLRequest *)newArtistCountFromPersonalCollectionRequest;

+ (NSURLRequest *)newArtistInfoRequestWithID:(NSString *)artistID;
+ (NSURLRequest *)newFollowingArtistsRequestWithFair:(Fair *)fair;
+ (NSURLRequest *)newFollowingRequestForArtist:(Artist *)artists;
+ (NSURLRequest *)newFollowingRequestForArtists:(NSArray *)artists;
+ (NSURLRequest *)newFollowArtistRequest:(Artist *)artist;
+ (NSURLRequest *)newUnfollowArtistRequest:(Artist *)artist;

+ (NSURLRequest *)newArtistsRelatedToArtistRequest:(Artist *)artist;
+ (NSURLRequest *)newShowsRequestForArtist:(NSString *)artistID;
+ (NSURLRequest *)newShowsRequestForArtistID:(NSString *)artistID inFairID:(NSString *)fairID;

#pragma mark - Genes

+ (NSURLRequest *)newGeneCountFromPersonalCollectionRequest;
+ (NSURLRequest *)newGenesFromPersonalCollectionAtPage:(NSInteger)page;
+ (NSURLRequest *)newGeneInfoRequestWithID:(NSString *)geneID;
+ (NSURLRequest *)newFollowingRequestForGene:(Gene *)gene;
+ (NSURLRequest *)newFollowGeneRequest:(Gene *)gene;
+ (NSURLRequest *)newUnfollowGeneRequest:(Gene *)gene;
+ (NSURLRequest *)newFollowingRequestForGenes:(NSArray *)genes;
+ (NSURLRequest *)newArtworksFromGeneRequest:(NSString *)gene atPage:(NSInteger)page;

#pragma mark - Shows

+ (NSURLRequest *)newShowInfoRequestWithID:(NSString *)showID;
+ (NSURLRequest *)newArtworksFromShowRequest:(PartnerShow *)show atPage:(NSInteger)page;
+ (NSURLRequest *)newImagesFromShowRequest:(PartnerShow *)show atPage:(NSInteger)page;
+ (NSURLRequest *)newShowsListingRequest;
+ (NSURLRequest *)newRunningShowsListingRequestForLongitude:(CGFloat)longitude latitude:(CGFloat)latitude;

#pragma mark - Models

+ (NSURLRequest *)newPostInfoRequestWithID:(NSString *)postID;
+ (NSURLRequest *)newProfileInfoRequestWithID:(NSString *)profileID;
+ (NSURLRequest *)newArtworkInfoRequestWithID:(NSString *)artworkID;

#pragma mark - Search

+ (NSURLRequest *)newSearchRequestWithQuery:(NSString *)query;
+ (NSURLRequest *)newSearchRequestWithFairID:(NSString *)fairID andQuery:(NSString *)query;
+ (NSURLRequest *)newArtistSearchRequestWithQuery:(NSString *)query;

+ (NSURLRequest *)directImageRequestForModel:(Class)model andSlug:(NSString *)slug;

#pragma mark - Fairs

+ (NSURLRequest *)newFairInfoRequestWithID:(NSString *)fairID;
+ (NSURLRequest *)newFairShowsRequestWithFair:(Fair *)fair;
+ (NSURLRequest *)newFairMapRequestWithFair:(Fair *)fair;
+ (NSURLRequest *)newFollowArtistRequest;
+ (NSURLRequest *)newFollowArtistRequestWithFair:(Fair *)fair;

#pragma mark - Inquiries

+ (NSURLRequest *)newOnDutyRepresentativeRequest;
+ (NSURLRequest *)newArtworkInquiryRequestForArtwork:(Artwork *)artwork
                                                name:(NSString *)name
                                               email:(NSString *)email
                                             message:(NSString *)message
                                 analyticsDictionary:(NSDictionary *)analyticsDictionary
                                shouldContactGallery:(BOOL)contactGallery;

#pragma mark - Auctions

+ (NSURLRequest *)salesWithArtworkRequest:(NSString *)artworkID;
+ (NSURLRequest *)artworksForSaleRequest:(NSString *)saleID;
+ (NSURLRequest *)biddersRequest;
+ (NSURLRequest *)createBidderPositionsForSaleID:(NSString *)saleID artworkID:(NSString *)artworkID maxBidAmountCents:(NSInteger)maxBidAmountCents;
+ (NSURLRequest *)bidderPositionsRequestForSaleID:(NSString *)saleID artworkID:(NSString *)artworkID;
+ (NSURLRequest *)saleArtworkRequestForSaleID:(NSString *)saleID artworkID:(NSString *)artworkID;

#pragma mark - Ordered Sets

+ (NSURLRequest *)orderedSetsWithOwnerType:(NSString *)ownerType andID:(NSString *)ownerID;
+ (NSURLRequest *)orderedSetsWithKey:(NSString *)key;
+ (NSURLRequest *)orderedSetItems:(NSString *)orderedSetID;
+ (NSURLRequest *)orderedSetItems:(NSString *)orderedSetID atPage:(NSInteger)page;

#pragma mark - Recommendations

+ (NSURLRequest *)suggestedHomepageArtworksRequest;
+ (NSURLRequest *)worksForYouRequest;
+ (NSURLRequest *)worksForYouCountRequest;

#pragma mark - Misc Site

+ (NSURLRequest *)newSiteHeroUnitsRequest;
+ (NSURLRequest *)newForgotPasswordRequestWithEmail:(NSString *)email;
+ (NSURLRequest *)newSiteFeaturesRequest;
+ (NSURLRequest *)newSetDeviceAPNTokenRequest:(NSString *)token forDevice:(NSString *)device;
+ (NSURLRequest *)newUptimeURLRequest;
+ (NSURLRequest *)newSystemTimeRequest;
+ (NSURLRequest *)newRequestOutbidNotificationRequest;
+ (NSURLRequest *)newRequestForBlankPage;

@end
