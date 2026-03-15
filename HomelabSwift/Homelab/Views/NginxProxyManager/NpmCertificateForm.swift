import SwiftUI

struct NpmCertificateForm: View {
    let onSave: (NpmCertificateRequest) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var niceName = ""
    @State private var domainNames: [String] = []
    @State private var newDomain = ""
    @State private var letsencryptEmail = ""
    @State private var dnsChallenge = false
    @State private var agreedTos = false
    @State private var isSaving = false

    private let npmColor = Color(hex: "#F15B2A")

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(localizer.t.npmNiceName, text: $niceName)
                }

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

                Section {
                    TextField(localizer.t.npmLetsencryptEmail, text: $letsencryptEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    Toggle(localizer.t.npmDnsChallenge, isOn: $dnsChallenge)

                    Toggle(localizer.t.npmLetsencryptAgree, isOn: $agreedTos)
                }
            }
            .navigationTitle(localizer.t.npmAddCertificate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(domainNames.isEmpty || letsencryptEmail.isEmpty || !agreedTos || isSaving)
                        .fontWeight(.semibold)
                }
            }
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

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let request = NpmCertificateRequest(
            provider: "letsencrypt",
            niceName: niceName,
            domainNames: domainNames,
            meta: NpmCertificateRequestMeta(
                letsencryptAgree: agreedTos,
                letsencryptEmail: letsencryptEmail,
                dnsChallenge: dnsChallenge
            )
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
