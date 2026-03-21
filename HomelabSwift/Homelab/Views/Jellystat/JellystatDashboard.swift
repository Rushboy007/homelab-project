import SwiftUI

struct JellystatDashboard: View {
    let instanceId: UUID

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInstanceId: UUID
    @State private var selectedDays: Int = 30
    @State private var state: LoadableState<Void> = .idle
    @State private var summary: JellystatWatchSummary?
    @State private var animateCharts = false
    @State private var rangePulseToken = 0
    @State private var rangePulseActive = false
    @Namespace private var rangeNamespace

    private let jellyColor = ServiceType.jellystat.colors.primary
    private let watchTone = Color(hex: "#A855F7")
    private let viewsTone = Color(hex: "#EC4899")
    private let activeTone = Color(hex: "#22D3EE")
    private let topLibraryTone = Color(hex: "#8B5CF6")
    private let averageTone = Color(hex: "#F59E0B")
    private let smoothAnimation = Animation.spring(response: 0.44, dampingFraction: 0.86)

    private var sectionTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .bottom))
    }

    private var mutedGlassTint: Color {
        AppTheme.surface.opacity(colorScheme == .light ? 0.65 : 0.45)
    }

    init(instanceId: UUID) {
        self.instanceId = instanceId
        _selectedInstanceId = State(initialValue: instanceId)
    }

    var body: some View {
        ServiceDashboardLayout(
            serviceType: .jellystat,
            instanceId: selectedInstanceId,
            state: state,
            onRefresh: { await fetchDashboard(force: true) }
        ) {
            instancePicker
            heroCard

            if let summary {
                stagedSection(0) {
                    overviewUnifiedCard(summary)
                        .transition(sectionTransition)
                }
                stagedSection(1) {
                    mediaTypesCard(summary)
                        .transition(sectionTransition)
                }
                stagedSection(2) {
                    trendCard(summary)
                        .transition(sectionTransition)
                }
            } else {
                emptyState
            }
        }
        .animation(smoothAnimation, value: selectedDays)
        .animation(smoothAnimation, value: summary?.totalViews ?? 0)
        .animation(smoothAnimation, value: animateCharts)
        .sensoryFeedback(.selection, trigger: selectedDays)
        .sensoryFeedback(.success, trigger: summary?.totalViews ?? 0)
        .navigationTitle(localizer.t.serviceJellystat)
        .task(id: "\(selectedInstanceId.uuidString)-\(selectedDays)") {
            await fetchDashboard(force: true)
        }
    }

    private var instancePicker: some View {
        let instances = servicesStore.instances(for: .jellystat)
        return Group {
            if instances.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizer.t.dashboardInstances)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                        .textCase(.uppercase)

                    ForEach(instances) { instance in
                        Button {
                            HapticManager.light()
                            withAnimation(smoothAnimation) {
                                selectedInstanceId = instance.id
                                servicesStore.setPreferredInstance(id: instance.id, for: .jellystat)
                                summary = nil
                                state = .idle
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ServiceIconView(type: .jellystat, size: 22)
                                    .frame(width: 36, height: 36)
                                    .background(jellyColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instance.displayLabel)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(instance.url)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .glassCard(tint: instance.id == selectedInstanceId ? jellyColor.opacity(0.1) : mutedGlassTint)
                        }
                        .buttonStyle(PressableCardButtonStyle())
                    }
                }
            }
        }
    }

    private var heroCard: some View {
        GlassCard(tint: jellyColor.opacity(colorScheme == .light ? 0.16 : 0.12)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ServiceIconView(type: .jellystat, size: 34)
                        .frame(width: 56, height: 56)
                        .background(jellyColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizer.t.serviceJellystat)
                            .font(.headline.bold())
                            .lineLimit(1)
                        Text(localizer.t.jellystatOverviewSubtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text("\(selectedDays)d")
                        .font(.caption.bold())
                        .foregroundStyle(jellyColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(jellyColor.opacity(0.14), in: Capsule())
                        .scaleEffect(rangePulseActive ? 1.07 : 1.0)
                        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: rangePulseActive)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        metricPill(
                            title: localizer.t.jellystatWatchTime,
                            value: formatHours(summary?.totalHours ?? 0),
                            symbol: "clock.fill",
                            tint: watchTone
                        )

                        metricPill(
                            title: localizer.t.jellystatViews,
                            value: Formatters.formatNumber(summary?.totalViews ?? 0),
                            symbol: "play.circle.fill",
                            tint: viewsTone
                        )
                    }

                    VStack(spacing: 10) {
                        metricPill(
                            title: localizer.t.jellystatWatchTime,
                            value: formatHours(summary?.totalHours ?? 0),
                            symbol: "clock.fill",
                            tint: watchTone
                        )

                        metricPill(
                            title: localizer.t.jellystatViews,
                            value: Formatters.formatNumber(summary?.totalViews ?? 0),
                            symbol: "play.circle.fill",
                            tint: viewsTone
                        )
                    }
                }

                if let points = summary?.points, !points.isEmpty {
                    tinyTrendStrip(points: Array(points.suffix(12)))
                }
            }
            .padding(14)
        }
    }

    private func metricPill(title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(mutedGlassTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func tinyTrendStrip(points: [JellystatSeriesPoint]) -> some View {
        let maxHours = max(1.0, points.map { $0.totalDurationSeconds / 3600.0 }.max() ?? 1)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localizer.t.jellystatRecentTrend)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    let hours = point.totalDurationSeconds / 3600.0
                    let ratio = max(0.07, hours / maxHours)
                    let displayedRatio = animateCharts ? ratio : 0.06
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [jellyColor.opacity(colorScheme == .light ? 0.45 : 0.35), jellyColor],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 46 * displayedRatio)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.84)
                                .delay(Double(index) * 0.018),
                            value: animateCharts
                        )
                        .accessibilityLabel(shortDate(point.key))
                }
            }
            .frame(height: 52)
        }
    }

    private var rangeSelectorRow: some View {
        let ranges = [7, 30, 90]
        return HStack {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                ForEach(ranges, id: \.self) { days in
                    let isSelected = selectedDays == days
                    Button {
                        guard selectedDays != days else { return }
                        HapticManager.light()
                        selectedDays = days
                        triggerRangePulse()
                    } label: {
                        Text("\(days)d")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 70)
                            .padding(.vertical, 9)
                            .scaleEffect(isSelected && rangePulseActive ? 1.08 : 1.0)
                            .shadow(
                                color: isSelected ? jellyColor.opacity(rangePulseActive ? 0.36 : 0.12) : .clear,
                                radius: isSelected ? (rangePulseActive ? 14 : 7) : 0,
                                y: isSelected ? 4 : 0
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.62), value: rangePulseActive)
                            .background {
                                if isSelected {
                                    Capsule(style: .continuous)
                                        .fill(jellyColor)
                                        .matchedGeometryEffect(id: "jellystat-range", in: rangeNamespace)
                                } else {
                                    Capsule(style: .continuous)
                                        .fill(mutedGlassTint)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func overviewUnifiedCard(_ summary: JellystatWatchSummary) -> some View {
        let averageHours = summary.days > 0 ? summary.totalHours / Double(summary.days) : 0

        return GlassCard(tint: mutedGlassTint) {
            VStack(alignment: .leading, spacing: 14) {
                rangeSelectorRow
                    .padding(10)
                    .background(mutedGlassTint.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Rectangle()
                    .fill(AppTheme.textMuted.opacity(0.18))
                    .frame(height: 1)

                LazyVGrid(columns: twoColumnGrid, spacing: 10) {
                    UnifiedMetricTile(
                        title: localizer.t.jellystatTopLibrary,
                        value: summary.topLibraryName ?? localizer.t.jellystatNoActivity,
                        icon: "building.columns.fill",
                        iconColor: topLibraryTone,
                        subtitle: summary.topLibraryName == nil ? localizer.t.jellystatNoActivity : formatHours(summary.topLibraryHours)
                    )

                    UnifiedMetricTile(
                        title: localizer.t.jellystatActiveDays,
                        value: "\(summary.activeDays)",
                        icon: "calendar.badge.clock",
                        iconColor: activeTone,
                        subtitle: String(format: localizer.t.jellystatWindowDaysFormat, summary.days)
                    )

                    UnifiedMetricTile(
                        title: localizer.t.jellystatViews,
                        value: Formatters.formatNumber(summary.totalViews),
                        icon: "play.circle.fill",
                        iconColor: viewsTone,
                        subtitle: localizer.t.jellystatDaysWithPlayback
                    )

                    UnifiedMetricTile(
                        title: localizer.t.jellystatAvgPerDay,
                        value: formatHours(averageHours),
                        icon: "clock.arrow.circlepath",
                        iconColor: averageTone,
                        subtitle: localizer.t.jellystatAverageWatchTime
                    )
                }
            }
            .padding(14)
        }
    }

    private func insightRibbon(_ summary: JellystatWatchSummary) -> some View {
        let topLibraryChip = InsightChip(
            title: localizer.t.jellystatTopLibrary,
            value: summary.topLibraryName ?? localizer.t.jellystatNoActivity,
            subtitle: summary.topLibraryName == nil ? nil : formatHours(summary.topLibraryHours),
            icon: "sparkles.tv",
            tint: topLibraryTone
        )

        let activeDaysChip = InsightChip(
            title: localizer.t.jellystatActiveDays,
            value: "\(summary.activeDays)",
            subtitle: String(format: localizer.t.jellystatWindowDaysFormat, summary.days),
            icon: "calendar.badge.clock",
            tint: activeTone
        )

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                topLibraryChip
                activeDaysChip
            }

            VStack(spacing: 10) {
                topLibraryChip
                activeDaysChip
            }
        }
    }

    private func statsGrid(_ summary: JellystatWatchSummary) -> some View {
        let averageHours = summary.days > 0 ? summary.totalHours / Double(summary.days) : 0

        return LazyVGrid(columns: twoColumnGrid, spacing: 10) {
            JellystatMetricCard(
                title: localizer.t.jellystatViews,
                value: Formatters.formatNumber(summary.totalViews),
                icon: "play.circle.fill",
                iconColor: viewsTone,
                subtitle: String(format: localizer.t.jellystatWindowDaysFormat, summary.days)
            )

            JellystatMetricCard(
                title: localizer.t.jellystatActiveDays,
                value: "\(summary.activeDays)",
                icon: "calendar",
                iconColor: activeTone,
                subtitle: localizer.t.jellystatDaysWithPlayback
            )

            JellystatMetricCard(
                title: localizer.t.jellystatTopLibrary,
                value: summary.topLibraryName ?? localizer.t.jellystatNoActivity,
                icon: "building.columns.fill",
                iconColor: topLibraryTone,
                subtitle: summary.topLibraryName == nil ? localizer.t.jellystatNoActivity : formatHours(summary.topLibraryHours)
            )

            JellystatMetricCard(
                title: localizer.t.jellystatAvgPerDay,
                value: formatHours(averageHours),
                icon: "clock.arrow.circlepath",
                iconColor: averageTone,
                subtitle: localizer.t.jellystatAverageWatchTime
            )
        }
    }

    private func mediaTypesCard(_ summary: JellystatWatchSummary) -> some View {
        let items: [MediaTypeMetric] = [
            MediaTypeMetric(title: localizer.t.jellystatSongs, value: summary.viewsByType.audio, symbol: "music.note", color: Color(hex: "#FB7185")),
            MediaTypeMetric(title: localizer.t.jellystatMovies, value: summary.viewsByType.movie, symbol: "film.fill", color: Color(hex: "#F59E0B")),
            MediaTypeMetric(title: localizer.t.jellystatEpisodes, value: summary.viewsByType.series, symbol: "tv.fill", color: Color(hex: "#3B82F6")),
            MediaTypeMetric(title: localizer.t.jellystatOther, value: summary.viewsByType.other, symbol: "square.stack.3d.down.forward", color: Color(hex: "#A78BFA"))
        ]

        let total = max(summary.viewsByType.totalViews, 1)
        let segments = ringSegments(items: items, total: total)

        return GlassCard(tint: mutedGlassTint) {
            VStack(alignment: .leading, spacing: 14) {
                Text(localizer.t.jellystatMediaTypeBreakdown)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 14) {
                        VStack(spacing: 10) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                mediaRow(item: item, total: total, index: index)
                            }
                        }

                        Spacer(minLength: 4)

                        ringChart(segments: segments, total: summary.viewsByType.totalViews)
                    }

                    VStack(spacing: 14) {
                        ringChart(segments: segments, total: summary.viewsByType.totalViews)
                        VStack(spacing: 10) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                mediaRow(item: item, total: total, index: index)
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private func mediaRow(item: MediaTypeMetric, total: Int, index: Int) -> some View {
        let ratio = Double(item.value) / Double(max(total, 1))
        let displayedRatio = animateCharts ? ratio : 0.0

        return VStack(spacing: 6) {
            HStack {
                Label(item.title, systemImage: item.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(Formatters.formatNumber(item.value))
                    .font(.caption.bold())
                    .foregroundStyle(item.color)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(mutedGlassTint)
                    Capsule(style: .continuous)
                        .fill(item.color.gradient)
                        .frame(width: geo.size.width * CGFloat(displayedRatio))
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.86)
                                .delay(Double(index) * 0.05),
                            value: animateCharts
                        )
                }
            }
            .frame(height: 8)
        }
        .opacity(animateCharts ? 1.0 : 0.0)
        .offset(y: animateCharts ? 0 : 8)
        .animation(
            .spring(response: 0.58, dampingFraction: 0.84)
                .delay(Double(index) * 0.045),
            value: animateCharts
        )
    }

    private func ringChart(segments: [RingSegment], total: Int) -> some View {
        ZStack {
            Circle()
                .stroke(mutedGlassTint, style: StrokeStyle(lineWidth: 13, lineCap: .round))

            ForEach(segments) { segment in
                let animatedEnd = animateCharts ? segment.end : segment.start + 0.0001
                Circle()
                    .trim(from: CGFloat(segment.start), to: CGFloat(animatedEnd))
                    .stroke(
                        segment.color.gradient,
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.62, dampingFraction: 0.86), value: animateCharts)
            }

            VStack(spacing: 2) {
                Text(Formatters.formatNumber(total))
                    .font(.headline.bold())
                    .contentTransition(.numericText())
                    .lineLimit(1)
                Text(localizer.t.jellystatViews)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                    .frame(width: 74)
            }
        }
        .frame(width: 114, height: 114)
        .padding(6)
        .background(mutedGlassTint.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func trendCard(_ summary: JellystatWatchSummary) -> some View {
        let recent = Array(summary.points.suffix(8))
        let maxHours = max(1.0, recent.map { $0.totalDurationSeconds / 3600.0 }.max() ?? 1)

        return GlassCard(tint: mutedGlassTint) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizer.t.jellystatRecentTrend)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("\(recent.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(jellyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(jellyColor.opacity(0.14), in: Capsule())
                }

                if recent.isEmpty {
                    Text(localizer.t.jellystatNoDataForPeriod)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, point in
                        trendRow(point: point, maxHours: maxHours, index: index)
                    }
                }
            }
            .padding(14)
        }
    }

    private func trendRow(point: JellystatSeriesPoint, maxHours: Double, index: Int) -> some View {
        let hours = point.totalDurationSeconds / 3600.0
        let ratio = max(0.03, hours / maxHours)
        let displayedRatio = animateCharts ? ratio : 0.02

        return HStack(spacing: 10) {
            Text(shortDate(point.key))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 56, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(mutedGlassTint)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [jellyColor.opacity(0.5), jellyColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(displayedRatio))
                        .animation(
                            .spring(response: 0.62, dampingFraction: 0.86)
                                .delay(Double(index) * 0.035),
                            value: animateCharts
                        )
                }
            }
            .frame(height: 9)

            VStack(alignment: .trailing, spacing: 1) {
                Text(formatHours(hours))
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .lineLimit(1)

                Text(String(format: localizer.t.jellystatViewsSuffix, point.totalViews))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 88, alignment: .trailing)
        }
        .opacity(animateCharts ? 1.0 : 0.0)
        .offset(y: animateCharts ? 0 : 10)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.86)
                .delay(Double(index) * 0.03),
            value: animateCharts
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textMuted)
            Text(localizer.t.jellystatNoData)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func ringSegments(items: [MediaTypeMetric], total: Int) -> [RingSegment] {
        guard total > 0 else { return [] }

        var cursor = 0.0
        return items.compactMap { item in
            guard item.value > 0 else { return nil }
            let fraction = Double(item.value) / Double(total)
            defer { cursor += fraction }
            return RingSegment(
                title: item.title,
                value: item.value,
                color: item.color,
                start: cursor,
                end: min(cursor + fraction, 1.0)
            )
        }
    }

    private func fetchDashboard(force: Bool) async {
        if state.isLoading { return }
        if case .loaded = state, !force { return }

        animateCharts = false
        state = .loading
        do {
            guard let client = await servicesStore.jellystatClient(instanceId: selectedInstanceId) else {
                state = .error(.notConfigured)
                return
            }
            let loaded = try await client.getWatchSummary(days: selectedDays)
            withAnimation(smoothAnimation) {
                summary = loaded
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) {
                animateCharts = true
            }
            state = .loaded(())
        } catch let apiError as APIError {
            state = .error(apiError)
        } catch {
            state = .error(.custom(error.localizedDescription))
        }
    }

    private func stagedSection<Content: View>(_ index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(animateCharts ? 1.0 : 0.0)
            .offset(y: animateCharts ? 0 : 18)
            .scaleEffect(animateCharts ? 1.0 : 0.985, anchor: .top)
            .animation(
                .spring(response: 0.62, dampingFraction: 0.86)
                    .delay(Double(index) * 0.08),
                value: animateCharts
            )
    }

    private func triggerRangePulse() {
        rangePulseToken += 1
        let token = rangePulseToken
        rangePulseActive = true
        Task {
            try? await Task.sleep(nanoseconds: 240_000_000)
            if token == rangePulseToken {
                rangePulseActive = false
            }
        }
    }

    private func formatHours(_ value: Double) -> String {
        if value > 0, value < 1 {
            let minutes = Int((value * 60).rounded(.down))
            if minutes <= 0 {
                return "<1m"
            }
            return "\(minutes)m"
        }
        if value >= 100 {
            return String(format: "%.0fh", value)
        }
        return String(format: "%.1fh", value)
    }

    private func shortDate(_ key: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")

        let formats = ["MMM d, yyyy", "MMM dd, yyyy", "yyyy-MM-dd", "yyyy/MM/dd"]
        for format in formats {
            parser.dateFormat = format
            if let date = parser.date(from: key) {
                let output = DateFormatter()
                output.locale = .current
                output.setLocalizedDateFormatFromTemplate("MMM d")
                return output.string(from: date)
            }
        }
        return key
    }
}

private struct JellystatMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let subtitle: String

    var body: some View {
        GlassCard(tint: AppTheme.surface.opacity(0.45)) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(iconColor)
                        .frame(width: 22, height: 22)
                        .background(iconColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 122, alignment: .topLeading)
            .padding(10)
        }
    }
}

private struct UnifiedMetricTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 112, alignment: .topLeading)
        .padding(10)
        .background(mutedTile, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderTone, lineWidth: 1)
        )
    }

    private var mutedTile: Color {
        AppTheme.surface.opacity(tileOpacity)
    }

    private var tileOpacity: Double {
        colorScheme == .light ? 0.72 : 0.58
    }

    private var borderTone: Color {
        AppTheme.textMuted.opacity(colorScheme == .light ? 0.22 : 0.18)
    }
}

private struct InsightChip: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 92)
        .glassCard(tint: AppTheme.surface.opacity(0.5))
    }
}

private struct MediaTypeMetric: Identifiable {
    let title: String
    let value: Int
    let symbol: String
    let color: Color

    var id: String { title }
}

private struct RingSegment: Identifiable {
    let title: String
    let value: Int
    let color: Color
    let start: Double
    let end: Double

    var id: String { title }
}
