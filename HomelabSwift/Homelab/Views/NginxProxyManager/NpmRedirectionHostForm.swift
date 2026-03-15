import SwiftUI

struct NpmRedirectionHostForm: View {
    let editing: NpmRedirectionHost?
    let certificates: [NpmCertificate]
    let accessLists: [NpmAccessList]
    let onSave: (NpmRedirectionHostRequest) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var domainNames: [String] = []
    @State private var newDomain = ""
    @State private var forwardHttpCode = 302
    @State private var forwardScheme = "http"
    @State private var forwardDomainName = ""
    @State private var preservePath = false
    @State private var certificateId = 0
    @State private var accessListId = 0
    @State private var sslForced = false
    @State private var blockExploits = true
    @State private var http2 = false
    @State private var hsts = false
    @State private var hstsSubdomains = false
    @State private var enabled = true
    @State private var isSaving = false

    private let npmColor = Color(hex: "#F15B2A")

    var body: some View {
        NavigationStack {
            Form {
                domainsSection
                redirectionSection
                securitySection
                optionsSection
            }
            .navigationTitle(editing == nil ? localizer.t.npmAddRedirection : localizer.t.npmEditRedirection)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(domainNames.isEmpty || forwardDomainName.isEmpty || isSaving)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var domainsSection: some View {
        Section(localizer.t.npmDomainNames) {
            HStack {
                TextField(localizer.t.npmDomainNamesHint, text: $newDomain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button { addDomain() } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(npmColor)
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

    private var redirectionSection: some View {
        Section {
            Picker(localizer.t.npmForwardHttpCode, selection: $forwardHttpCode) {
                Text("301 – Permanent").tag(301)
                Text("302 – Temporary").tag(302)
            }

            Picker(localizer.t.npmForwardScheme, selection: $forwardScheme) {
                Text("http").tag("http")
                Text("https").tag("https")
            }

            TextField(localizer.t.npmForwardDomain, text: $forwardDomainName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Toggle(localizer.t.npmPreservePath, isOn: $preservePath)

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

    private var optionsSection: some View {
        Section {
            Toggle(localizer.t.npmHttp2, isOn: $http2)
            Toggle(localizer.t.npmEnabled, isOn: $enabled)
        }
    }

    private func domainChip(_ domain: String) -> some View {
        HStack(spacing: 4) {
            Text(domain).font(.caption).lineLimit(1)
            Button { domainNames.removeAll { $0 == domain } } label: {
                Image(systemName: "xmark.circle.fill").font(.caption2)
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
        forwardHttpCode = h.forwardHttpCode
        forwardScheme = h.forwardScheme
        forwardDomainName = h.forwardDomainName
        preservePath = h.preservePath == 1
        certificateId = h.certificateId
        accessListId = h.accessListId
        sslForced = h.sslForced == 1
        blockExploits = h.blockExploits == 1
        http2 = h.http2Support == 1
        hsts = h.hstsEnabled == 1
        hstsSubdomains = h.hstsSubdomains == 1
        enabled = h.isEnabled
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let request = NpmRedirectionHostRequest(
            domainNames: domainNames,
            forwardHttpCode: forwardHttpCode,
            forwardScheme: forwardScheme,
            forwardDomainName: forwardDomainName,
            preservePath: preservePath ? 1 : 0,
            certificateId: certificateId,
            accessListId: accessListId,
            sslForced: sslForced ? 1 : 0,
            hstsEnabled: hsts ? 1 : 0,
            hstsSubdomains: hstsSubdomains ? 1 : 0,
            http2Support: http2 ? 1 : 0,
            blockExploits: blockExploits ? 1 : 0,
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
