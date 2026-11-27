#import "URXProvisioningProfileDecoder.h"
#import <Security/Security.h>
#import <openssl/cms.h>
#import <openssl/err.h>
#import <openssl/x509.h>
#import <openssl/bio.h>

static NSString * const URXProfileDecoderErrorDomain = @"team.greenvn.urx.provisioning-profile";

static NSError *URXProfileError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:URXProfileDecoderErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

NSDictionary *URXDecodeProvisioningProfile(NSData *data, NSError **error) {
    if (data.length == 0 || data.length > 8 * 1024 * 1024) {
        if (error) *error = URXProfileError(1, @"Provisioning profile is empty or exceeds the 8 MB safety limit.");
        return nil;
    }

    const unsigned char *cursor = data.bytes;
    CMS_ContentInfo *cms = d2i_CMS_ContentInfo(NULL, &cursor, (long)data.length);
    if (cms == NULL || cursor != (const unsigned char *)data.bytes + data.length) {
        if (cms) CMS_ContentInfo_free(cms);
        if (error) *error = URXProfileError(2, @"Provisioning profile is not a valid DER-encoded CMS message.");
        return nil;
    }

    BIO *contentBIO = BIO_new(BIO_s_mem());
    if (contentBIO == NULL) {
        CMS_ContentInfo_free(cms);
        if (error) *error = URXProfileError(3, @"Could not allocate a CMS content buffer.");
        return nil;
    }

    // Verify the CMS cryptographic signature first. Certificate trust is evaluated
    // separately with Apple's public Security framework below.
    int verified = CMS_verify(cms, NULL, NULL, NULL, contentBIO,
                              CMS_BINARY | CMS_NO_SIGNER_CERT_VERIFY);
    if (verified != 1) {
        unsigned long opensslError = ERR_get_error();
        char errorBuffer[256] = {0};
        if (opensslError) ERR_error_string_n(opensslError, errorBuffer, sizeof(errorBuffer));
        NSString *detail = opensslError
            ? [NSString stringWithUTF8String:errorBuffer]
            : @"CMS signature verification failed.";
        if (error) *error = URXProfileError(4, [NSString stringWithFormat:@"Provisioning profile signature is invalid: %@.", detail]);
        BIO_free(contentBIO);
        CMS_ContentInfo_free(cms);
        return nil;
    }

    STACK_OF(X509) *signers = CMS_get0_signers(cms);
    STACK_OF(X509) *embeddedCertificates = CMS_get1_certs(cms);
    if (signers == NULL || sk_X509_num(signers) < 1) {
        if (signers) sk_X509_free(signers);
        if (embeddedCertificates) sk_X509_pop_free(embeddedCertificates, X509_free);
        BIO_free(contentBIO);
        CMS_ContentInfo_free(cms);
        if (error) *error = URXProfileError(5, @"The profile does not contain a CMS signer certificate.");
        return nil;
    }

    NSMutableArray *trustCertificates = [NSMutableArray array];
    X509 *signer = sk_X509_value(signers, 0);
    int certificateCount = embeddedCertificates ? sk_X509_num(embeddedCertificates) : 0;
    BOOL signerAdded = NO;

    for (int index = 0; index < certificateCount; index++) {
        X509 *certificate = sk_X509_value(embeddedCertificates, index);
        int derLength = i2d_X509(certificate, NULL);
        if (derLength <= 0) continue;
        NSMutableData *der = [NSMutableData dataWithLength:(NSUInteger)derLength];
        unsigned char *derCursor = der.mutableBytes;
        if (i2d_X509(certificate, &derCursor) != derLength) continue;
        SecCertificateRef secCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)der);
        if (secCertificate) {
            [trustCertificates addObject:(__bridge id)secCertificate];
            if (X509_cmp(certificate, signer) == 0) signerAdded = YES;
            CFRelease(secCertificate);
        }
    }

    if (!signerAdded) {
        int derLength = i2d_X509(signer, NULL);
        if (derLength > 0) {
            NSMutableData *der = [NSMutableData dataWithLength:(NSUInteger)derLength];
            unsigned char *derCursor = der.mutableBytes;
            if (i2d_X509(signer, &derCursor) == derLength) {
                SecCertificateRef secCertificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)der);
                if (secCertificate) {
                    [trustCertificates insertObject:(__bridge id)secCertificate atIndex:0];
                    CFRelease(secCertificate);
                }
            }
        }
    }

    BOOL trusted = NO;
    if (trustCertificates.count > 0) {
        SecPolicyRef policy = SecPolicyCreateBasicX509();
        SecTrustRef trust = NULL;
        OSStatus trustStatus = SecTrustCreateWithCertificates((__bridge CFArrayRef)trustCertificates, policy, &trust);
        if (trustStatus == errSecSuccess && trust != NULL) {
            trusted = SecTrustEvaluateWithError(trust, NULL);
            CFRelease(trust);
        }
        if (policy) CFRelease(policy);
    }

    sk_X509_free(signers);
    if (embeddedCertificates) sk_X509_pop_free(embeddedCertificates, X509_free);

    if (!trusted) {
        BIO_free(contentBIO);
        CMS_ContentInfo_free(cms);
        if (error) *error = URXProfileError(6, @"The CMS signature is valid, but its signer certificate chain could not be trusted by iOS.");
        return nil;
    }

    char *contentBytes = NULL;
    long contentLength = BIO_get_mem_data(contentBIO, &contentBytes);
    if (contentLength <= 0 || contentBytes == NULL) {
        BIO_free(contentBIO);
        CMS_ContentInfo_free(cms);
        if (error) *error = URXProfileError(7, @"The signed profile did not contain an embedded property list.");
        return nil;
    }

    NSData *payload = [NSData dataWithBytes:contentBytes length:(NSUInteger)contentLength];
    BIO_free(contentBIO);
    CMS_ContentInfo_free(cms);

    return @{
        @"content": payload,
        @"signatureVerified": @YES,
        @"signerCount": @1
    };
}
