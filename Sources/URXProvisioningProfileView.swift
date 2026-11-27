import SwiftUI
import UniformTypeIdentifiers
import Security

struct URXProvisioningProfileView: View {
    @State private var showingImporter = false
    @State private var status = "Import a .mobileprovision file after importing your signing identity."
    @State private var isSuccess = false
    @State private var isChecking = false
    @State private var summary: URXProvisioningProfileSummary?
    @State private var hasSavedProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "doc.badge.gearshape")
                            .font(.system(size: 36))
                            .foregroundStyle(.green)
                        Text("Provisioning profile")
                            .font(.largeTitle.bold())
                        Text("A profile connects your Apple signing identity to an App ID, team and permitted capabilities. URX verifies its CMS signature before saving it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import .mobileprovision", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isChecking)

                        Text("The signing identity must already be imported in the Identity tab.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

                    if let summary {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("PROFILE VERIFIED", systemImage: "checkmark.seal.fill")
                                    .font(.caption.weight(.bold))
                                    .tracking(0.8)
                                    .foregroundStyle(.green)
                                Spacer()
                                Text(summary.profileType.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(summary.name)
                                .font(.title2.bold())
                            profileRow("Team ID", summary.teamID)
                            profileRow("App ID", summary.applicationIdentifier)
                            profileRow("UUID", summary.uuid)
                            profileRow("Expires", summary.expiration.formatted(date: .abbreviated, time: .shortened))
                            profileRow("Certificates", "\(summary.certificateCount) included")
                            profileRow("Devices", summary.deviceDescription)
                            Text("CMS signature verified by Apple Security. The imported signing certificate matches one of the profile's DeveloperCertificates.")
                                .font(.footnote)
                                .foregroundStyle(.green)
                                .padding(.top, 4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(isSuccess ? .green : .secondary)
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(isSuccess ? .green : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(15)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                    if hasSavedProfile {
                        Button(role: .destructive) {
                            do {
                                try URXProvisioningProfileStore.remove()
                                hasSavedProfile = false
                                summary = nil
                                status = "Saved provisioning profile removed."
                                isSuccess = false
                            } catch {
                                status = "Could not remove saved profile: \(error.localizedDescription)"
                                isSuccess = false
                            }
                        } label: {
                            Label("Remove saved profile", systemImage: "trash")
                        }
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Label("Local processing", systemImage: "lock.shield.fill")
                            .font(.headline)
                        Text("The profile is verified and stored locally in URX's app container. No profile data or device identifiers are uploaded.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "mobileprovision") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: handleSelection
            )
            .onAppear(perform: restoreSavedProfile)
        }
    }

    private func profileRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func handleSelection(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }

            var coordinationError: NSError?
            var readError: Error?
            var fileData: Data?
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: readableURL.path)
                    let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
                    guard size > 0, size <= 8 * 1024 * 1024 else {
                        throw URXProvisioningProfileError.invalidSize
                    }
                    fileData = try Data(contentsOf: readableURL, options: [.mappedIfSafe])
                } catch {
                    readError = error
                }
            }
            if let coordinationError { throw coordinationError }
            if let readError { throw readError }
            guard let fileData else { throw URXProvisioningProfileError.emptyFile }
            try inspect(fileData, persist: true)
        } catch {
            status = error.localizedDescription
            isSuccess = false
        }
    }

    private func inspect(_ data: Data, persist: Bool) throws {
        var decoderError: NSError?
        guard let decoded = URXDecodeProvisioningProfile(data as NSData, &decoderError),
              let content = decoded["content"] as? Data,
              (decoded["signatureVerified"] as? Bool) == true else {
            throw decoderError ?? URXProvisioningProfileError.signatureRejected
        }

        let propertyList = try PropertyListSerialization.propertyList(from: content, options: [], format: nil)
        guard let profile = propertyList as? [String: Any] else {
            throw URXProvisioningProfileError.invalidPropertyList
        }

        guard let name = profile["Name"] as? String,
              let uuid = profile["UUID"] as? String,
              let expiration = profile["ExpirationDate"] as? Date,
              let teamIDs = profile["TeamIdentifier"] as? [String],
              let entitlements = profile["Entitlements"] as? [String: Any],
              let applicationIdentifier = entitlements["application-identifier"] as? String,
              let developerCertificates = profile["DeveloperCertificates"] as? [Data],
              !developerCertificates.isEmpty else {
            throw URXProvisioningProfileError.missingFields
        }

        guard expiration > Date() else { throw URXProvisioningProfileError.expired }
        guard let teamID = teamIDs.first, !teamID.isEmpty else {
            throw URXProvisioningProfileError.missingTeam
        }

        let localCertificate = try URXCertificateVault.currentCertificateDER()
        guard developerCertificates.contains(where: { $0 == localCertificate }) else {
            throw URXProvisioningProfileError.certificateMismatch
        }

        let devices = profile["ProvisionedDevices"] as? [String] ?? []
        let allDevices = profile["ProvisionsAllDevices"] as? Bool ?? false
        let allowsDevelopment = entitlements["get-task-allow"] as? Bool ?? false
        let profileType: String
        if allDevices {
            profileType = "Enterprise"
        } else if allowsDevelopment {
            profileType = "Development"
        } else if !devices.isEmpty {
            profileType = "Ad Hoc"
        } else {
            profileType = "App Store"
        }

        let deviceDescription: String
        if allDevices {
            deviceDescription = "All devices"
        } else if !devices.isEmpty {
            deviceDescription = "\(devices.count) registered"
        } else {
            deviceDescription = "No device list"
        }

        let result = URXProvisioningProfileSummary(
            name: name,
            uuid: uuid,
            teamID: teamID,
            applicationIdentifier: applicationIdentifier,
            expiration: expiration,
            certificateCount: developerCertificates.count,
            profileType: profileType,
            deviceDescription: deviceDescription
        )

        if persist {
            try URXProvisioningProfileStore.save(data)
        }
        summary = result
        hasSavedProfile = true
        status = "Profile signature verified, expiry checked, and signing certificate matched. Profile saved locally."
        isSuccess = true
    }

    private func restoreSavedProfile() {
        guard summary == nil else { return }
        do {
            guard let data = try URXProvisioningProfileStore.load() else { return }
            try inspect(data, persist: false)
        } catch {
            status = "A saved profile is present but is no longer usable: \(error.localizedDescription)"
            isSuccess = false
            hasSavedProfile = true
        }
    }
}

