#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Parses a PKCS#12 identity with OpenSSL and re-encodes it using a broadly
/// compatible 3DES/SHA-1 PBE profile for Apple's Security.framework importer.
/// All processing stays in memory; private-key material is never written to disk.
FOUNDATION_EXPORT NSData * _Nullable URXNormalizePKCS12(
    NSData *input,
    NSString *password,
    NSError * _Nullable * _Nullable error
);

NS_ASSUME_NONNULL_END
