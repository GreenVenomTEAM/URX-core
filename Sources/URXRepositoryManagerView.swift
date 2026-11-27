import SwiftUI
import Foundation

private struct URXRepository: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
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
    @State private var indexURL = ""
    @State private var isLoading = false
    @State private var loadingID: UUID?
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private let maximumIndexSize = 20 * 1024 * 1024

    var body: some View {
        NavigationStack {
            List {
                Section("ADD APT SOURCE") {
                    TextField("Repository name", text: $repositoryName)
                        .textInputAutocapitalization(.words)
                    TextField("HTTPS URL to Packages index", text: $indexURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("For this stage, enter the direct URL of a Debian Packages index file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: addRepository) {
                        Label("Add source", systemImage: "plus.circle.fill")
                    }
                    .disabled(repositoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || indexURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                    Label("Only the Packages index is downloaded and parsed. Package archives, maintainer scripts, and executable code are not downloaded or run.", systemImage: "lock.shield.fill")
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
        let address = indexURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: address),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              let url = components.url else {
            errorMessage = "Enter a valid HTTPS URL without embedded credentials."
            return
        }
        guard !repositories.contains(where: { $0.indexURL == url.absoluteString }) else {
            errorMessage = "This Packages index URL is already added."
            return
        }
        repositories.append(URXRepository(name: name, indexURL: url.absoluteString))
        repositoryName = ""
        indexURL = ""
        saveRepositories()
        statusMessage = "Source added. Tap the refresh icon to load its index."
    }

    @MainActor
    private func refresh(_ repository: URXRepository) async {
        guard let url = URL(string: repository.indexURL),
              url.scheme?.lowercased() == "https" else {
            errorMessage = "This source does not contain a valid HTTPS URL."
            return
        }
        isLoading = true
        loadingID = repository.id
        defer {
            isLoading = false
            loadingID = nil
        }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue("URX-Core-APT/0.1", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw RepositoryError.httpStatus(code)
            }
            guard !data.isEmpty, data.count <= maximumIndexSize else {
                throw RepositoryError.invalidSize
            }
            guard let source = String(data: data, encoding: .utf8) else {
                throw RepositoryError.invalidEncoding
            }
            let parsed = try URXPackageIndexParser.parse(source)
            guard !parsed.isEmpty else { throw RepositoryError.emptyIndex }

            try data.write(to: cacheURL(for: repository), options: .atomic)
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
            statusMessage = "Loaded \(parsed.count) packages from \(repository.name)."
        } catch {
            errorMessage = error.localizedDescription
        }
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
        case httpStatus(Int)
        case invalidSize
        case invalidEncoding
        case emptyIndex

        var errorDescription: String? {
            switch self {
            case .httpStatus(let code): return "The server returned HTTP status \(code)."
            case .invalidSize: return "The Packages index is empty or exceeds 20 MB."
            case .invalidEncoding: return "The Packages index is not valid UTF-8 text."
            case .emptyIndex: return "The downloaded file contains no package records."
            }
        }
    }
}
