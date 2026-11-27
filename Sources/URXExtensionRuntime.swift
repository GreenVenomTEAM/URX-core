import SwiftUI
import UniformTypeIdentifiers

struct URXExtensionManifest: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
    let author: String
    let description: String
    let accentHex: String?
    let homeLabel: String?

    func validate() throws {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-_")
        guard !id.isEmpty, id.count <= 80, id.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw URXExtensionError.invalidIdentifier
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw URXExtensionError.missingRequiredField
        }
        if let accentHex, !URXExtensionRuntime.isValidHexColor(accentHex) {
            throw URXExtensionError.invalidAccent
        }
        if let homeLabel, homeLabel.count > 48 {
            throw URXExtensionError.invalidHomeLabel
        }
    }
}

enum URXExtensionError: LocalizedError {
    case invalidIdentifier
    case missingRequiredField
    case invalidAccent
    case invalidHomeLabel
    case duplicateExtension

    var errorDescription: String? {
        switch self {
        case .invalidIdentifier: return "The extension ID may contain only lowercase letters, numbers, dots, hyphens and underscores."
        case .missingRequiredField: return "The extension must include a name and version."
        case .invalidAccent: return "The accent color must be a six-digit hexadecimal RGB value."
        case .invalidHomeLabel: return "The home-screen label is too long."
        case .duplicateExtension: return "An extension with this ID is already installed."
        }
    }
}

@MainActor
final class URXExtensionRuntime: ObservableObject {
    @Published private(set) var extensions: [URXExtensionManifest] = []
    @Published private(set) var enabledIDs: Set<String> = []
    @Published private(set) var shellGeneration = 0
    @Published var statusMessage: String?

    private let fileManager = FileManager.default
    private let enabledKey = "URXExtensionRuntime.enabledIDs"

    init() {
        loadExtensions()
    }

    var activeAccent: Color {
        guard let manifest = extensions.first(where: { enabledIDs.contains($0.id) }),
              let hex = manifest.accentHex else {
            return Color(red: 0.35, green: 0.95, blue: 0.55)
        }
        return Self.color(from: hex)
    }

    var activeHomeLabel: String? {
        extensions.first(where: { enabledIDs.contains($0.id) })?.homeLabel
    }

    func isEnabled(_ manifest: URXExtensionManifest) -> Bool {
        enabledIDs.contains(manifest.id)
    }

    func setEnabled(_ enabled: Bool, for manifest: URXExtensionManifest) {
        if enabled {
            enabledIDs.insert(manifest.id)
        } else {
            enabledIDs.remove(manifest.id)
        }
        persistEnabledIDs()
        statusMessage = enabled ? "\(manifest.name) enabled for the URX shell." : "\(manifest.name) disabled."
    }

    func respring() {
        shellGeneration += 1
        statusMessage = "URX shell restarted. Host iOS was not affected."
    }

    func importExtension(from url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard size > 0, size <= 256 * 1024 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Extension manifest must be under 256 KB."))
        }

        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(URXExtensionManifest.self, from: data)
        try manifest.validate()
        guard !extensions.contains(where: { $0.id == manifest.id }) else {
            throw URXExtensionError.duplicateExtension
        }

        let directory = try extensionsDirectory()
        let destination = directory.appendingPathComponent(manifest.id + ".urxext")
        try data.write(to: destination, options: .atomic)
        extensions.append(manifest)
        extensions.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        statusMessage = "Imported \(manifest.name). Review it and enable it when ready."
    }

    private func extensionsDirectory() throws -> URL {
        let base = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = base.appendingPathComponent("URXExtensions", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func loadExtensions() {
        var loaded: [URXExtensionManifest] = [
            URXExtensionManifest(
                id: "team.greenvn.neon-accent",
                name: "Neon Accent",
                version: "1.0.0",
                author: "GreenVenom Team",
                description: "A sample declarative extension that changes the URX shell accent color.",
                accentHex: "59F28C",
                homeLabel: "URX Enhanced"
            )
        ]

        if let directory = try? extensionsDirectory(),
           let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for url in urls where url.pathExtension == "urxext" {
                guard let data = try? Data(contentsOf: url),
                      let manifest = try? JSONDecoder().decode(URXExtensionManifest.self, from: data),
                      (try? manifest.validate()) != nil,
                      !loaded.contains(where: { $0.id == manifest.id }) else { continue }
                loaded.append(manifest)
            }
        }

        extensions = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        enabledIDs = Set(UserDefaults.standard.stringArray(forKey: enabledKey) ?? [])
            .intersection(Set(extensions.map(\.id)))
    }

    private func persistEnabledIDs() {
        UserDefaults.standard.set(Array(enabledIDs), forKey: enabledKey)
    }

    nonisolated static func isValidHexColor(_ value: String) -> Bool {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        return hex.count == 6 && hex.allSatisfy { $0.isHexDigit }
    }

    private static func color(from value: String) -> Color {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        let number = UInt64(hex, radix: 16) ?? 0x59F28C
        return Color(
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255
        )
    }
}

struct ExtensionsView: View {
    @ObservedObject var runtime: URXExtensionRuntime
    @State private var showingImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "puzzlepiece.extension.fill")
                                .font(.title2)
                                .foregroundStyle(runtime.activeAccent)
                            Spacer()
                            Text("RUNTIME V1")
                                .font(.caption2.bold())
                                .tracking(1)
                                .foregroundStyle(runtime.activeAccent)
                        }
                        Text("URX Extensions")
                            .font(.title2.bold())
                        Text("A contained, declarative extension system. Imported manifests can change supported URX shell settings only; they cannot execute native code or modify host iOS.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

                    HStack(spacing: 10) {
                        Label("\(runtime.enabledIDs.count) enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(runtime.activeAccent)
                        Spacer()
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(runtime.activeAccent)
                    }

                    ForEach(runtime.extensions) { manifest in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(manifest.name).font(.headline)
                                    Text("\(manifest.id) • v\(manifest.version)")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle("Enabled", isOn: Binding(
                                    get: { runtime.isEnabled(manifest) },
                                    set: { runtime.setEnabled($0, for: manifest) }
                                ))
                                .labelsHidden()
                                .tint(runtime.activeAccent)
                            }
                            Text(manifest.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("by \(manifest.author)")
                                Spacer()
                                Text(runtime.isEnabled(manifest) ? "ACTIVE" : "DISABLED")
                                    .font(.caption2.bold())
                                    .tracking(0.8)
                                    .foregroundStyle(runtime.isEnabled(manifest) ? runtime.activeAccent : .secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 18))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Shell preview", systemImage: "iphone")
                            .font(.headline)
                        HStack {
                            Image(systemName: "circle.hexagongrid.fill")
                                .foregroundStyle(runtime.activeAccent)
                            Text(runtime.activeHomeLabel ?? "URX Core")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("GEN \(runtime.shellGeneration)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            runtime.respring()
                        } label: {
                            Label("Respring URX shell", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(runtime.activeAccent)
                        Text("This restarts the extension presentation state inside this screen. It does not restart SpringBoard or any iOS service.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 18))

                    if let status = runtime.statusMessage {
                        Label(status, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(runtime.activeAccent)
                    }
                    if let importError {
                        Label(importError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    Text("URXEXT is a JSON manifest format in v1. It is not a Debian package and does not load .dylib files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Extensions")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json, .data], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    try runtime.importExtension(from: url)
                    importError = nil
                } catch {
                    importError = error.localizedDescription
                }
            }
        }
        .tint(runtime.activeAccent)
    }
}
