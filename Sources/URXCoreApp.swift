import SwiftUI

@main
struct URXCoreApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Overview", systemImage: "square.grid.2x2") }
            GuestWorkspaceView()
                .tabItem { Label("Guest", systemImage: "externaldrive") }
            PackageView()
                .tabItem { Label("Packages", systemImage: "shippingbox") }
            CertificateImportView()
                .tabItem { Label("Identity", systemImage: "checkmark.seal") }
        }
        .tint(.green)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("URX CORE")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.green)
                        Text("Unc0veR rEb0rnEd X Core")
                            .font(.title3.weight(.semibold))
                        Text("GreenVenom Team")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(Color.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeading("ENVIRONMENT")
                        statusRow("Host iOS remains untouched", detail: "The host device is not modified.", icon: "lock.shield", color: .green)
                        Divider().overlay(Color.white.opacity(0.08))
                        statusRow("Guest workspace", detail: "Local app-container prototype.", icon: "externaldrive", color: .green)
                        Divider().overlay(Color.white.opacity(0.08))
                        statusRow("Package execution", detail: "Not implemented.", icon: "pause.circle", color: .orange)
                    }
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeading("PROJECT STATUS")
                        statusLine("Foundation", value: "In progress")
                        statusLine("Guest runtime", value: "Research")
                        statusLine("Sileo compatibility", value: "Not evaluated")
                    }
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))

                    Text("URX Core is an app-contained research project. It does not jailbreak this device or enable arbitrary system tweaks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(.secondary)
    }

    private func statusRow(_ title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .font(.subheadline)
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
