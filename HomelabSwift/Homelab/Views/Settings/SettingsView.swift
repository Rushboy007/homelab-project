import SwiftUI

// Maps to app/(tabs)/settings/index.tsx

struct SettingsView: View {
    @Environment(ServicesStore.self) private var servicesStore
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(Localizer.self) private var localizer

    @State private var fallbackInputs: [ServiceType: String] = [:]
    @State private var showDisconnectAlert: ServiceType? = nil

    var body: some View {
        NavigationStack {
            List {
                preferencesSection
                servicesSection
                aboutSection
            }
            .navigationTitle(localizer.t.tabSettings)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section(localizer.t.settingsPreferences) {
            // Language picker
            VStack(alignment: .leading, spacing: 12) {
                Label(localizer.t.settingsLanguage, systemImage: "globe")
                    .font(.body)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Button {
                            HapticManager.light()
                            settingsStore.language = lang
                            localizer.language = lang
                        } label: {
                            HStack(spacing: 8) {
                                Text(lang.flagEmoji)
                                Text(languageDisplayName(lang))
                                    .font(.subheadline)
                                    .fontWeight(settingsStore.language == lang ? .semibold : .regular)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                settingsStore.language == lang
                                    ? AppTheme.accent.opacity(0.1)
                                    : Color(.tertiarySystemFill)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        settingsStore.language == lang ? AppTheme.accent.opacity(0.3) : .clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Theme picker
            VStack(alignment: .leading, spacing: 12) {
                Label(localizer.t.settingsTheme, systemImage: settingsStore.theme == .dark ? "moon.fill" : "sun.max.fill")
                    .font(.body)

                HStack(spacing: 8) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Button {
                            HapticManager.light()
                            settingsStore.theme = mode
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: themeIcon(mode))
                                    .font(.caption)
                                Text(themeLabel(mode))
                                    .font(.subheadline)
                                    .fontWeight(settingsStore.theme == mode ? .semibold : .regular)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                settingsStore.theme == mode
                                    ? AppTheme.accent.opacity(0.1)
                                    : Color(.tertiarySystemFill)
                            )
                            .foregroundStyle(settingsStore.theme == mode ? AppTheme.accent : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        settingsStore.theme == mode ? AppTheme.accent.opacity(0.3) : .clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Services

    private var servicesSection: some View {
        Section(localizer.t.settingsServices) {
            ForEach(ServiceType.allCases) { type in
                serviceRow(type)
            }
        }
        .alert(localizer.t.settingsDisconnectConfirm, isPresented: .init(
            get: { showDisconnectAlert != nil },
            set: { if !$0 { showDisconnectAlert = nil } }
        )) {
            Button(localizer.t.cancel, role: .cancel) { }
            Button(localizer.t.settingsDisconnect, role: .destructive) {
                if let type = showDisconnectAlert {
                    HapticManager.medium()
                    servicesStore.disconnectService(type)
                }
            }
        } message: {
            Text(localizer.t.settingsDisconnectMessage)
        }
    }

    @ViewBuilder
    private func serviceRow(_ type: ServiceType) -> some View {
        let connected = servicesStore.isConnected(type)
        let conn = servicesStore.connection(for: type)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: type.symbolName)
                    .font(.body)
                    .foregroundStyle(type.colors.primary)
                    .frame(width: 36, height: 36)
                    .background(type.colors.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.body)

                    if let conn, connected {
                        Text(conn.url)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .lineLimit(1)
                    } else {
                        Text(localizer.t.settingsNotConnected)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                Spacer()

                if connected {
                    Button {
                        showDisconnectAlert = type
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Circle()
                        .fill(AppTheme.textMuted.opacity(0.2))
                        .frame(width: 10, height: 10)
                }
            }

            // Fallback URL input
            if connected, let conn {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)

                    TextField(localizer.t.settingsFallbackUrl, text: fallbackBinding(for: type, current: conn.fallbackUrl))
                        .font(.caption)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onSubmit { saveFallback(for: type) }
                }
                .padding(.leading, 48)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section(localizer.t.settingsAbout) {
            HStack {
                Label(localizer.t.settingsVersion, systemImage: "info.circle")
                Spacer()
                Text("2.0.0")
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func languageDisplayName(_ lang: Language) -> String {
        switch lang {
        case .it: return localizer.t.settingsItalian
        case .en: return localizer.t.settingsEnglish
        case .fr: return localizer.t.settingsFrench
        case .es: return localizer.t.settingsSpanish
        case .de: return localizer.t.settingsGerman
        }
    }

    private func themeIcon(_ mode: ThemeMode) -> String {
        switch mode {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    private func themeLabel(_ mode: ThemeMode) -> String {
        switch mode {
        case .dark: return localizer.t.settingsThemeDark
        case .light: return localizer.t.settingsThemeLight
        case .system: return "Auto"
        }
    }

    private func fallbackBinding(for type: ServiceType, current: String?) -> Binding<String> {
        Binding(
            get: { fallbackInputs[type] ?? current ?? "" },
            set: { fallbackInputs[type] = $0 }
        )
    }

    private func saveFallback(for type: ServiceType) {
        guard let value = fallbackInputs[type] else { return }
        Task { await servicesStore.updateFallbackURL(for: type, fallbackUrl: value.trimmingCharacters(in: .whitespaces)) }
        HapticManager.light()
    }
}
