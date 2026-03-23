import SwiftUI

struct PlexDashboard: View {
    let instanceId: UUID

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInstanceId: UUID
    @State private var state: LoadableState<Void> = .idle
    @State private var dashboard: PlexDashboardData?
    @State private var animateCharts = false

    private let plexColor     = ServiceType.plex.colors.primary
    private let sessionTone   = Color(hex: "#22D3EE")
    private let movieTone     = Color(hex: "#F59E0B")
    private let showTone      = Color(hex: "#3B82F6")
    private let episodeTone   = Color(hex: "#60A5FA")
    private let musicTone     = Color(hex: "#EC4899")
    private let recentTone    = Color(hex: "#A855F7")
    private let historyTone   = Color(hex: "#10B981")
    private let smoothAnim    = Animation.spring(response: 0.44, dampingFraction: 0.86)

    private var glass: Color {
        AppTheme.surface.opacity(colorScheme == .light ? 0.65 : 0.45)
    }

    init(instanceId: UUID) {
        self.instanceId = instanceId
        _selectedInstanceId = State(initialValue: instanceId)
    }

    var body: some View {
        ServiceDashboardLayout(
            serviceType: .plex,
            instanceId: selectedInstanceId,
            state: state,
            onRefresh: { await fetchDashboard(force: true) }
        ) {
            instancePicker
            heroCard

            if let dashboard {
                stagedSection(0) { statsGrid(dashboard.stats).transition(.opacity.combined(with: .move(edge: .bottom))) }
                stagedSection(1) { librariesCard(dashboard.libraries).transition(.opacity.combined(with: .move(edge: .bottom))) }
                if !dashboard.activeSessions.isEmpty {
                    stagedSection(2) { sessionsCard(dashboard.activeSessions).transition(.opacity.combined(with: .move(edge: .bottom))) }
                }
                stagedSection(3) { recentlyAddedCard(dashboard.recentlyAdded).transition(.opacity.combined(with: .move(edge: .bottom))) }
                if !dashboard.watchHistory.isEmpty {
                    stagedSection(4) { historyCard(dashboard.watchHistory).transition(.opacity.combined(with: .move(edge: .bottom))) }
                }
            } else {
                emptyState
            }
        }
        .animation(smoothAnim, value: dashboard?.stats.totalItems ?? 0)
        .animation(smoothAnim, value: animateCharts)
        .sensoryFeedback(.success, trigger: dashboard?.stats.totalItems ?? 0)
        .navigationTitle(localizer.t.servicePlex)
        .task(id: selectedInstanceId.uuidString) { await fetchDashboard(force: true) }
    }

    // MARK: - Instance Picker

