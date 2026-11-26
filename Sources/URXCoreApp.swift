import SwiftUI

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
    var body: some View {
        GeometryReader { geometry in
            TabView {
                DashboardView()
                    .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
                GuestWorkspaceView()
                    .tabItem { Label("Guest", systemImage: "externaldrive.fill") }
                PackageView()
                    .tabItem { Label("Packages", systemImage: "shippingbox.fill") }
                CertificateImportView()
                    .tabItem { Label("Identity", systemImage: "checkmark.seal.fill") }
            }
            .tint(Color(red: 0.35, green: 0.95, blue: 0.55))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.ignoresSafeArea())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

struct DashboardView: View {
    private let accent = Color(red: 0.35, green: 0.95, blue: 0.55)

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

    private let sample = """
    Package: example-tool
    Version: 1.2.0-1
    Architecture: iphoneos-arm64
    Maintainer: Example Team
    Section: Utilities
    Description: A sample package for metadata inspection
     This is a second line of the description.
    Depends: libexample (>= 2.0), another-package | alternative-package
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
                            Button("Load example") {
                                controlText = sample
                                metadata = nil
                                parseError = nil
                            }
                            .font(.caption.weight(.semibold))
                            .tint(.green)
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

                            if !metadata.dependencies.isEmpty {
                                Divider().overlay(.white.opacity(0.08))
                                Text("DEPENDENCIES")
                                    .font(.caption.weight(.bold))
                                    .tracking(1)
                                    .foregroundStyle(.secondary)
                                ForEach(metadata.dependencies, id: \.self) { dependency in
                                    Label(dependency, systemImage: "arrow.triangle.branch")
                                        .font(.footnote.monospaced())
                                }
                            } else {
                                Text("No dependencies declared.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
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

    private func inspectMetadata() {
        do {
            metadata = try DebianControlParser.parse(controlText)
            parseError = nil
        } catch {
            metadata = nil
            parseError = error.localizedDescription
        }
    }
}

private struct DebianPackageMetadata {
    let name: String
    let version: String
    let architecture: String
    let maintainer: String
    let section: String
    let description: String
    let dependencies: [String]
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
        let dependencies = dependencyText
            .split(separator: ",")
            .map { component -> String in
                let firstAlternative = component.split(separator: "|", maxSplits: 1).first ?? component[...]
                let withoutConstraint = firstAlternative
                    .split(whereSeparator: { $0 == "(" || $0 == "[" || $0 == "<" })
                    .first ?? firstAlternative
                return withoutConstraint.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        return DebianPackageMetadata(
            name: try required("package"),
            version: try required("version"),
            architecture: try required("architecture"),
            maintainer: fields["maintainer"] ?? "",
            section: fields["section"] ?? "",
            description: (fields["description"] ?? "").replacingOccurrences(of: "\n", with: " "),
            dependencies: dependencies
        )
    }
}
