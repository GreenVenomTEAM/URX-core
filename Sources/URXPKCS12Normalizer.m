#import "URXPKCS12Normalizer.h"
#import <OpenSSL/OpenSSL.h>

static NSString * const URXPKCS12ErrorDomain = @"team.greenvn.urx.pkcs12";

static NSError *URXPKCS12MakeError(NSInteger code, NSString *message) {
    unsigned long opensslCode = ERR_get_error();
    if (opensslCode != 0) {
        char buffer[256] = {0};
        ERR_error_string_n(opensslCode, buffer, sizeof(buffer));
        message = [NSString stringWithFormat:@"%@ OpenSSL: %s", message, buffer];
    }
    ERR_clear_error();
    return [NSError errorWithDomain:URXPKCS12ErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

NSData * _Nullable URXNormalizePKCS12(NSData *input,
                                      NSString *password,
                                      NSError * _Nullable * _Nullable error) {
    if (input.length == 0 || password == nil) {
        if (error) {
            *error = URXPKCS12MakeError(1, @"The PKCS#12 input or password is empty.");
        }
        return nil;
    }

    const unsigned char *inputStart = (const unsigned char *)input.bytes;
    const unsigned char *readCursor = inputStart;
    PKCS12 *source = d2i_PKCS12(NULL, &readCursor, (long)input.length);
    if (source == NULL || readCursor != inputStart + input.length) {
        if (source != NULL) PKCS12_free(source);
        if (error) {
            *error = URXPKCS12MakeError(2, @"The file is not a complete DER-encoded PKCS#12 container.");
        } else {
            ERR_clear_error();
        }
        return nil;
    }

    EVP_PKEY *privateKey = NULL;
    X509 *certificate = NULL;
    STACK_OF(X509) *certificateChain = NULL;
    const char *passphrase = password.UTF8String;

    if (PKCS12_parse(source, passphrase, &privateKey, &certificate, &certificateChain) != 1 ||
        privateKey == NULL || certificate == NULL) {
        if (privateKey != NULL) EVP_PKEY_free(privateKey);
        if (certificate != NULL) X509_free(certificate);
        if (certificateChain != NULL) sk_X509_pop_free(certificateChain, X509_free);
        PKCS12_free(source);
        if (error) {
            *error = URXPKCS12MakeError(3, @"OpenSSL could not verify the PKCS#12 password or extract its identity.");
        } else {
            ERR_clear_error();
        }
        return nil;
    }

    // Re-encode with a conservative PKCS#12 PBE profile. This does not weaken
    // the imported identity: the new container remains password-protected.
    PKCS12 *normalized = PKCS12_create(
        passphrase,
        "URX Core Signing Identity",
        privateKey,
        certificate,
        certificateChain,
        NID_pbe_WithSHA1And3_Key_TripleDES_CBC,
        NID_pbe_WithSHA1And3_Key_TripleDES_CBC,
        2048,
        2048,
        0
    );

    NSData *result = nil;
    if (normalized != NULL) {
        int encodedLength = i2d_PKCS12(normalized, NULL);
        if (encodedLength > 0) {
            NSMutableData *encoded = [NSMutableData dataWithLength:(NSUInteger)encodedLength];
            unsigned char *writeCursor = (unsigned char *)encoded.mutableBytes;
            int writtenLength = i2d_PKCS12(normalized, &writeCursor);
            if (writtenLength == encodedLength) {
                result = [encoded copy];
            }
        }
    }

    if (normalized != NULL) PKCS12_free(normalized);
    if (certificateChain != NULL) sk_X509_pop_free(certificateChain, X509_free);
    if (certificate != NULL) X509_free(certificate);
    if (privateKey != NULL) EVP_PKEY_free(privateKey);
    PKCS12_free(source);

    if (result == nil && error) {
        *error = URXPKCS12MakeError(4, @"OpenSSL parsed the identity but could not create a compatible PKCS#12 container.");
    } else if (result == nil) {
        ERR_clear_error();
    }
    return result;
}
