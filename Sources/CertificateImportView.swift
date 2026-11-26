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
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            var importedItems: CFArray?
            let options = [kSecImportExportPassphrase as String: password] as CFDictionary
            let code = SecPKCS12Import(data as CFData, options, &importedItems)

            guard code == errSecSuccess,
                  let items = importedItems as? [[String: Any]],
                  !items.isEmpty else {
                status = securityErrorMessage(for: code)
                isSuccess = false
                importedItems = nil
                return
            }

            importedItems = nil
            password = ""
            status = "Valid PKCS#12 identity found. Nothing was installed or saved."
            isSuccess = true
        } catch {
            status = "Could not read selected file: \(error.localizedDescription)"
            isSuccess = false
        }
    }

    private func securityErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecAuthFailed:
            return "The PKCS#12 file rejected this password (errSecAuthFailed). Check the password, keyboard layout, and whether the file is the expected .p12/.pfx."
        case errSecDecode:
            return "Security could not decode this file (errSecDecode). It may not be a valid PKCS#12 file or may use an unsupported encoding."
        case errSecParam:
            return "Security rejected the import parameters (errSecParam)."
        case errSecSuccess:
            return "The file was read, but no identity was returned."
        default:
            return "PKCS#12 verification failed. Security status: \(status)."
        }
    }
}
