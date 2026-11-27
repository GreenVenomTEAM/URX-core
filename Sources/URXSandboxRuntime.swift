import SwiftUI

struct URXSandboxAppRecord: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let version: String
    let developer: String
    let summary: String
    let iconSymbol: String
    let installedAt: Date

    var dataDirectoryName: String { id.replacingOccurrences(of: ".", with: "_") }
}

@MainActor
final class URXSandboxRuntime: ObservableObject {
    @Published private(set) var installedApps: [URXSandboxAppRecord] = []
    @Published private(set) var storageReady = false
    @Published private(set) var packageDatabaseReady = false
    @Published private(set) var installedPackageCount = 0
    @Published var statusMessage: String?

    private let fileManager = FileManager.default
    private var rootURL: URL?
    private var registryURL: URL?
    private var dpkgStatusURL: URL?

    init() {
        prepareStorage()
        loadRegistry()
        loadPackageDatabase()
    }

    var installedCount: Int { installedApps.count }

    func appDataDirectory(for app: URXSandboxAppRecord) throws -> URL {
        guard let rootURL else { throw SandboxError.storageUnavailable }
        let directory = rootURL
            .appendingPathComponent("AppData", isDirectory: true)
            .appendingPathComponent(app.dataDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func sharedDirectory() throws -> URL {
        guard let rootURL else { throw SandboxError.storageUnavailable }
        let directory = rootURL.appendingPathComponent("Shared", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func prepareStorage() {
        do {
            let support = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let root = support.appendingPathComponent("URXSandbox", isDirectory: true)
            let apps = root.appendingPathComponent("Apps", isDirectory: true)
            let data = root.appendingPathComponent("AppData", isDirectory: true)
            let shared = root.appendingPathComponent("Shared", isDirectory: true)
            try fileManager.createDirectory(at: apps, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: data, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: shared, withIntermediateDirectories: true)
            rootURL = root
            registryURL = root.appendingPathComponent("registry.json")
            let dpkgDirectory = root
                .appendingPathComponent("var", isDirectory: true)
                .appendingPathComponent("lib", isDirectory: true)
                .appendingPathComponent("dpkg", isDirectory: true)
            try fileManager.createDirectory(at: dpkgDirectory, withIntermediateDirectories: true)
            dpkgStatusURL = dpkgDirectory.appendingPathComponent("status")
            if let dpkgStatusURL, !fileManager.fileExists(atPath: dpkgStatusURL.path) {
                try Data().write(to: dpkgStatusURL, options: .atomic)
            }
            storageReady = true
        } catch {
            statusMessage = "Sandbox storage could not be prepared: \(error.localizedDescription)"
        }
    }

    /// Loads dpkg's data-only status database from URX's private container.
    /// This does not run dpkg, package scripts, or native package payloads.
    private func loadPackageDatabase() {
        guard let dpkgStatusURL else {
            packageDatabaseReady = false
            return
        }
        do {
            let records = try URXDPKGStatusStore.load(from: dpkgStatusURL)
            installedPackageCount = records.filter(\.isInstalled).count
            packageDatabaseReady = true
        } catch {
            packageDatabaseReady = false
            statusMessage = "The local package status database could not be read: \(error.localizedDescription)"
        }
    }

    /// Persists metadata-only installed-state records in the app container.
    func savePackageStatus(_ records: [URXDPKGStatusRecord]) throws {
        guard let dpkgStatusURL else { throw SandboxError.storageUnavailable }
        try URXDPKGStatusStore.save(records, to: dpkgStatusURL)
        installedPackageCount = records.filter(\.isInstalled).count
        packageDatabaseReady = true
    }

    private func loadRegistry() {
        guard let registryURL,
              let data = try? Data(contentsOf: registryURL),
              let records = try? JSONDecoder().decode([URXSandboxAppRecord].self, from: data) else {
            installedApps = []
            return
        }
        installedApps = records.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func saveRegistry() {
        guard let registryURL else { return }
        do {
            let data = try JSONEncoder().encode(installedApps)
            try data.write(to: registryURL, options: .atomic)
        } catch {
            statusMessage = "Could not save the app registry: \(error.localizedDescription)"
        }
    }

    enum SandboxError: LocalizedError {
        case storageUnavailable
        var errorDescription: String? {
            "The URX Sandbox storage is not available."
        }
    }
}

struct URXSandboxView: View {
    @StateObject private var runtime = URXSandboxRuntime()
    @State private var selectedApp: URXSandboxAppRecord?
    @State private var showingSileoInfo = false

    private let accent = Color(red: 0.35, green: 0.95, blue: 0.55)

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    HStack(spacing: 12) {
                        metric("APPS", value: "\(runtime.installedCount)", symbol: "square.stack.3d.up.fill")
                        metric("DPKG", value: runtime.packageDatabaseReady ? "\(runtime.installedPackageCount)" : "ERROR", symbol: "shippingbox.fill")
                        metric("STORAGE", value: runtime.storageReady ? "READY" : "ERROR", symbol: "externaldrive.fill")
                    }

                    sectionHeading("INSTALLED APPLICATIONS")
                    if runtime.installedApps.isEmpty {
                        emptyState
                    } else {
                        ForEach(runtime.installedApps) { app in
                            installedAppCard(app)
                        }
                    }

                    sectionHeading("FIRST INTEGRATION")
                    sileoCard

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Isolated app data", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundStyle(accent)
                        Text("Each URX app will receive its own data directory. The shared area is separate. The runtime will only open app modules explicitly supported by URX; it does not execute arbitrary IPA binaries or jailbreak package code.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 18))

                    if let status = runtime.statusMessage {
                        Label(status, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Sandbox")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSileoInfo) {
                sileoInfoSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.title2)
                    .foregroundStyle(accent)
                Spacer()
                Text("URX APP ENVIRONMENT")
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(accent)
            }
            Text("Your apps, inside URX.")
                .font(.title2.bold())
            Text("A dedicated space for app modules, their launch state and private data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.15), Color(uiColor: .secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(accent)
            Text(title).font(.caption2.bold()).tracking(0.8).foregroundStyle(.secondary)
            Text(value).font(.title3.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .tracking(1.2)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)
            Text("No apps installed yet")
                .font(.headline)
            Text("When an app module is integrated and installed into URX, it will appear here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
    }

    private func installedAppCard(_ app: URXSandboxAppRecord) -> some View {
        HStack(spacing: 13) {
            Image(systemName: app.iconSymbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 54, height: 54)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.headline)
                Text("v\(app.version) • \(app.developer)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(app.summary).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 17))
    }

    private var sileoCard: some View {
        Button {
            showingSileoInfo = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.22, green: 0.48, blue: 0.95).opacity(0.16))
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(Color(red: 0.42, green: 0.66, blue: 1))
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Sileo").font(.headline).foregroundStyle(.primary)
                    Text("Original package manager • first target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("INTEGRATION PLANNED")
                        .font(.caption2.bold())
                        .tracking(0.7)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var sileoInfoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Label("Sileo integration", systemImage: "shippingbox.fill")
                    .font(.title2.bold())
                Text("Sileo is the first application we are targeting for URX Sandbox. This entry is an integration target, not a fake or reimplemented Sileo screen.")
                    .font(.body)
                Text("Next: map Sileo's UI and backend dependencies, then identify which components can run in URX's contained environment and which require replacement by safe app-local services.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("No package scripts or native tweak code will be executed by this app-contained runtime.", systemImage: "lock.shield.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .navigationTitle("Sileo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showingSileoInfo = false }
                }
            }
        }
        .tint(accent)
    }
}
