import SwiftUI
import Security
import UniformTypeIdentifiers

struct CertificateImportView: View {
    @State private var showingImporter = false
    @State private var selectedFile: URL?
    @State private var password = ""
    @State private var status = "Choose a .p12 or .pfx file to begin."
    @State private var isSuccess = false
    @State private var isChecking = false
    @State private var hasStoredIdentity = false
    @FocusState private var passwordFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 9) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.green)
                        Text("Signing identity")
                            .font(.largeTitle.bold())
                        Text("Select a PKCS#12 file and enter its password. URX will verify the identity and securely save it in the iOS Keychain for later use.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 14) {
                        stepLabel("01", "SELECT FILE")
                        Button {
                            passwordFocused = false
                            showingImporter = true
                        } label: {
                            Label(selectedFile == nil ? "Import .p12 / .pfx" : "Choose another file", systemImage: "folder.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        if let selectedFile {
                            Label(selectedFile.lastPathComponent, systemImage: "doc.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("No file selected")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))

                    if selectedFile != nil {
                        VStack(alignment: .leading, spacing: 14) {
                            stepLabel("02", "ENTER PASSWORD")
                            SecureField("P12 password", text: $password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($passwordFocused)
                                .onSubmit { verifyAndDismissKeyboard() }
                                .padding(15)
                                .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 13))

                            Button {
                                verifyAndDismissKeyboard()
                            } label: {
                                HStack {
                                    if isChecking { ProgressView().tint(.black) }
                                    Label(isChecking ? "Importing…" : "Import & verify identity", systemImage: "checkmark.shield.fill")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isChecking || password.isEmpty)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(isSuccess ? .green : .secondary)
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(isSuccess ? .green : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                    if hasStoredIdentity {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Signing identity saved", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("The PKCS#12 container and its password are stored as a single item in the device-only iOS Keychain.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                do {
                                    try URXCertificateVault.remove()
                                    hasStoredIdentity = false
                                    status = "Saved signing identity removed from the Keychain."
                                    isSuccess = false
                                } catch {
                                    status = "Could not remove saved identity: \(error.localizedDescription)"
                                    isSuccess = false
                                }
                            } label: {
                                Label("Remove saved identity", systemImage: "trash")
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy & security", systemImage: "lock.shield.fill")
                            .font(.headline)
                        Text("The file is processed locally. The PKCS#12 data and password are saved together in the device-only iOS Keychain. Nothing is uploaded.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Importing a signing identity does not grant jailbreak privileges or access outside the app sandbox.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Identity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { passwordFocused = false }
                        .tint(.green)
                }
            }
            .onAppear {
                hasStoredIdentity = URXCertificateVault.containsIdentity()
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data, UTType(filenameExtension: "pfx") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: handleFileSelection
            )
            .onTapGesture {
                passwordFocused = false
            }
        }
    }

    private func stepLabel(_ number: String, _ title: String) -> some View {
        HStack(spacing: 9) {
            Text(number)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.green)
                .padding(7)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
        }
    }

    private func verifyAndDismissKeyboard() {
        passwordFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            inspectIdentity()
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                status = "No file selected."
                isSuccess = false
                return
            }
            selectedFile = url
            password = ""
            status = "File selected. Enter its password to verify the identity."
            isSuccess = false
        case .failure(let error):
            status = "Could not select file: \(error.localizedDescription)"
            isSuccess = false
        }
    }

    private func inspectIdentity() {
        guard let url = selectedFile else { return }
        guard !password.isEmpty else {
            status = "Enter the password for this file."
            isSuccess = false
            return
        }

        isChecking = true
        defer { isChecking = false }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Coordinate access for files supplied by the Files app or cloud providers.
            var coordinationError: NSError?
            var readError: Error?
            var coordinatedData: Data?
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
                do {
                    coordinatedData = try Data(contentsOf: readableURL)
                } catch {
                    readError = error
                }
            }

            if let coordinationError { throw coordinationError }
            if let readError { throw readError }
            guard let data = coordinatedData, !data.isEmpty else {
                status = "The selected file is empty or could not be read."
                isSuccess = false
                return
            }

            var importedItems: CFArray?
            let options = [kSecImportExportPassphrase as String: password] as CFDictionary
            var identityData = data
            var importStatus = SecPKCS12Import(data as CFData, options, &importedItems)

            // SideStore may export PKCS#12 encryption profiles that Apple's
            // importer rejects. Normalize only after the native importer
            // specifically reports a decode error, then verify again with Apple.
            if importStatus == errSecDecode {
                var compatibilityError: NSError?
                if let normalized = URXNormalizePKCS12(data as NSData, password as NSString, &compatibilityError) {
                    var normalizedItems: CFArray?
                    let normalizedStatus = SecPKCS12Import(normalized as CFData, options, &normalizedItems)
                    if normalizedStatus == errSecSuccess {
                        importedItems = normalizedItems
                        identityData = normalized as Data
                        importStatus = errSecSuccess
                    } else {
                        importedItems = nil
                        status = "The compatibility parser read the identity, but Apple Security still rejected the normalized container (status: \\(normalizedStatus))."
                        isSuccess = false
                        return
                    }
                } else {
                    importedItems = nil
                    let detail = compatibilityError?.localizedDescription ?? "No parser details were returned."
                    status = "Apple Security could not decode this PKCS#12 file, and the compatibility parser could not normalize it: \\(detail)"
                    isSuccess = false
                    return
                }
            }

            guard importStatus == errSecSuccess,
                  let items = importedItems as? [[String: Any]],
                  !items.isEmpty else {
                status = securityErrorMessage(for: importStatus, byteCount: data.count, looksLikeASN1Sequence: data.first == 0x30)
                isSuccess = false
                importedItems = nil
                return
            }

            guard let identityItem = items.first(where: { $0[kSecImportItemIdentity as String] != nil }) else {
                importedItems = nil
                status = "The PKCS#12 file was read, but it did not contain a signing identity with a private key."
                isSuccess = false
                return
            }

            let identity = identityItem[kSecImportItemIdentity as String] as! SecIdentity
            var certificate: SecCertificate?
            let certificateStatus = SecIdentityCopyCertificate(identity, &certificate)
            let subject = certificateStatus == errSecSuccess
                ? certificate.flatMap { SecCertificateCopySubjectSummary($0) as String? }
                : nil
            importedItems = nil

            do {
                try URXCertificateVault.save(pkcs12Data: identityData, password: password, subject: subject)
                hasStoredIdentity = true
                password = ""
                status = "Signing identity imported and securely saved in the iOS Keychain."
                if let subject { status += " Certificate: \(subject)" }
                isSuccess = true
            } catch {
                status = "Identity is valid, but Keychain storage failed: \(error.localizedDescription)"
                isSuccess = false
            }
        } catch {
            status = "Could not read selected file: \(error.localizedDescription)"
            isSuccess = false
        }
    }

    private func securityErrorMessage(for status: OSStatus, byteCount: Int, looksLikeASN1Sequence: Bool) -> String {
        switch status {
        case errSecAuthFailed:
            return "The file was recognized, but its password was rejected or its contents are damaged (errSecAuthFailed). Recheck the password and the exported file."
        case errSecDecode:
            if !looksLikeASN1Sequence {
                return "This file does not look like a PKCS#12 data container. It is \(byteCount) bytes and does not begin with the expected ASN.1 sequence marker. Re-export the full P12 from SideStore and select that file."
            }
            return "The file begins like an ASN.1 container (\(byteCount) bytes), but Apple Security could not decode it as PKCS#12 (errSecDecode). The export may be malformed or use an unsupported encoding."
        case errSecParam:
            return "Security rejected the import parameters (errSecParam)."
        case errSecSuccess:
            return "The file was read, but no identity was returned."
        default:
            return "PKCS#12 verification failed. Security status: \(status)."
        }
    }
}


private enum URXCertificateVault {
    private static let service = "team.greenvn.urx.signing-identity"
    private static let account = "pkcs12-container"

    private struct StoredIdentity: Codable {
        let pkcs12Data: Data
        let password: String
        let subject: String?
        let importedAt: Date
    }

    static func save(pkcs12Data: Data, password: String, subject: String?) throws {
        let payload = StoredIdentity(pkcs12Data: pkcs12Data, password: password, subject: subject, importedAt: Date())
        let encoded = try JSONEncoder().encode(payload)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw VaultError.keychain(updateStatus) }

        var addQuery = query
        attributes.forEach { addQuery[$0.key] = $0.value }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw VaultError.keychain(addStatus) }
    }

    static func remove() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw VaultError.keychain(status) }
    }

    static func containsIdentity() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    enum VaultError: LocalizedError {
        case keychain(OSStatus)
        var errorDescription: String? {
            switch self {
            case .keychain(let status): return "iOS Keychain error (\\(status))."
            }
        }
    }
}
