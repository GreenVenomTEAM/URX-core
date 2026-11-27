#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Decodes an embedded CMS provisioning profile and verifies its CMS signer
/// and certificate chain using Apple's Security framework.
FOUNDATION_EXPORT NSDictionary * _Nullable URXDecodeProvisioningProfile(
    NSData *data,
    NSError * _Nullable * _Nullable error
);

NS_ASSUME_NONNULL_END
