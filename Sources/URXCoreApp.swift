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
                ToolbarItem(placement: .topBarTrailing) {
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
    @State private var message = "No guest workspace created yet."

    var body: some View {
        NavigationStack {
            List {
                Section("Local workspace") {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                    Button { createWorkspace() } label: {
                        Label("Create guest workspace", systemImage: "plus.square")
                    }
                    .disabled(workspaceURL != nil)
                    if let workspaceURL {
                        Text(workspaceURL.lastPathComponent).font(.caption.monospaced())
                    }
                }
                Section("Isolation") {
                    Text("This is an ordinary directory inside URX Core's app container, not a virtualized copy of iOS. It cannot access host system files.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Guest")
        }
    }

    private func createWorkspace() {
        do {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directory = base.appendingPathComponent("GuestWorkspace", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            workspaceURL = directory
            message = "Guest workspace is ready inside the app container."
        } catch {
            message = "Could not create workspace: \(error.localizedDescription)"
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
