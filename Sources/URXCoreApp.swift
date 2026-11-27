import SwiftUI
import UniformTypeIdentifiers

@main
struct URXCoreApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @StateObject private var extensionRuntime = URXExtensionRuntime()

    var body: some View {
        GeometryReader { geometry in
            TabView {
                DashboardView(accent: extensionRuntime.activeAccent)
                    .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
                URXSandboxView()
                    .tabItem { Label("Sandbox", systemImage: "square.stack.3d.up.fill") }
                GuestWorkspaceView()
                    .tabItem { Label("Guest", systemImage: "externaldrive.fill") }
                PackageView()
                    .tabItem { Label("Packages", systemImage: "shippingbox.fill") }
                URXAPTView()
                    .tabItem { Label("APT", systemImage: "shippingbox") }
                ExtensionsView(runtime: extensionRuntime)
                    .tabItem { Label("Extensions", systemImage: "puzzlepiece.extension.fill") }
                CertificateImportView()
                    .tabItem { Label("Identity", systemImage: "checkmark.seal.fill") }
                URXSettingsView(runtime: extensionRuntime)
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(extensionRuntime.activeAccent)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.ignoresSafeArea())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

struct DashboardView: View {
    let accent: Color

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    HStack(spacing: 12) {
                        metricCard("GUEST", value: "LOCAL", detail: "App container", icon: "externaldrive.fill")
                        metricCard("IDENTITY", value: "OPTIONAL", detail: "P12 inspection", icon: "checkmark.seal")
                    }
                    sectionTitle("CORE COMPONENTS")
                    VStack(spacing: 0) {
                        componentRow("Guest workspace", subtitle: "Private storage inside URX Core", symbol: "externaldrive.fill", state: "READY", stateColor: accent)
                        Divider().overlay(.white.opacity(0.08)).padding(.leading, 58)
                        componentRow("Package manager", subtitle: "Metadata support is planned", symbol: "shippingbox.fill", state: "PLANNED", stateColor: .orange)
                        Divider().overlay(.white.opacity(0.08)).padding(.leading, 58)
                        componentRow("Tweak runtime", subtitle: "Not available in this prototype", symbol: "puzzlepiece.extension", state: "NOT BUILT", stateColor: .secondary)
                    }
                    .background(Color(uiColor: .secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
                    sectionTitle("PROJECT NOTES")
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Host iOS stays untouched", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundStyle(accent)
                        Text("URX Core is an app-contained research environment. It is not a jailbreak or a virtualized copy of iOS, and it cannot run arbitrary system tweaks.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
                    HStack {
                        Text("GREENVENOM TEAM")
                        Spacer()
                        Text("URX CORE • EXPERIMENTAL")
                    }
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("URX Core")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundStyle(accent)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(accent)
                Spacer()
                Text("CORE ONLINE")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(accent.opacity(0.12), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("Unc0veR")
                Text("rEb0rnEd X")
                    .foregroundStyle(accent)
                Text("CORE")
            }
            .font(.system(size: 38, weight: .black, design: .rounded))
            .lineSpacing(-4)
            Text("A contained iOS environment research project.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 8) {
                Label("GreenVenom Team", systemImage: "terminal")
                Spacer()
                Text("BUILD 0.1")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.55))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26).fill(
                    LinearGradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.12), Color(red: 0.04, green: 0.07, blue: 0.06), Color(uiColor: .secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 190, height: 190)
                    .blur(radius: 4)
                    .offset(x: 65, y: -75)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(accent.opacity(0.18), lineWidth: 1))
    }

    private func metricCard(_ title: String, value: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(accent)
            Text(title).font(.caption2.weight(.bold)).tracking(1).foregroundStyle(.secondary)
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
            Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(15)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1.4)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    private func componentRow(_ title: String, subtitle: String, symbol: String, state: String, stateColor: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(state)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(stateColor)
                .lineLimit(1)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GuestWorkspaceView: View {
    @State private var workspaceURL: URL?
    @State private var setupError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let workspaceURL {
                    GuestDirectoryView(directoryURL: workspaceURL)
                } else if let setupError {
                    VStack(spacing: 14) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("Workspace unavailable").font(.headline)
                        Text(setupError)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try again", action: loadWorkspace)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                    .padding()
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(.green)
                        Text("Your private guest space")
                            .font(.title2.bold())
                        Text("Create a workspace to manage folders and files stored locally in the URX Core app folder.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Button(action: createWorkspace) {
                            Label("Create sandbox", systemImage: "plus.square.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Guest")
            .onAppear(perform: loadWorkspace)
        }
    }

    private func documentsDirectory() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private func loadWorkspace() {
        guard workspaceURL == nil else { return }
        do {
            let directory = try documentsDirectory().appendingPathComponent("GuestWorkspace", isDirectory: true)
            if FileManager.default.fileExists(atPath: directory.path) {
                workspaceURL = directory
            } else {
                setupError = nil
            }
        } catch {
            setupError = "Could not access the app's Documents folder: \(error.localizedDescription)"
        }
    }

    private func createWorkspace() {
        do {
            let directory = try documentsDirectory().appendingPathComponent("GuestWorkspace", isDirectory: true)
            let manager = FileManager.default
            if !manager.fileExists(atPath: directory.path) {
                try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            // Preserve files from the earlier private Application Support workspace.
            let support = try manager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("GuestWorkspace", isDirectory: true)

            if manager.fileExists(atPath: support.path) {
                let oldItems = try manager.contentsOfDirectory(at: support, includingPropertiesForKeys: nil)
                for item in oldItems {
                    let destination = directory.appendingPathComponent(item.lastPathComponent)
                    if !manager.fileExists(atPath: destination.path) {
                        try manager.moveItem(at: item, to: destination)
                    }
                }
            }
            workspaceURL = directory
            setupError = nil
        } catch {
            setupError = "Could not create the sandbox: \(error.localizedDescription)"
        }
    }
}

private struct GuestDirectoryView: View {
    let directoryURL: URL

    @State private var items: [URL] = []
    @State private var showingNamePrompt = false
    @State private var createFolder = true
    @State private var newName = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    Text("Private to URX Core")
                        .font(.footnote.weight(.medium))
                    Spacer()
                    Text("LOCAL")
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(.green)
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))
            }

            Section {
                HStack {
                    Text("CONTENTS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        Button {
                            createFolder = true
                            newName = ""
                            showingNamePrompt = true
                        } label: {
                            Label("New folder", systemImage: "folder.badge.plus")
                        }
                        Button {
                            createFolder = false
                            newName = ""
                            showingNamePrompt = true
                        } label: {
                            Label("New text file", systemImage: "doc.badge.plus")
                        }
                        Divider()
                        Button {
                            refreshItems()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(.green)
                }
                .listRowBackground(Color.clear)

                if items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "folder")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text("This folder is empty").font(.headline)
                        Text("Create a folder or a text file to get started.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(items, id: \.standardizedFileURL) { item in
                        if isDirectory(item) {
                            NavigationLink(destination: GuestDirectoryView(directoryURL: item)) {
                                Label(item.lastPathComponent, systemImage: "folder.fill")
                                    .foregroundStyle(.primary)
                            }
                        } else {
                            Label(item.lastPathComponent, systemImage: "doc.text")
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: refreshItems)
        .alert(createFolder ? "New folder" : "New text file", isPresented: $showingNamePrompt) {
            TextField("Name", text: $newName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Create", action: createItem)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(createFolder ? "Choose a name for this folder." : "Choose a name for the text file.")
        }
    }

    private func refreshItems() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: [.skipsHiddenFiles]
            )
            items = urls.sorted {
                let leftIsDirectory = isDirectory($0)
                let rightIsDirectory = isDirectory($1)
                if leftIsDirectory != rightIsDirectory {
                    return leftIsDirectory && !rightIsDirectory
                }
                return $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
            errorMessage = nil
        } catch {
            errorMessage = "Could not read this folder: \(error.localizedDescription)"
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func createItem() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              name != ".",
              name != "..",
              !name.contains("/"),
              !name.contains("\\") else {
            errorMessage = "Use a non-empty name without path separators."
            return
        }

        let fileName = createFolder || name.lowercased().hasSuffix(".txt") ? name : name + ".txt"
        let destination = directoryURL.appendingPathComponent(fileName, isDirectory: createFolder)

        do {
            if createFolder {
                try FileManager.default.createDirectory(
                    at: destination,
                    withIntermediateDirectories: false
                )
            } else {
                try Data().write(to: destination, options: .withoutOverwriting)
            }
            refreshItems()
        } catch {
            errorMessage = "Could not create item: \(error.localizedDescription)"
        }
    }
}

struct PackageView: View {
    @State private var controlText = ""
    @State private var metadata: DebianPackageMetadata?
    @State private var parseError: String?
    @State private var showingPackageImporter = false
    @State private var importedFilename: String?
    @State private var dataFileEntries: [String] = []
    @State private var dataArchiveMessage: String?

    private let sample = """
    Package: example-tool
    Version: 1.2.0-1
    Architecture: iphoneos-arm64
    Maintainer: Example Team
    Section: Utilities
    Description: A sample package for metadata inspection
     This is a second line of the description.
    Depends: libexample (>= 2.0), another-package | alternative-package
    Conflicts: old-example
    Provides: example-api
    Replaces: legacy-example
    Installed-Size: 128
    Homepage: https://example.invalid
    """

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("METADATA INSPECTOR")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.green)
                        Text("Inspect Debian package control metadata without installing or running anything.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CONTROL DATA")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Open .deb") {
                                showingPackageImporter = true
                            }
                            .font(.caption.weight(.semibold))
                            .tint(.green)
                            Button("Load example") {
                                controlText = sample
                                importedFilename = nil
                                metadata = nil
                                parseError = nil
                            }
                            .font(.caption.weight(.semibold))
                            .tint(.green)
                        }

                        if let importedFilename {
                            Label(importedFilename, systemImage: "archivebox")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        TextEditor(text: $controlText)
                            .font(.system(.footnote, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(minHeight: 230)
                            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1))

                        Button(action: inspectMetadata) {
                            Label("Inspect metadata", systemImage: "doc.text.magnifyingglass")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(controlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 20))

                    if let parseError {
                        Label(parseError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if let metadata {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("PACKAGE DETAILS")
                                    .font(.caption.weight(.bold))
                                    .tracking(1)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("PARSED")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(.green.opacity(0.12), in: Capsule())
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(metadata.name)
                                    .font(.title2.bold())
                                Text(metadata.version)
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            metadataRow("Architecture", value: metadata.architecture)
                            if !metadata.maintainer.isEmpty {
                                metadataRow("Maintainer", value: metadata.maintainer)
                            }
                            if !metadata.section.isEmpty {
                                metadataRow("Section", value: metadata.section)
                            }
                            if !metadata.installedSize.isEmpty { metadataRow("Installed size", value: metadata.installedSize + " KB") }
                            if !metadata.author.isEmpty { metadataRow("Author", value: metadata.author) }
                            if !metadata.homepage.isEmpty { metadataRow("Homepage", value: metadata.homepage) }
                            if !metadata.depiction.isEmpty { metadataRow("Depiction", value: metadata.depiction) }
                            if !metadata.description.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("DESCRIPTION")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                    Text(metadata.description)
                                        .font(.footnote)
                                        .textSelection(.enabled)
                                }
                            }

                            if !metadata.preDepends.isEmpty { metadataTextSection("PRE-DEPENDS", value: metadata.preDepends) }
                            if !metadata.dependencyGroups.isEmpty {
                                Divider().overlay(.white.opacity(0.08))
                                Text("DEPENDENCIES")
                                    .font(.caption.weight(.bold))
                                    .tracking(1)
                                    .foregroundStyle(.secondary)
                                ForEach(Array(metadata.dependencyGroups.enumerated()), id: \.offset) { index, group in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("GROUP \(index + 1)")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        ForEach(Array(group.alternatives.enumerated()), id: \.offset) { alternativeIndex, requirement in
                                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                                Text(alternativeIndex == 0 ? "•" : "OR")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(alternativeIndex == 0 ? .green : .orange)
                                                Text(requirement.display)
                                                    .font(.footnote.monospaced())
                                                    .textSelection(.enabled)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 3)
                                }
                            } else {
                                Text("No dependencies declared.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if !metadata.conflicts.isEmpty { metadataTextSection("CONFLICTS", value: metadata.conflicts) }
                            if !metadata.provides.isEmpty { metadataTextSection("PROVIDES", value: metadata.provides) }
                            if !metadata.replaces.isEmpty { metadataTextSection("REPLACES", value: metadata.replaces) }
                            if !metadata.breaks.isEmpty { metadataTextSection("BREAKS", value: metadata.breaks) }
                            if !metadata.recommends.isEmpty { metadataTextSection("RECOMMENDS", value: metadata.recommends) }
                            if !metadata.suggests.isEmpty { metadataTextSection("SUGGESTS", value: metadata.suggests) }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
                    }

                    if let dataArchiveMessage {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PACKAGE CONTENTS")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(.secondary)
                            Text(dataArchiveMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if !dataFileEntries.isEmpty {
                                Text("\(dataFileEntries.count) entries")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                                ForEach(dataFileEntries, id: \.self) { path in
                                    Text(path)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
                    }

                    Label("Read-only inspection. No package installation, scripts, or system modifications.", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Packages")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingPackageImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false,
                onCompletion: handlePackageImport
            )
        }
    }

    private func metadataRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func metadataTextSection(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.bold)).tracking(1).foregroundStyle(.secondary)
            Text(value).font(.footnote.monospaced()).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func inspectMetadata() {
        do {
            metadata = try DebianControlParser.parse(controlText)
            dataFileEntries = []
            dataArchiveMessage = nil
            parseError = nil
        } catch {
            metadata = nil
            parseError = error.localizedDescription
        }
    }

    private func handlePackageImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
            guard fileSize > 0, fileSize <= 64 * 1024 * 1024 else {
                throw DebianArchiveReader.ArchiveError.archiveTooLarge
            }

            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let extractedControl = try DebianArchiveReader.controlText(from: data)
            let parsed = try DebianControlParser.parse(extractedControl)
            controlText = extractedControl
            metadata = parsed
            importedFilename = url.lastPathComponent
            parseError = nil
            do {
                dataFileEntries = try DebianDataArchiveInspector.fileEntries(from: data)
                dataArchiveMessage = "File paths only. Nothing is extracted, installed, or executed."
            } catch {
                dataFileEntries = []
                dataArchiveMessage = error.localizedDescription
            }
        } catch {
            metadata = nil
            parseError = error.localizedDescription
        }
    }
}

