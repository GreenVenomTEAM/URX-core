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
