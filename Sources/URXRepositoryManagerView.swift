import SwiftUI
import Foundation
import CryptoKit

private struct URXRepository: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    // Kept as indexURL for backward-compatible decoding of sources added by the first prototype.
    var indexURL: String
    var lastUpdated: String?

    init(name: String, indexURL: String) {
        self.id = UUID()
        self.name = name
        self.indexURL = indexURL
        self.lastUpdated = nil
    }
}

struct URXRepositoryManagerView: View {
    let onPackagesLoaded: ([URXPackageRecord]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var repositories: [URXRepository] = []
    @State private var repositoryName = ""
    @State private var repositoryURL = ""
    @State private var isLoading = false
    @State private var loadingID: UUID?
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private let maximumIndexSize = 20 * 1024 * 1024
    private let maximumExpandedSize = 32 * 1024 * 1024

    var body: some View {
        NavigationStack {
            List {
                Section("ADD APT SOURCE") {
                    TextField("Repository name", text: $repositoryName)
                        .textInputAutocapitalization(.words)
                    TextField("Repository URL (e.g. https://repo.example/)", text: $repositoryURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Enter the repository's root address, as you would in Sileo. URX Core will look for its package indexes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: addRepository) {
                        Label("Add source", systemImage: "plus.circle.fill")
                    }
                    .disabled(repositoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("SOURCES") {
                    if repositories.isEmpty {
                        Text("No repositories added yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(repositories) { repository in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(repository.name).font(.headline)
                                    Text(repository.indexURL)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Button {
                                    Task { await refresh(repository) }
                                } label: {
                                    if loadingID == repository.id {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                }
                                .disabled(isLoading)
                                .accessibilityLabel("Refresh \(repository.name)")
                            }
                            if let updated = repository.lastUpdated {
                                Text("Last refreshed: \(updated)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .onDelete(perform: removeRepositories)
                }

                if let statusMessage {
                    Section("STATUS") {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Label("URX Core fetches repository metadata only. It does not download package archives or execute package scripts.", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("APT Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Repository error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear(perform: restore)
        }
    }

    private func directoryURL() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("URXAPT", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func repositoryListURL() throws -> URL {
        try directoryURL().appendingPathComponent("repositories.json")
    }

    private func cacheURL(for repository: URXRepository) throws -> URL {
        try directoryURL().appendingPathComponent("repo-\(repository.id.uuidString).Packages")
    }

    private func restore() {
        do {
            let listURL = try repositoryListURL()
            if FileManager.default.fileExists(atPath: listURL.path) {
                repositories = try JSONDecoder().decode([URXRepository].self, from: Data(contentsOf: listURL))
            }
            var allPackages: [URXPackageRecord] = []
            for repository in repositories {
                let url = try cacheURL(for: repository)
                guard let data = try? Data(contentsOf: url),
                      let source = String(data: data, encoding: .utf8) else { continue }
                allPackages.append(contentsOf: try URXPackageIndexParser.parse(source))
            }
            onPackagesLoaded(uniquePackages(allPackages))
        } catch {
            errorMessage = "Could not restore repository data: \(error.localizedDescription)"
        }
    }

    private func addRepository() {
        let name = repositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = repositoryURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: address),
              let scheme = components.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            errorMessage = "Enter a valid HTTP or HTTPS repository URL without credentials, query parameters, or fragments."
            return
        }
        if !components.path.hasSuffix("/") { components.path += "/" }
        guard let url = components.url else {
            errorMessage = "The repository URL is invalid."
            return
        }
        guard !repositories.contains(where: { $0.indexURL == url.absoluteString }) else {
            errorMessage = "This repository is already added."
            return
        }
        repositories.append(URXRepository(name: name, indexURL: url.absoluteString))
        repositoryName = ""
        repositoryURL = ""
        saveRepositories()
        statusMessage = "Repository added. Tap refresh to discover its package index."
    }

    @MainActor
    private func refresh(_ repository: URXRepository) async {
        guard let baseURL = URL(string: repository.indexURL),
              ["https", "http"].contains(baseURL.scheme?.lowercased() ?? "") else {
            errorMessage = "This repository URL is invalid."
            return
        }
        isLoading = true
        loadingID = repository.id
        defer {
            isLoading = false
            loadingID = nil
        }

        do {
            let discovered = try await discoverPackages(baseURL: baseURL)
            try discovered.data.write(to: cacheURL(for: repository), options: .atomic)
            if let position = repositories.firstIndex(where: { $0.id == repository.id }) {
                repositories[position].lastUpdated = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
            }
            try persistRepositories()

            var allPackages: [URXPackageRecord] = []
            for item in repositories {
                let cachedURL = try cacheURL(for: item)
                guard let cachedData = try? Data(contentsOf: cachedURL),
                      let cachedSource = String(data: cachedData, encoding: .utf8) else { continue }
                allPackages.append(contentsOf: try URXPackageIndexParser.parse(cachedSource))
            }
            onPackagesLoaded(uniquePackages(allPackages))
            statusMessage = "Found \(discovered.count) packages at \(discovered.location)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func discoverPackages(baseURL: URL) async throws -> (data: Data, count: Int, location: String, sourceSHA256: String) {
        // Flat APT repositories (suite "./") publish Release and Packages at the root.
        // Validate the compressed/plain bytes against Release before accepting the index.
        let flatReleaseURL = baseURL.appendingPathComponent("Release")
        if let releaseData = try? await fetchSmallText(flatReleaseURL),
           let releaseText = String(data: releaseData, encoding: .utf8) {
            let checksums = parseReleaseSHA256(releaseText)
            for name in ["Packages.gz", "Packages"] {
                guard let expected = checksums[name] else { continue }
                let candidate = baseURL.appendingPathComponent(name)
                guard let result = try? await fetchIndex(candidate),
                      result.sourceSHA256 == expected.lowercased() else { continue }
                return result
            }
        }

        // Legacy flat repositories without Release metadata (metadata-only compatibility).
        let flatNames = ["Packages.gz", "Packages"]
        for name in flatNames {
            let candidate = baseURL.appendingPathComponent(name)
            if let result = try? await fetchIndex(candidate) {
                return result
            }
        }

        // Also accept a URL that already points directly to a Packages index (legacy prototype).
        if baseURL.lastPathComponent.lowercased().hasPrefix("packages") {
            if let result = try? await fetchIndex(baseURL) { return result }
        }

        // Conventional APT distributions: inspect Release metadata, then locate the
        // architecture-specific component indexes it advertises.
        let suites = ["stable", "ios", "unstable"]
        var attempted = [String]()
        for suite in suites {
            let releaseURL = baseURL.appendingPathComponent("dists").appendingPathComponent(suite).appendingPathComponent("Release")
            guard let releaseData = try? await fetchSmallText(releaseURL),
                  let releaseText = String(data: releaseData, encoding: .utf8) else { continue }
            let fields = parseReleaseFields(releaseText)
            let components = (fields["components"] ?? "main").split(whereSeparator: { $0.isWhitespace }).map(String.init)
            let advertised = (fields["architectures"] ?? "").split(whereSeparator: { $0.isWhitespace }).map(String.init)
            let architectures = uniqueStrings(advertised + ["iphoneos-arm64", "iphoneos-arm64e", "all"])
            for component in components {
                for architecture in architectures {
                    for filename in ["Packages.gz", "Packages"] {
                        let candidate = baseURL
                            .appendingPathComponent("dists")
                            .appendingPathComponent(suite)
                            .appendingPathComponent(component)
                            .appendingPathComponent("binary-\(architecture)")
                            .appendingPathComponent(filename)
                        attempted.append(candidate.path)
                        if let result = try? await fetchIndex(candidate) { return result }
                    }
                }
            }
        }
        throw RepositoryError.indexNotFound(attempted.count)
    }

    private func fetchSmallText(_ url: URL) async throws -> Data {
        let (data, response) = try await performRequest(url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RepositoryError.notFound
        }
        guard !data.isEmpty, data.count <= 1024 * 1024 else { throw RepositoryError.invalidSize }
        return data
    }

    private func fetchIndex(_ url: URL) async throws -> (data: Data, count: Int, location: String, sourceSHA256: String) {
        let (downloaded, response) = try await performRequest(url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RepositoryError.notFound
        }
        guard !downloaded.isEmpty, downloaded.count <= maximumIndexSize else {
            throw RepositoryError.invalidSize
        }
        let sourceSHA256 = SHA256.hash(data: downloaded).map { String(format: "%02x", $0) }.joined()
        let data: Data
        if url.pathExtension.lowercased() == "gz" {
            data = try decompressGzip(downloaded)
        } else {
            data = downloaded
        }
        guard data.count <= maximumExpandedSize,
              let source = String(data: data, encoding: .utf8) else {
            throw RepositoryError.invalidEncoding
        }
        let records = try URXPackageIndexParser.parse(source)
        guard !records.isEmpty else { throw RepositoryError.emptyIndex }
        return (data, records.count, url.path, sourceSHA256)
    }

    private func performRequest(_ url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("URX-Core-APT/0.2", forHTTPHeaderField: "User-Agent")
        return try await URLSession.shared.data(for: request)
    }

    private func decompressGzip(_ data: Data) throws -> Data {
        var output: UnsafeMutablePointer<UInt8>?
        var outputLength = 0
        let result = data.withUnsafeBytes { bytes -> Int32 in
            guard let base = bytes.bindMemory(to: UInt8.self).baseAddress else { return -2 }
            return urx_gzip_decompress(base, data.count, &output, &outputLength)
        }
        guard result == 0, let output else { throw RepositoryError.decompressionFailed }
        defer { free(output) }
        return Data(bytes: output, count: outputLength)
    }

    private func parseReleaseFields(_ text: String) -> [String: String] {
        var fields: [String: String] = [:]
        var currentKey: String?
        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix(" "), let key = currentKey {
                fields[key, default: ""] += " " + line.trimmingCharacters(in: .whitespaces)
            } else if let colon = line.firstIndex(of: ":") {
                let key = line[..<colon].lowercased()
                fields[key] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                currentKey = key
            }
        }
        return fields
    }

    /// Reads SHA256 entries from a Release file. Each entry is: hash size relative-path.
    private func parseReleaseSHA256(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        var insideSHA256 = false
        for line in text.components(separatedBy: .newlines) {
            if line == "SHA256:" {
                insideSHA256 = true
                continue
            }
            if !line.hasPrefix(" ") && line.contains(":") {
                insideSHA256 = false
            }
            guard insideSHA256 else { continue }
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            guard parts.count == 3,
                  parts[0].count == 64,
                  parts[0].allSatisfy({ $0.isHexDigit }),
                  let size = Int(parts[1]), size >= 0 else { continue }
            let path = String(parts[2])
            guard !path.hasPrefix("/"),
                  !path.split(separator: "/").contains("..") else { continue }
            result[path] = String(parts[0]).lowercased()
        }
        return result
    }

    private func uniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func uniquePackages(_ input: [URXPackageRecord]) -> [URXPackageRecord] {
        var seen = Set<String>()
        return input.filter { seen.insert("\($0.id)|\($0.version)|\($0.architecture)").inserted }
    }

    private func removeRepositories(at offsets: IndexSet) {
        let removed = offsets.map { repositories[$0] }
        for repository in removed {
            if let url = try? cacheURL(for: repository) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        repositories.remove(atOffsets: offsets)
        saveRepositories()
        statusMessage = "Selected source(s) removed."
        Task {
            var allPackages: [URXPackageRecord] = []
            for item in repositories {
                guard let url = try? cacheURL(for: item),
                      let data = try? Data(contentsOf: url),
                      let source = String(data: data, encoding: .utf8),
                      let parsed = try? URXPackageIndexParser.parse(source) else { continue }
                allPackages.append(contentsOf: parsed)
            }
            onPackagesLoaded(uniquePackages(allPackages))
        }
    }

    private func saveRepositories() {
        do {
            try persistRepositories()
        } catch {
            errorMessage = "Could not save sources: \(error.localizedDescription)"
        }
    }

    private func persistRepositories() throws {
        let data = try JSONEncoder().encode(repositories)
        try data.write(to: repositoryListURL(), options: .atomic)
    }

    private enum RepositoryError: LocalizedError {
        case notFound
        case invalidSize
        case invalidEncoding
        case emptyIndex
        case decompressionFailed
        case indexNotFound(Int)

        var errorDescription: String? {
            switch self {
            case .notFound: return "This index path does not exist."
            case .invalidSize: return "A repository metadata file is empty or exceeds its size limit."
            case .invalidEncoding: return "The downloaded Packages index is not valid UTF-8 or exceeds the expanded size limit."
            case .emptyIndex: return "The discovered file contains no package records."
            case .decompressionFailed: return "The repository's gzip Packages index could not be decompressed."
            case .indexNotFound(let count): return "No supported Packages index was found. Checked flat repository indexes and \(count) standard APT index paths. This repository may use a different suite, component, architecture, or compression format."
            }
        }
    }
}
