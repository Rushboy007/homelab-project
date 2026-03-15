import SwiftUI

struct NpmStreamForm: View {
    let editing: NpmStream?
    let onSave: (NpmStreamRequest) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var incomingPort = ""
    @State private var forwardingHost = ""
    @State private var forwardingPort = ""
    @State private var tcpForwarding = true
    @State private var udpForwarding = false
    @State private var enabled = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(localizer.t.npmIncomingPort, text: $incomingPort)
                        .keyboardType(.numberPad)

                    TextField(localizer.t.npmForwardingHost, text: $forwardingHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(localizer.t.npmForwardingPort, text: $forwardingPort)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle(localizer.t.npmTcpForwarding, isOn: $tcpForwarding)
                    Toggle(localizer.t.npmUdpForwarding, isOn: $udpForwarding)
                    Toggle(localizer.t.npmEnabled, isOn: $enabled)
                }
            }
            .navigationTitle(editing == nil ? localizer.t.npmAddStream : localizer.t.npmEditStream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(incomingPort.isEmpty || forwardingHost.isEmpty || forwardingPort.isEmpty || isSaving)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard let s = editing else { return }
        incomingPort = "\(s.incomingPort)"
        forwardingHost = s.forwardingHost
        forwardingPort = "\(s.forwardingPort)"
        tcpForwarding = s.tcpForwarding == 1
        udpForwarding = s.udpForwarding == 1
        enabled = s.isEnabled
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let request = NpmStreamRequest(
            incomingPort: Int(incomingPort) ?? 0,
            forwardingHost: forwardingHost,
            forwardingPort: Int(forwardingPort) ?? 0,
            tcpForwarding: tcpForwarding ? 1 : 0,
            udpForwarding: udpForwarding ? 1 : 0,
            enabled: enabled ? 1 : 0
        )
        do {
            try await onSave(request)
            HapticManager.success()
            dismiss()
        } catch {
            HapticManager.error()
        }
    }
}