private struct DebianDependencyRequirement {
    let name: String
    let operatorText: String?
    let version: String?

    var display: String {
        guard let operatorText, let version else { return name }
        return "\(name) (\(operatorText) \(version))"
    }
}

private struct DebianDependencyGroup {
    let alternatives: [DebianDependencyRequirement]
}

private struct DebianPackageMetadata {
    let name: String
    let version: String
    let architecture: String
    let maintainer: String
    let section: String
    let description: String
    let dependencyGroups: [DebianDependencyGroup]
    let conflicts: String
    let provides: String
    let replaces: String
    let preDepends: String
    let breaks: String
    let recommends: String
    let suggests: String
    let author: String
    let homepage: String
    let depiction: String
    let installedSize: String
}

private enum DebianControlParser {
    enum ParseError: LocalizedError {
        case missingField(String)
        case malformedLine(Int)

        var errorDescription: String? {
            switch self {
            case .missingField(let field):
                return "Required field is missing: \(field)"
            case .malformedLine(let line):
                return "Could not read control data near line \(line). Check the field format."
            }
        }
    }

    static func parse(_ source: String) throws -> DebianPackageMetadata {
        var fields: [String: String] = [:]
        var currentKey: String?
        let lines = source.components(separatedBy: .newlines)

        for (index, rawLine) in lines.enumerated() {
            if rawLine.isEmpty || rawLine.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            if rawLine.hasPrefix("#") {
                continue
            }

            if rawLine.hasPrefix(" ") || rawLine.hasPrefix("\t") {
                guard let key = currentKey else {
                    throw ParseError.malformedLine(index + 1)
                }
                let continuation = String(rawLine.dropFirst()).trimmingCharacters(in: .newlines)
                fields[key, default: ""] += "\n" + continuation
                continue
            }

            guard let colon = rawLine.firstIndex(of: ":") else {
                throw ParseError.malformedLine(index + 1)
            }
            let key = rawLine[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = rawLine[rawLine.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else {
                throw ParseError.malformedLine(index + 1)
            }
            fields[key] = value
            currentKey = key
        }

        func required(_ key: String) throws -> String {
            guard let value = fields[key], !value.isEmpty else {
                throw ParseError.missingField(key.capitalized)
            }
            return value
        }

        let dependencyText = fields["depends"] ?? ""
        let dependencyGroups = try parseDependencyGroups(dependencyText)

        return DebianPackageMetadata(
            name: try required("package"),
            version: try required("version"),
            architecture: try required("architecture"),
            maintainer: fields["maintainer"] ?? "",
            section: fields["section"] ?? "",
            description: (fields["description"] ?? "").replacingOccurrences(of: "\n", with: " "),
            dependencyGroups: dependencyGroups,
            conflicts: fields["conflicts"] ?? "",
            provides: fields["provides"] ?? "",
            replaces: fields["replaces"] ?? "",
            preDepends: fields["pre-depends"] ?? "",
            breaks: fields["breaks"] ?? "",
            recommends: fields["recommends"] ?? "",
            suggests: fields["suggests"] ?? "",
            author: fields["author"] ?? "",
            homepage: fields["homepage"] ?? "",
            depiction: fields["depiction"] ?? "",
            installedSize: fields["installed-size"] ?? ""
        )
    }

    private static func parseDependencyGroups(_ source: String) throws -> [DebianDependencyGroup] {
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let groupStrings = splitTopLevel(source, separator: ",")
        return try groupStrings.map { groupText in
            let alternatives = splitTopLevel(groupText, separator: "|")
            let requirements = try alternatives.map { rawRequirement -> DebianDependencyRequirement in
                let requirement = rawRequirement.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !requirement.isEmpty else {
                    throw ParseError.malformedLine(1)
                }

                guard let openParen = requirement.firstIndex(of: "(") else {
                    return DebianDependencyRequirement(name: requirement, operatorText: nil, version: nil)
                }
                guard let closeParen = requirement[openParen...].firstIndex(of: ")") else {
                    throw ParseError.malformedLine(1)
                }

                let name = requirement[..<openParen].trimmingCharacters(in: .whitespaces)
                let constraint = requirement[requirement.index(after: openParen)..<closeParen]
                    .trimmingCharacters(in: .whitespaces)
                let pieces = constraint.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
                guard !name.isEmpty, pieces.count == 2 else {
                    throw ParseError.malformedLine(1)
                }
                let allowedOperators: Set<String> = [">>", ">=", "=", "<=", "<<"]
                let operatorText = String(pieces[0])
                let version = String(pieces[1])
                guard allowedOperators.contains(operatorText), !version.isEmpty else {
                    throw ParseError.malformedLine(1)
                }
                return DebianDependencyRequirement(name: name, operatorText: operatorText, version: version)
            }
            return DebianDependencyGroup(alternatives: requirements)
        }
    }

    private static func splitTopLevel(_ source: String, separator: Character) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0

        for character in source {
            if character == "(" || character == "[" {
                depth += 1
            } else if character == ")" || character == "]" {
                depth = max(0, depth - 1)
            }

            if character == separator && depth == 0 {
                parts.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(character)
            }
        }

        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return parts
    }
}