private struct URXProvisioningProfileSummary {
    let name: String
    let uuid: String
    let teamID: String
    let applicationIdentifier: String
    let expiration: Date
    let certificateCount: Int
    let profileType: String
    let deviceDescription: String
}

private enum URXProvisioningProfileStore {
    static func fileURL() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("URXSigning", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("embedded.mobileprovision")
    }

    static func save(_ data: Data) throws {
        try data.write(to: fileURL(), options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    static func load() throws -> Data? {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    static func remove() throws {
        let url = try fileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

private enum URXProvisioningProfileError: LocalizedError {
    case invalidSize
    case emptyFile
    case signatureRejected
    case invalidPropertyList
    case missingFields
    case expired
    case missingTeam
    case certificateMismatch

    var errorDescription: String? {
        switch self {
        case .invalidSize: return "The profile is empty or larger than 8 MB."
        case .emptyFile: return "The selected profile could not be read."
        case .signatureRejected: return "Apple Security could not verify the profile's CMS signature."
        case .invalidPropertyList: return "The signed profile does not contain a valid property list."
        case .missingFields: return "The profile is missing required signing fields."
        case .expired: return "This provisioning profile has expired."
        case .missingTeam: return "The profile does not declare a Team ID."
        case .certificateMismatch: return "The imported signing certificate is not included in this provisioning profile."
        }
    }
}
