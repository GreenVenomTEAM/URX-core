import SwiftUI
import Security

struct CertificateImportView: View {
    @State private var showingImporter = false
    @State private var password = ""
    @State private var status = "No identity inspected."
    @State private var isSuccess = false
    var body: some View {
        NavigationStack {
            Form {
                Section("PKCS#12 identity") {
                    SecureField("Certificate password", text: $password)
                    Button { showingImporter = true } label: { Label("Inspect .p12 / .pfx file", systemImage: "doc.badge.gearshape") }
                    Text(status).font(.footnote).foregroundStyle(isSuccess ? .green : .secondary)
                }
                Section("Privacy") {
                    Text("The selected file is inspected locally in memory. URX Core does not upload or save the certificate or private key. The password is cleared after each inspection.").font(.footnote)
                    Text("A signing identity does not grant jailbreak privileges or access outside the app sandbox.").font(.footnote)
                }
            }.navigationTitle("Identity")
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.data], allowsMultipleSelection: false, onCompletion: handleImport)
        }
    }
    private func handleImport(_ result: Result<[URL], Error>) {
        defer { password = "" }
        do {
            guard let url = try result.get().first else { status = "No file selected."; isSuccess = false; return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            var importedItems: CFArray?
            let options = [kSecImportExportPassphrase as String: password] as CFDictionary
            let code = SecPKCS12Import(data as CFData, options, &importedItems)
            guard code == errSecSuccess, let items = importedItems as? [[String: Any]], !items.isEmpty else {
                status = "Could not inspect identity (Security status: \(code)). Check file and password."
                isSuccess = false
                return
            }
            status = "Valid PKCS#12 identity found. It was not saved or installed."
            isSuccess = true
            importedItems = nil
        } catch { status = "Import failed: \(error.localizedDescription)"; isSuccess = false }
    }
}