    private var instancePicker: some View {
        let instances = servicesStore.instances(for: .plex)
        return Group {
            if instances.count > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizer.t.dashboardInstances)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                        .textCase(.uppercase)
                    ForEach(instances) { instance in
                        Button {
                            HapticManager.light()
                            withAnimation(smoothAnim) {
                                selectedInstanceId = instance.id
                                servicesStore.setPreferredInstance(id: instance.id, for: .plex)
                                dashboard = nil
                                state = .idle
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ServiceIconView(type: .plex, size: 22)
                                    .frame(width: 36, height: 36)
                                    .background(plexColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instance.displayLabel).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text(instance.url).font(.caption).foregroundStyle(AppTheme.textMuted).lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .glassCard(tint: instance.id == selectedInstanceId ? plexColor.opacity(0.1) : glass)
                        }
                        .buttonStyle(PressableCardButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        GlassCard(tint: plexColor.opacity(colorScheme == .light ? 0.18 : 0.13)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ServiceIconView(type: .plex, size: 36)
                        .frame(width: 58, height: 58)
                        .background(plexColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizer.t.servicePlex)
                            .font(.headline.bold())
                        Text(localizer.t.plexOverviewSubtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .lineLimit(2)
                    }
                    Spacer()
                    if let s = dashboard, !s.activeSessions.isEmpty {
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 7, height: 7)
                                Text("\(s.activeSessions.count)").font(.caption.bold()).foregroundStyle(sessionTone)
                            }
                            Text(localizer.t.plexActiveSessions)
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(sessionTone.opacity(0.13), in: Capsule())
                    }
                }

                // Server ribbon
                if let server = dashboard?.serverInfo {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "server.rack").font(.caption2).foregroundStyle(AppTheme.textMuted)
                            Text(server.name).font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.textSecondary).lineLimit(1)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text(server.platform).font(.caption2).foregroundStyle(AppTheme.textMuted)
                            Text("·").font(.caption2).foregroundStyle(AppTheme.textMuted)
                            Text("v\(server.version)").font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(glass, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: - Stats Grid (movies / shows / episodes / music)

    private func statsGrid(_ stats: PlexStats) -> some View {
        GlassCard(tint: glass) {
            VStack(alignment: .leading, spacing: 12) {
                Text(localizer.t.plexTotalItems + " · \(Formatters.formatNumber(stats.totalItems))")
                    .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(
                        icon: "film.fill",
                        tint: movieTone,
                        value: Formatters.formatNumber(stats.totalMovies),
                        label: localizer.t.plexMovies
                    )
                    statTile(
                        icon: "tv.fill",
                        tint: showTone,
                        value: Formatters.formatNumber(stats.totalShows),
                        label: localizer.t.plexShows
                    )
                    statTile(
                        icon: "rectangle.stack.fill",
                        tint: episodeTone,
                        value: Formatters.formatNumber(stats.totalEpisodes),
                        label: localizer.t.plexEpisodes
                    )
                    statTile(
                        icon: "music.note",
                        tint: musicTone,
                        value: Formatters.formatNumber(stats.totalMusic),
                        label: localizer.t.plexMusic
                    )
                }
            }
        }
    }

    private func statTile(icon: String, tint: Color, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout.bold())
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(glass.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(animateCharts ? 1 : 0)
        .offset(y: animateCharts ? 0 : 10)
    }

    // MARK: - Libraries Card

    private func librariesCard(_ libs: [PlexLibrary]) -> some View {
        let total = max(libs.reduce(0) { $0 + $1.itemCount }, 1)

        return GlassCard(tint: glass) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(localizer.t.plexLibraries, systemImage: "square.stack.fill")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    badge(text: "\(libs.count)", tint: plexColor)
                }
                ForEach(Array(libs.enumerated()), id: \.element.id) { idx, lib in
                    libraryRow(lib: lib, total: total, index: idx)
                }
            }
        }
    }

    private func libraryRow(lib: PlexLibrary, total: Int, index: Int) -> some View {
        let ratio = Double(lib.itemCount) / Double(total)
        let displayRatio = animateCharts ? max(0.02, ratio) : 0.0
        let tint = colorFor(libType: lib.type)

        return VStack(spacing: 5) {
            HStack {
                Label(lib.title, systemImage: lib.sfSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(Formatters.formatNumber(lib.itemCount))
                        .font(.caption.bold()).foregroundStyle(tint).lineLimit(1)
                    if lib.type == "show" && lib.episodeCount > 0 {
                        Text("\(Formatters.formatNumber(lib.episodeCount)) ep.")
                            .font(.system(size: 9)).foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(glass)
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: geo.size.width * CGFloat(displayRatio))
                        .animation(.spring(response: 0.6, dampingFraction: 0.86).delay(Double(index) * 0.05), value: animateCharts)
                }
            }
            .frame(height: 8)
        }
        .opacity(animateCharts ? 1 : 0)
        .offset(y: animateCharts ? 0 : 8)
        .animation(.spring(response: 0.58, dampingFraction: 0.84).delay(Double(index) * 0.045), value: animateCharts)
    }

    // MARK: - Sessions Card

    private func sessionsCard(_ sessions: [PlexSession]) -> some View {
        GlassCard(tint: sessionTone.opacity(colorScheme == .light ? 0.08 : 0.06)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(localizer.t.plexActiveSessions, systemImage: "play.circle.fill")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text("\(sessions.count)").font(.caption2.bold()).foregroundStyle(sessionTone)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(sessionTone.opacity(0.14), in: Capsule())
                }
                ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                    sessionRow(session: session, index: idx)
                }
            }
        }
    }

    private func sessionRow(session: PlexSession, index: Int) -> some View {
        let isPlaying = session.playerState == "playing"
        let stateColor: Color = isPlaying ? .green : .orange

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "play.fill" : "pause.fill")
                    .font(.caption.bold())
                    .foregroundStyle(stateColor)
                    .frame(width: 28, height: 28)
                    .background(stateColor.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayTitle).font(.caption.weight(.semibold)).lineLimit(1)
                    if !session.displaySubtitle.isEmpty {
                        Text(session.displaySubtitle).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(1)
                    }
                }
                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.username).font(.caption2.weight(.semibold)).foregroundStyle(plexColor).lineLimit(1)
                    HStack(spacing: 3) {
                        Image(systemName: session.isLocal ? "house.fill" : "globe").font(.system(size: 8))
                        Text(session.playerPlatform.capitalized).font(.system(size: 9))
                    }
                    .foregroundStyle(AppTheme.textMuted)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(glass)
                    Capsule()
                        .fill(LinearGradient(colors: [plexColor.opacity(0.55), plexColor], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(session.progressRatio))
                }
            }
            .frame(height: 5)

            // Tags row: resolution, transcode, bandwidth
            HStack(spacing: 6) {
                if !session.resolutionLabel.isEmpty {
                    sessionTag(text: session.resolutionLabel, tint: episodeTone)
                }
                if session.isTranscoding {
                    sessionTag(text: "⟲ Transcode", tint: .orange)
                } else {
                    sessionTag(text: "▶ Direct", tint: historyTone)
                }
                if session.bandwidth > 0 {
                    sessionTag(text: String(format: "%.1f Mbps", session.bandwidthMbps), tint: plexColor)
                }
            }
        }
        .padding(10)
        .background(glass.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(animateCharts ? 1 : 0)
        .offset(y: animateCharts ? 0 : 10)
        .animation(.spring(response: 0.6, dampingFraction: 0.86).delay(Double(index) * 0.04), value: animateCharts)
    }

    private func sessionTag(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tint.opacity(0.13), in: Capsule())
    }

    // MARK: - Recently Added Card

    private func recentlyAddedCard(_ items: [PlexRecentItem]) -> some View {
        GlassCard(tint: glass) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(localizer.t.plexRecentlyAdded, systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    badge(text: "\(items.count)", tint: recentTone)
                }
                if items.isEmpty {
                    Text(localizer.t.plexNoRecentItems).font(.caption).foregroundStyle(AppTheme.textMuted)
                } else {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { idx, item in
                        recentRow(item: item, index: idx)
                    }
                }
            }
        }
    }

    private func recentRow(item: PlexRecentItem, index: Int) -> some View {
        let tint = colorFor(mediaType: item.type)
        return HStack(spacing: 10) {
            Image(systemName: item.sfSymbol)
                .font(.caption.bold()).foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle).font(.caption.weight(.semibold)).lineLimit(1)
                if let year = item.year { Text("\(year)").font(.caption2).foregroundStyle(AppTheme.textMuted) }
            }
            Spacer(minLength: 4)
            Text(relativeDate(item.addedAt)).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(1)
        }
        .opacity(animateCharts ? 1 : 0)
        .offset(y: animateCharts ? 0 : 8)
        .animation(.spring(response: 0.58, dampingFraction: 0.84).delay(Double(index) * 0.03), value: animateCharts)
    }

    // MARK: - History Card

    private func historyCard(_ items: [PlexHistoryItem]) -> some View {
        GlassCard(tint: glass) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(localizer.t.plexWatchHistory, systemImage: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    badge(text: "\(items.count)", tint: historyTone)
                }
                ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { idx, item in
                    historyRow(item: item, index: idx)
                }
            }
        }
    }

    private func historyRow(item: PlexHistoryItem, index: Int) -> some View {
        let tint = colorFor(mediaType: item.type)
        return HStack(spacing: 10) {
            Circle().fill(tint).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle).font(.caption.weight(.semibold)).lineLimit(1)
                if item.displayTitle != item.title {
                    Text(item.title).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            Text(relativeDate(item.viewedAt)).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(1)
        }
        .opacity(animateCharts ? 1 : 0)
        .offset(y: animateCharts ? 0 : 8)
        .animation(.spring(response: 0.58, dampingFraction: 0.84).delay(Double(index) * 0.03), value: animateCharts)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.tv")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textMuted)
            Text(localizer.t.plexNoData)
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    // MARK: - Staged animation

    private func stagedSection<C: View>(_ index: Int, @ViewBuilder content: () -> C) -> some View {
        content()
            .opacity(animateCharts ? 1 : 0)
            .offset(y: animateCharts ? 0 : 18)
            .scaleEffect(animateCharts ? 1 : 0.985, anchor: .top)
            .animation(.spring(response: 0.62, dampingFraction: 0.86).delay(Double(index) * 0.08), value: animateCharts)
    }

    // MARK: - Badge helper

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
    }

    // MARK: - Fetch

    private func fetchDashboard(force: Bool) async {
        if state.isLoading { return }
        if case .loaded = state, !force { return }
        animateCharts = false
        state = .loading
        do {
            guard let client = await servicesStore.plexClient(instanceId: selectedInstanceId) else {
                state = .error(.notConfigured)
                return
            }
            let loaded = try await client.getDashboard()
            withAnimation(smoothAnim) { dashboard = loaded }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { animateCharts = true }
            state = .loaded(())
        } catch let apiError as APIError {
            state = .error(apiError)
        } catch {
            state = .error(.custom(error.localizedDescription))
        }
    }

    // MARK: - Helpers

    private func colorFor(libType: String) -> Color {
        switch libType {
        case "movie":  return movieTone
        case "show":   return showTone
        case "artist": return musicTone
        default:       return recentTone
        }
    }

    private func colorFor(mediaType: String) -> Color {
        switch mediaType {
        case "movie":           return movieTone
        case "episode", "show": return showTone
        case "track", "album":  return musicTone
        default:                return recentTone
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let i = Date().timeIntervalSince(date)
        if i < 3600    { return localizer.t.timeNow }
        if i < 86400   { return String(format: localizer.t.timeHoursAgo, Int(i / 3600)) }
        if i < 172800  { return localizer.t.timeDayAgo }
        return String(format: localizer.t.timeDaysAgo, Int(i / 86400))
    }
}
