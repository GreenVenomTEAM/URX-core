import SwiftUI
import Security

struct CertificateImportView: View {
    @State private var showingImporter = false
    @State private var selectedFile: URL?
    @State private var password = ""
    @State private var status = "Choose a .p12 or .pfx file to begin."
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 34))
                            .foregroundStyle(.green)
                        Text("Signing identity")
                            .font(.title2.bold())
                        Text("Select a PKCS#12 file, then enter its password in the next step.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("STEP 1")
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(.secondary)

                        Button {
                            showingImporter = true
                        } label: {
                            Label(selectedFile == nil ? "Import .p12 / .pfx" : "Choose another file",
                                  systemImage: "folder")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        if let selectedFile {
                            Label(selectedFile.lastPathComponent, systemImage: "doc")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("No file selected")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

                    if selectedFile != nil {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("STEP 2")
                                .font(.caption.weight(.semibold))
                                .tracking(1)
                                .foregroundStyle(.secondary)

                            SecureField("Certificate password", text: $password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))

                            Button(action: inspectIdentity) {
                                Label("Verify identity", systemImage: "checkmark.shield")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "info.circle")
                            .foregroundStyle(isSuccess ? .green : .secondary)
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(isSuccess ? .green : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy", systemImage: "lock.shield")
                            .font(.headline)
                        Text("The file is inspected locally. URX Core does not upload or save the certificate, private key, or password. The password is cleared after verification.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Importing a signing identity does not grant jailbreak privileges or access outside the app sandbox.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Identity")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false,
                onCompletion: handleFileSelection
            )
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
        defer { password = "" }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            var importedItems: CFArray?
            let options = [kSecImportExportPassphrase as String: password] as CFDictionary
            let code = SecPKCS12Import(data as CFData, options, &importedItems)

            guard code == errSecSuccess,
                  let items = importedItems as? [[String: Any]],
                  !items.isEmpty else {
                status = "Verification failed (Security status: \(code)). Check the file and password, then try again."
                isSuccess = false
                importedItems = nil
                return
            }

            status = "Valid PKCS#12 identity found. Nothing was installed or saved."
            isSuccess = true
            importedItems = nil
        } catch {
            status = "Could not read selected file: \(error.localizedDescription)"
            isSuccess = false
        }
    }
}
