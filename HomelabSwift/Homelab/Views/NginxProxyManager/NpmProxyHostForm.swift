import SwiftUI

struct NpmProxyHostForm: View {
    let editing: NpmProxyHost?
    let certificates: [NpmCertificate]
    let accessLists: [NpmAccessList]
    let onSave: (NpmProxyHostRequest) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var domainNames: [String] = []
    @State private var newDomain = ""
    @State private var forwardScheme = "http"
    @State private var forwardHost = ""
    @State private var forwardPort = "80"
    @State private var certificateId = 0
    @State private var accessListId = 0
    @State private var sslForced = false
    @State private var cachingEnabled = false
    @State private var blockExploits = true
    @State private var websocket = false
    @State private var http2 = false
    @State private var hsts = false
    @State private var hstsSubdomains = false
    @State private var enabled = true
    @State private var advancedConfig = ""
    @State private var isSaving = false

    private let npmColor = Color(hex: "#F15B2A")

    init(editing: NpmProxyHost? = nil, certificates: [NpmCertificate], accessLists: [NpmAccessList], onSave: @escaping (NpmProxyHostRequest) async throws -> Void) {
        self.editing = editing
        self.certificates = certificates
        self.accessLists = accessLists
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                domainsSection
                forwardingSection
                securitySection
                featuresSection
                advancedSection
            }
            .navigationTitle(editing == nil ? localizer.t.npmAddProxyHost : localizer.t.npmEditProxyHost)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(domainNames.isEmpty || forwardHost.isEmpty || isSaving)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    // MARK: - Domains

    private var domainsSection: some View {
        Section(localizer.t.npmDomainNames) {
            HStack {
                TextField(localizer.t.npmDomainNamesHint, text: $newDomain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button {
                    addDomain()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(npmColor)
                }
                .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            FlowLayout(spacing: 6) {
                ForEach(domainNames, id: \.self) { domain in
                    domainChip(domain)
                }
            }
        }
    }

    // MARK: - Forwarding

    private var forwardingSection: some View {
        Section {
            Picker(localizer.t.npmForwardScheme, selection: $forwardScheme) {
                Text("http").tag("http")
                Text("https").tag("https")
            }

            TextField(localizer.t.npmForwardHost, text: $forwardHost)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField(localizer.t.npmForwardPort, text: $forwardPort)
                .keyboardType(.numberPad)

            Picker(localizer.t.npmCertificate, selection: $certificateId) {
                Text(localizer.t.npmCertificateNone).tag(0)
                ForEach(certificates) { cert in
                    Text(cert.niceName.isEmpty ? cert.primaryDomain : cert.niceName).tag(cert.id)
                }
            }

            Picker(localizer.t.npmAccessList, selection: $accessListId) {
                Text(localizer.t.npmAccessListNone).tag(0)
                ForEach(accessLists) { al in
                    Text(al.name).tag(al.id)
                }
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section {
            Toggle(localizer.t.npmSslForced, isOn: $sslForced)
            Toggle(localizer.t.npmSecurity, isOn: $blockExploits)
            Toggle(localizer.t.npmHsts, isOn: $hsts)
            if hsts {
                Toggle(localizer.t.npmHstsSubdomains, isOn: $hstsSubdomains)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        Section {
            Toggle(localizer.t.npmCachingEnabled, isOn: $cachingEnabled)
            Toggle(localizer.t.npmWebsocket, isOn: $websocket)
            Toggle(localizer.t.npmHttp2, isOn: $http2)
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section(localizer.t.npmAdvancedConfig) {
            TextEditor(text: $advancedConfig)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80)
        }
    }

    // MARK: - Helpers

    private func domainChip(_ domain: String) -> some View {
        HStack(spacing: 4) {
            Text(domain)
                .font(.caption)
                .lineLimit(1)
            Button {
                domainNames.removeAll { $0 == domain }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(npmColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .foregroundStyle(npmColor)
    }

    private func addDomain() {
        let trimmed = newDomain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !domainNames.contains(trimmed) else { return }
        domainNames.append(trimmed)
        newDomain = ""
    }

    private func prefill() {
        guard let h = editing else { return }
        domainNames = h.domainNames
        forwardScheme = h.forwardScheme
        forwardHost = h.forwardHost
        forwardPort = "\(h.forwardPort)"
        certificateId = h.certificateId
        accessListId = h.accessListId
        sslForced = h.sslForced == 1
        cachingEnabled = h.cachingEnabled == 1
        blockExploits = h.blockExploits == 1
        websocket = h.allowWebsocketUpgrade == 1
        http2 = h.http2Support == 1
        hsts = h.hstsEnabled == 1
        hstsSubdomains = false
        enabled = h.isEnabled
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let request = NpmProxyHostRequest(
            domainNames: domainNames,
            forwardScheme: forwardScheme,
            forwardHost: forwardHost,
            forwardPort: Int(forwardPort) ?? 80,
            certificateId: certificateId,
            accessListId: accessListId,
            sslForced: sslForced ? 1 : 0,
            cachingEnabled: cachingEnabled ? 1 : 0,
            blockExploits: blockExploits ? 1 : 0,
            allowWebsocketUpgrade: websocket ? 1 : 0,
            http2Support: http2 ? 1 : 0,
            hstsEnabled: hsts ? 1 : 0,
            hstsSubdomains: hstsSubdomains ? 1 : 0,
            enabled: enabled ? 1 : 0,
            advancedConfig: advancedConfig,
            meta: nil
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

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalSize: CGSize = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalSize.width = max(totalSize.width, currentX - spacing)
        }
        totalSize.height = currentY + lineHeight
        return (offsets, totalSize)
    }
}
