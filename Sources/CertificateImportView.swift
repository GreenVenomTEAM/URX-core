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
                        Text("Select your PKCS#12 file first. Then enter its password to check that the identity can be read.")
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
                                    Label(isChecking ? "Checking…" : "Verify identity", systemImage: "checkmark.shield.fill")
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

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy & security", systemImage: "lock.shield.fill")
                            .font(.headline)
                        Text("The file is inspected locally. URX Core does not upload or save the certificate, private key, or password. The password is cleared only after a successful check.")
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

            let looksLikeASN1Sequence = data.first == 0x30
            var importedItems: CFArray?
            let options = [kSecImportExportPassphrase as String: password] as CFDictionary
            let code = SecPKCS12Import(data as CFData, options, &importedItems)

            guard code == errSecSuccess,
                  let items = importedItems as? [[String: Any]],
                  !items.isEmpty else {
                status = securityErrorMessage(for: code, byteCount: data.count, looksLikeASN1Sequence: looksLikeASN1Sequence)
                isSuccess = false
                importedItems = nil
                return
            }

            let containsIdentity = items.contains { $0[kSecImportItemIdentity as String] != nil }
            importedItems = nil
            guard containsIdentity else {
                status = "The PKCS#12 file was read, but it did not contain a signing identity with a private key."
                isSuccess = false
                return
            }

            password = ""
            status = "Valid PKCS#12 signing identity found. Nothing was installed or saved."
            isSuccess = true
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
    }}
}
