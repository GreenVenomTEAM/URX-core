import SwiftUI

@main
struct URXCoreApp: App {
    var body: some Scene {
        WindowGroup { RootView().preferredColorScheme(.dark) }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Overview", systemImage: "square.grid.2x2") }
            GuestWorkspaceView().tabItem { Label("Guest", systemImage: "externaldrive") }
            PackageView().tabItem { Label("Packages", systemImage: "shippingbox") }
            CertificateImportView().tabItem { Label("Identity", systemImage: "checkmark.seal") }
        }.tint(.green)
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URX CORE").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.green)
                        Text("Unc0veR rEb0rnEd X Core").font(.headline)
                        Text("GreenVenom Team").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }
                Section("Environment") {
                    Label("Host iOS remains untouched", systemImage: "lock.shield")
                    Label("Guest workspace: local prototype", systemImage: "externaldrive")
                    Label("Package execution: not implemented", systemImage: "pause.circle")
                }
                Section("Project status") {
                    LabeledContent("Foundation", value: "In progress")
                    LabeledContent("Guest runtime", value: "Research")
                    LabeledContent("Sileo compatibility", value: "Not evaluated")
                }
                Section { Text("URX Core is an app-contained research project. It does not jailbreak this device or enable arbitrary system tweaks.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("Dashboard")
        }
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
                    Button { createWorkspace() } label: { Label("Create guest workspace", systemImage: "plus.square") }.disabled(workspaceURL != nil)
                    if let workspaceURL { Text(workspaceURL.lastPathComponent).font(.caption.monospaced()) }
                }
                Section("Isolation") { Text("This is an ordinary directory inside URX Core's app container, not a virtualized copy of iOS. It cannot access host system files.").font(.footnote) }
            }.navigationTitle("Guest")
        }
    }
    private func createWorkspace() {
        do {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directory = base.appendingPathComponent("GuestWorkspace", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            workspaceURL = directory
            message = "Guest workspace is ready inside the app container."
        } catch { message = "Could not create workspace: \(error.localizedDescription)" }
    }
}

struct PackageView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "shippingbox").font(.system(size: 42)).foregroundStyle(.secondary)
                Text("No packages yet").font(.headline)
                Text("The prototype does not install or execute .deb packages. A future milestone will parse package metadata and dependencies without running package scripts.")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).navigationTitle("Packages")
        }
    }
}
