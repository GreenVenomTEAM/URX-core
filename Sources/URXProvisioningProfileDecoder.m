#import "URXProvisioningProfileDecoder.h"
#import <Security/Security.h>
#import <Security/SecCMS.h>

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

    CMSDecoderRef decoder = NULL;
    OSStatus status = CMSDecoderCreate(&decoder);
    if (status != errSecSuccess || decoder == NULL) {
        if (error) *error = URXProfileError(status, [NSString stringWithFormat:@"Could not create CMS decoder (%d).", (int)status]);
        return nil;
    }

    status = CMSDecoderUpdateMessage(decoder, data.bytes, data.length);
    if (status == errSecSuccess) {
        status = CMSDecoderFinalizeMessage(decoder);
    }
    if (status != errSecSuccess) {
        if (error) *error = URXProfileError(status, [NSString stringWithFormat:@"Provisioning profile CMS data is invalid (%d).", (int)status]);
        CFRelease(decoder);
        return nil;
    }

    size_t signerCount = 0;
    status = CMSDecoderGetNumSigners(decoder, &signerCount);
    if (status != errSecSuccess || signerCount == 0) {
        if (error) *error = URXProfileError(status, @"The profile does not contain a CMS signature.");
        CFRelease(decoder);
        return nil;
    }

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CMSSignerStatus signerStatus = kCMSSignerUnsigned;
    SecTrustRef trust = NULL;
    OSStatus certificateStatus = errSecSuccess;
    status = CMSDecoderCopySignerStatus(decoder, 0, policy, true, &signerStatus, &trust, &certificateStatus);

    if (trust) CFRelease(trust);
    if (policy) CFRelease(policy);

    if (status != errSecSuccess || signerStatus != kCMSSignerValid) {
        NSString *message = [NSString stringWithFormat:
            @"The provisioning profile signature or signer trust could not be verified (CMS: %d, signer: %u, certificate: %d).",
            (int)status, (unsigned int)signerStatus, (int)certificateStatus];
        if (error) *error = URXProfileError(status != errSecSuccess ? status : certificateStatus, message);
        CFRelease(decoder);
        return nil;
    }

    CFDataRef content = NULL;
    status = CMSDecoderCopyContent(decoder, &content);
    CFRelease(decoder);

    if (status != errSecSuccess || content == NULL) {
        if (error) *error = URXProfileError(status, @"The signed profile did not contain an embedded property list.");
        if (content) CFRelease(content);
        return nil;
    }

    NSData *payload = [NSData dataWithData:(__bridge NSData *)content];
    CFRelease(content);
    return @{
        @"content": payload,
        @"signatureVerified": @YES,
        @"signerCount": @(signerCount)
    };
}
