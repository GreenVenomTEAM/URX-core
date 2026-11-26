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
                    ContentUnavailableView(
                        "Workspace unavailable",
                        systemImage: "externaldrive.badge.exclamationmark",
                        description: Text(setupError)
                    )
                } else {
                    ProgressView("Preparing guest workspace…")
                }
            }
            .navigationTitle("Guest")
            .onAppear(perform: prepareWorkspace)
        }
    }

    private func prepareWorkspace() {
        guard workspaceURL == nil, setupError == nil else { return }
        do {
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = base.appendingPathComponent("GuestWorkspace", isDirectory: true)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            workspaceURL = directory
        } catch {
            setupError = "Could not prepare the private workspace: \(error.localizedDescription)"
        }
    }
}

private struct GuestDirectoryView: View {
    let directoryURL: URL

    @State private var items: [URL] = []
    @State private var showingCreateMenu = false
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

            Section("CONTENTS") {
                if items.isEmpty {
                    ContentUnavailableView(
                        "This folder is empty",
                        systemImage: "folder",
                        description: Text("Create a folder or a text file to get started.")
                    )
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .tint(.green)
            }
        }
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("No packages yet").font(.headline)
                Text("The prototype does not install or execute .deb packages. A future milestone will parse package metadata and dependencies without running package scripts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Packages")
        }
    }
}
