import SwiftUI

struct NpmUserForm: View {
    let editing: NpmUser?
    let onSave: (NpmUserRequest) async throws -> Void
    let onDelete: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(Localizer.self) private var localizer

    @State private var email: String = ""
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var password: String = ""
    @State private var selectedRole: String = "user"
    @State private var isDisabled: Bool = false
    @State private var isSaving = false
    @State private var showingDeleteConfirm = false

    init(
        editing: NpmUser? = nil,
        onSave: @escaping (NpmUserRequest) async throws -> Void,
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
                    TextField(localizer.t.npmUserEmail, text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField(localizer.t.npmUserName, text: $name)
                    TextField(localizer.t.npmUserNickname, text: $nickname)
                }

                Section(footer: passwordFooter) {
                    SecureField(localizer.t.npmUserPassword, text: $password)
                }

                Section {
                    ViewThatFits(in: .horizontal) {
                        Picker(localizer.t.npmUserRole, selection: $selectedRole) {
                            Text(localizer.t.npmUserRoleAdmin).tag("admin")
                            Text(localizer.t.npmUserRoleUser).tag("user")
                        }
                        .pickerStyle(.segmented)

                        Picker(localizer.t.npmUserRole, selection: $selectedRole) {
                            Text(localizer.t.npmUserRoleAdmin).tag("admin")
                            Text(localizer.t.npmUserRoleUser).tag("user")
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle(localizer.t.npmDisabled, isOn: $isDisabled)
                }

                if editing != nil {
                    Section {
                        Button(localizer.t.npmDelete, role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? localizer.t.npmAddUser : localizer.t.npmEditUser)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizer.t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t.save) { Task { await save() } }
                        .disabled(!canSave || isSaving)
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

    private var passwordFooter: some View {
        Group {
            if editing != nil {
                Text(localizer.t.npmUserPasswordHint)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }

    private var canSave: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
            (editing != nil || !password.isEmpty)
    }

    private func prefill() {
        guard let user = editing else {
            email = ""
            name = ""
            nickname = ""
            password = ""
            selectedRole = "user"
            isDisabled = false
            return
        }

        email = user.email ?? ""
        name = user.name ?? ""
        nickname = user.nickname ?? ""
        password = ""
        if let roles = user.roles, roles.contains("admin") {
            selectedRole = "admin"
        } else {
            selectedRole = "user"
        }
        isDisabled = user.isDisabled ?? false
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespaces)
        let request = NpmUserRequest(
            email: trimmedEmail,
            name: trimmedName.isEmpty ? nil : trimmedName,
            nickname: trimmedNickname.isEmpty ? nil : trimmedNickname,
            password: password.isEmpty ? nil : password,
            roles: [selectedRole],
            isDisabled: isDisabled
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
