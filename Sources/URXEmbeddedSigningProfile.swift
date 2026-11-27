import Foundation

struct URXEmbeddedSigningProfileSummary {
    let name: String
    let uuid: String
    let teamIdentifier: String
    let applicationIdentifier: String
    let expirationDate: Date
}

enum URXEmbeddedSigningProfile {
    enum ValidationError: LocalizedError {
        case missing
        case invalidPayload
        case expired
        case certificateMismatch
        case missingEntitlements
        case appIdentifierMismatch
        case teamMismatch

        var errorDescription: String? {
            switch self {
            case .missing:
                return "No embedded.mobileprovision was found inside the installed URX Core app. Install URX using a signing method that embeds its development profile."
            case .invalidPayload:
                return "URX's embedded provisioning profile is missing required signing fields."
            case .expired:
                return "URX's embedded provisioning profile has expired."
            case .certificateMismatch:
                return "The imported .p12 certificate is not listed in URX's embedded provisioning profile. Import the certificate used to sign this installed URX build."
            case .missingEntitlements:
                return "URX's embedded profile does not contain the required application identifier entitlement."
            case .appIdentifierMismatch:
                return "URX's embedded profile does not authorize this installed app's bundle identifier."
            case .teamMismatch:
                return "The profile's Team ID and application identifier prefix do not agree."
            }
        }
    }

    static func validate(certificateDER: Data, bundleIdentifier: String, now: Date = Date()) throws -> URXEmbeddedSigningProfileSummary {
        guard let profileURL = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let profileData = try? Data(contentsOf: profileURL),
              !profileData.isEmpty else {
            throw ValidationError.missing
        }

        var decodeError: NSError?
        guard let decoded = URXDecodeProvisioningProfile(profileData as NSData, &decodeError),
              let payload = decoded["content"] as? Data,
              (decoded["signatureVerified"] as? Bool) == true else {
            throw decodeError ?? ValidationError.invalidPayload
        }

        let object = try PropertyListSerialization.propertyList(from: payload, options: [], format: nil)
        guard let profile = object as? [String: Any],
              let name = profile["Name"] as? String,
              let uuid = profile["UUID"] as? String,
              let expiration = profile["ExpirationDate"] as? Date,
              let teams = profile["TeamIdentifier"] as? [String],
              let appPrefixes = profile["ApplicationIdentifierPrefix"] as? [String],
              let entitlements = profile["Entitlements"] as? [String: Any],
              let appIdentifier = entitlements["application-identifier"] as? String,
              let certificates = profile["DeveloperCertificates"] as? [Data],
              !certificates.isEmpty else {
            throw ValidationError.invalidPayload
        }

        guard expiration > now else { throw ValidationError.expired }
        guard certificates.contains(certificateDER) else { throw ValidationError.certificateMismatch }

        guard let team = teams.first, !team.isEmpty else { throw ValidationError.teamMismatch }
        let components = appIdentifier.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count >= 2 else { throw ValidationError.missingEntitlements }
        let appIDPrefix = String(components[0])
        let authorizedBundle = components.dropFirst().joined(separator: ".")
        guard appPrefixes.contains(appIDPrefix) else { throw ValidationError.teamMismatch }
        guard authorizedBundle == "*" || bundleIdentifier == authorizedBundle ||
              (authorizedBundle.hasSuffix(".*") && bundleIdentifier.hasPrefix(String(authorizedBundle.dropLast()) + ".")) else {
            throw ValidationError.appIdentifierMismatch
        }

        return URXEmbeddedSigningProfileSummary(
            name: name,
            uuid: uuid,
            teamIdentifier: team,
            applicationIdentifier: appIdentifier,
            expirationDate: expiration
        )
    }
}
