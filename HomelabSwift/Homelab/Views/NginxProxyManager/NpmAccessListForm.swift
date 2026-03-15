import SwiftUI

struct NpmAccessListForm: View {
    let editing: NpmAccessList?
    let onSave: (NpmAccessListRequest) async throws -> Void
    let onDelete: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var name: String = ""

    @State private var items: [NpmAccessListItem] = []
    @State private var newUsername: String = ""
    @State private var newPassword: String = ""

    @State private var clients: [NpmAccessListClient] = []
    @State private var newClientAddress: String = ""
    @State private var newClientDirective: String = "allow"

    @State private var isSaving = false
    @State private var showingDeleteConfirm = false

    private let npmColor = Color(hex: "#F15B2A")

    init(
        editing: NpmAccessList? = nil,
        onSave: @escaping (NpmAccessListRequest) async throws -> Void,
        onDelete: (() async -> Void)? = nil
    ) {
        self.editing = editing
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(localizer.t.npmAccessList, text: $name)
                }

                usersSection
                clientsSection

                if editing != nil {
                    Section {
                        Button(localizer.t.npmDelete, role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? (localizer.t.npmAddAccessList) : localizer.t.npmEditAccessList)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
            .onChange(of: editing?.id) { _, _ in prefill() }
            .alert(localizer.t.npmDeleteConfirmTitle, isPresented: $showingDeleteConfirm) {
                Button(localizer.t.npmDelete, role: .destructive) {
                    Task {
                        await onDelete?()
                        dismiss()
                    }
                }
                Button(localizer.t.cancel, role: .cancel) { }
            } message: {
                Text(localizer.t.npmDeleteConfirm)
            }
        }
    }

    private var usersSection: some View {
        Section(localizer.t.npmAccessListUsers) {
            HStack {
                TextField(localizer.t.npmAccessListUsername, text: $newUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField(localizer.t.npmAccessListPassword, text: $newPassword)

                Button {
                    addUser()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(npmColor)
                }
                .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty || newPassword.isEmpty)
            }

            if items.isEmpty {
                Text(localizer.t.npmAccessListNoUsers)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.username)
                        Spacer()
                        if !item.password.isEmpty {
                            Text("••••••")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Button(role: .destructive) {
                            items.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private var clientsSection: some View {
        Section(localizer.t.npmAccessListClients) {
            let directiveLabel = newClientDirective == "deny" ? localizer.t.npmAccessListDeny : localizer.t.npmAccessListAllow

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TextField(localizer.t.npmAccessListAddress, text: $newClientAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        addClient()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(npmColor)
                    }
                    .disabled(newClientAddress.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ViewThatFits(in: .horizontal) {
                    Picker("", selection: $newClientDirective) {
                        Text(localizer.t.npmAccessListAllow).tag("allow")
                        Text(localizer.t.npmAccessListDeny).tag("deny")
                    }
                    .pickerStyle(.segmented)

                    Picker(directiveLabel, selection: $newClientDirective) {
                        Text(localizer.t.npmAccessListAllow).tag("allow")
                        Text(localizer.t.npmAccessListDeny).tag("deny")
                    }
                    .pickerStyle(.menu)
                }
            }

            if clients.isEmpty {
                Text(localizer.t.npmAccessListNoClients)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(Array(clients.enumerated()), id: \.offset) { index, client in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(client.address)
                            Text(client.directive == "deny" ? localizer.t.npmAccessListDeny : localizer.t.npmAccessListAllow)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            clients.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private func addUser() {
        let trimmedUser = newUsername.trimmingCharacters(in: .whitespaces)
        guard !trimmedUser.isEmpty, !newPassword.isEmpty else { return }
        items.append(NpmAccessListItem(username: trimmedUser, password: newPassword))
        newUsername = ""
        newPassword = ""
    }

    private func addClient() {
        let trimmedAddress = newClientAddress.trimmingCharacters(in: .whitespaces)
        guard !trimmedAddress.isEmpty else { return }
        clients.append(NpmAccessListClient(address: trimmedAddress, directive: newClientDirective))
        newClientAddress = ""
    }

    private func prefill() {
        guard let list = editing else {
            name = ""
            items = []
            clients = []
            return
        }
        name = list.name
        items = list.items ?? []
        clients = list.clients ?? []
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let request = NpmAccessListRequest(
            name: trimmedName,
            items: items,
            clients: clients
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
