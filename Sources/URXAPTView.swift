import SwiftUI
import UniformTypeIdentifiers

struct URXAPTView: View {
    @State private var packages: [URXPackageRecord] = []
    @State private var searchText = ""
    @State private var showingImporter = false
    @State private var sourceName: String?
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private let maximumIndexSize = 20 * 1024 * 1024

    private var filteredPackages: [URXPackageRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return packages.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
        }
        return packages.filter {
            $0.id.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query) ||
            $0.maintainer.localizedCaseInsensitiveContains(query)
        }.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if packages.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            HStack {
                                Label("\(packages.count) packages", systemImage: "shippingbox.fill")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("LOCAL INDEX")
                                    .font(.caption2.weight(.bold))
                                    .tracking(0.8)
                                    .foregroundStyle(.green)
                            }
                            if let sourceName {
                                Text(sourceName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Section("CATALOG") {
                            ForEach(filteredPackages) { package in
                                NavigationLink {
                                    URXAPTDetailsView(package: package)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(package.id)
                                                .font(.subheadline.weight(.semibold))
                                                .lineLimit(1)
                                            Spacer(minLength: 8)
                                            Text(package.version)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                        if !package.description.isEmpty {
                                            Text(package.description.components(separatedBy: "\n").first ?? package.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                        HStack(spacing: 8) {
                                            Text(package.architecture)
                                            if let size = package.size {
                                                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                            }
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                        if filteredPackages.isEmpty {
                            Text("No packages match this search.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Package name or description")
                }
            }
            .navigationTitle("APT")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import Packages index", systemImage: "square.and.arrow.down")
                        }
                        if !packages.isEmpty {
                            Button(role: .destructive, action: clearIndex) {
                                Label("Remove local index", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data, .plainText],
                allowsMultipleSelection: false,
                onCompletion: importIndex
            )
            .alert("APT index error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .safeAreaInset(edge: .bottom) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial)
                }
            }
            .onAppear(perform: loadSavedIndex)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.green)
            Text("APT package catalog")
                .font(.title2.bold())
            Text("Import a Debian Packages index to browse repository metadata locally. This first stage does not download or install packages.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Button {
                showingImporter = true
            } label: {
                Label("Import Packages index", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func indexURL() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("URXAPT", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Packages")
    }

    private func loadSavedIndex() {
        guard packages.isEmpty, let url = try? indexURL(),
              let data = try? Data(contentsOf: url),
              let source = String(data: data, encoding: .utf8) else { return }
        do {
            packages = try URXPackageIndexParser.parse(source)
            sourceName = "Saved local index"
            statusMessage = "Restored \(packages.count) package records"
        } catch {
            errorMessage = "The saved index could not be parsed: \(error.localizedDescription)"
        }
    }

    private func importIndex(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
            guard size > 0, size <= maximumIndexSize else {
                throw ImportError.invalidSize
            }
            let data = try Data(contentsOf: url)
            guard let source = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidEncoding
            }
            let parsed = try URXPackageIndexParser.parse(source)
            guard !parsed.isEmpty else { throw ImportError.emptyIndex }

            let destination = try indexURL()
            try data.write(to: destination, options: .atomic)
            packages = parsed
            sourceName = url.lastPathComponent
            searchText = ""
            statusMessage = "Imported \(parsed.count) package records"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearIndex() {
        do {
            let url = try indexURL()
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            packages = []
            sourceName = nil
            statusMessage = "Local package index removed"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum ImportError: LocalizedError {
        case invalidSize
        case invalidEncoding
        case emptyIndex

        var errorDescription: String? {
            switch self {
            case .invalidSize: return "The index is empty or larger than 20 MB."
            case .invalidEncoding: return "The index is not valid UTF-8 text."
            case .emptyIndex: return "No package records were found in this file."
            }
        }
    }
}

private struct URXAPTDetailsView: View {
    let package: URXPackageRecord

    var body: some View {
        List {
            Section("PACKAGE") {
                detailRow("Identifier", package.id)
                detailRow("Version", package.version)
                detailRow("Architecture", package.architecture)
                if !package.maintainer.isEmpty { detailRow("Maintainer", package.maintainer) }
                if let size = package.size {
                    detailRow("Download size", ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                }
                if !package.filename.isEmpty { detailRow("Filename", package.filename) }
                if let sha256 = package.sha256 { detailRow("SHA-256", sha256) }
            }
            if !package.description.isEmpty {
                Section("DESCRIPTION") {
                    Text(package.description)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            if !package.dependencies.isEmpty {
                Section("DEPENDENCIES") {
                    ForEach(Array(package.dependencies.enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Group \(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(group.map(\.display).joined(separator: "  OR  "))
                                .font(.footnote.monospaced())
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            Section {
                Label("Metadata only. No package files are downloaded, extracted, or installed.", systemImage: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(package.id)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.footnote.monospaced()).textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}
