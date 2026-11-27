import SwiftUI

struct URXSettingsView: View {
    @ObservedObject var runtime: URXExtensionRuntime
    @State private var showingDiagnostics = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(runtime.activeAccent)
                            .frame(width: 54, height: 54)
                            .background(runtime.activeAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("URX Core").font(.headline)
                            Text("Foundation • Experimental")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("GreenVenom Team")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("0.2")
                            .font(.caption.monospaced().bold())
                            .foregroundStyle(runtime.activeAccent)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Environment")
                }

                Section("Appearance") {
                    Picker("URX theme", selection: $runtime.selectedThemeID) {
                        ForEach(runtime.themes) { theme in
                            HStack {
                                Circle().fill(Color(hexRGB: theme.accentHex)).frame(width: 10, height: 10)
                                Text(theme.name)
                            }
                            .tag(theme.id)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(runtime.themes) { theme in
                            Circle()
                                .fill(Color(hexRGB: theme.accentHex))
                                .frame(height: 28)
                                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                        }
                    }
                    Text("Extensions with an accent color can override the selected theme accent while enabled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Runtime status") {
                    LabeledContent("Extensions", value: "\(runtime.extensions.count)")
                    LabeledContent("Enabled", value: "\(runtime.enabledIDs.count)")
                    LabeledContent("Shell generation", value: "\(runtime.shellGeneration)")
                    HStack {
                        Text("Active accent")
                        Spacer()
                        Circle()
                            .fill(runtime.activeAccent)
                            .frame(width: 18, height: 18)
                        Text("LIVE")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        runtime.respring()
                    } label: {
                        Label("Respring URX shell", systemImage: "arrow.clockwise")
                    }
                    .tint(runtime.activeAccent)
                }

                Section {
                    DisclosureGroup(isExpanded: $showingDiagnostics) {
                        if runtime.eventLog.isEmpty {
                            Text("No runtime events yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(runtime.eventLog.enumerated()), id: \.offset) { _, entry in
                                Text(entry)
                                    .font(.system(.caption2, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        Button("Clear diagnostics", role: .destructive) {
                            runtime.clearEventLog()
                        }
                    } label: {
                        Label("Runtime diagnostics", systemImage: "waveform.path")
                    }
                } footer: {
                    Text("The log is stored locally in the URX Core app container and keeps the latest 50 events.")
                }

                Section("About this build") {
                    Label("Host iOS is not modified", systemImage: "lock.shield")
                    Label("No native tweak code is executed", systemImage: "checkmark.shield")
                    Label("Package installation is not implemented yet", systemImage: "shippingbox")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .tint(runtime.activeAccent)
    }
}

private extension Color {
    init(hexRGB: String) {
        let value = UInt64(hexRGB, radix: 16) ?? 0x659BFF
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}
