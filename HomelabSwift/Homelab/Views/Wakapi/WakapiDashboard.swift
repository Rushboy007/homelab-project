import SwiftUI

struct WakapiDashboard: View {
    let instanceId: UUID

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInstanceId: UUID
    @State private var summary: WakapiSummary?
    @State private var state: LoadableState<Void> = .idle
    @State private var selectedInterval: WakapiInterval = .today
    @State private var activeFilter: WakapiSummaryFilter?

    private let wakapiColor = ServiceType.wakapi.colors.primary

    enum WakapiInterval: String, CaseIterable, Identifiable {
        case today = "today"
        case yesterday = "yesterday"
        case last7Days = "last_7_days"
        case last30Days = "last_30_days"
        case last6Months = "last_6_months"
        case lastYear = "last_year"
        case allTime = "all_time"

        var id: String { rawValue }

        func label(using t: Translations) -> String {
            switch self {
            case .today: return t.wakapiIntervalToday
            case .yesterday: return t.wakapiIntervalYesterday
            case .last7Days: return t.wakapiIntervalLast7Days
            case .last30Days: return t.wakapiIntervalLast30Days
            case .last6Months: return t.wakapiIntervalLast6Months
            case .lastYear: return t.wakapiIntervalLastYear
            case .allTime: return t.wakapiIntervalAllTime
            }
        }
    }

    init(instanceId: UUID) {
        self.instanceId = instanceId
        _selectedInstanceId = State(initialValue: instanceId)
    }

    var body: some View {
        ServiceDashboardLayout(
            serviceType: .wakapi,
            instanceId: selectedInstanceId,
            state: state,
            onRefresh: fetchSummary
        ) {
            instancePicker
            intervalPicker
            activeFilterBanner

            if let summary {
                overviewCard(summary)
                
                if let langs = summary.languages, !langs.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionLanguages,
                        icon: "curlybraces",
                        items: langs,
                        filterDimension: .language
                    )
                }
                
                if let projects = summary.projects, !projects.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionProjects,
                        icon: "folder.fill",
                        items: projects,
                        filterDimension: .project
                    )
                }

                if let editors = summary.editors, !editors.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionEditors,
                        icon: "keyboard.fill",
                        items: editors,
                        filterDimension: .editor
                    )
                }

                if let machines = summary.machines, !machines.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionMachines,
                        icon: "desktopcomputer",
                        items: machines,
                        filterDimension: .machine
                    )
                }
                
                if let oses = summary.operatingSystems, !oses.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionOperatingSystems,
                        icon: "laptopcomputer",
                        items: oses,
                        filterDimension: .operatingSystem
                    )
                }

                if let labels = summary.labels, !labels.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionLabels,
                        icon: "tag.fill",
                        items: labels,
                        filterDimension: .label
                    )
                }

                if let categories = summary.categories, !categories.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionCategories,
                        icon: "square.grid.2x2.fill",
                        items: categories
                    )
                }

                if let branches = summary.branches, !branches.isEmpty {
                    statListCard(
                        title: localizer.t.wakapiSectionBranches,
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        items: branches
                    )
                }
            }
        }
        .navigationTitle(localizer.t.serviceWakapi)
        .task(id: fetchTaskKey) {
            await fetchSummary()
        }
    }

    private var instancePicker: some View {
        let instances = servicesStore.instances(for: .wakapi)
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
                            selectedInstanceId = instance.id
                            servicesStore.setPreferredInstance(id: instance.id, for: .wakapi)
                            summary = nil
                            activeFilter = nil
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(instance.id == selectedInstanceId ? wakapiColor : AppTheme.textMuted.opacity(0.4))
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instance.displayLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Text(instance.url)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .glassCard(tint: instance.id == selectedInstanceId ? wakapiColor.opacity(0.1) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var intervalPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WakapiInterval.allCases) { interval in
                    Button {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedInterval = interval
                        }
                    } label: {
                        Text(interval.label(using: localizer.t))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedInterval == interval ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                if selectedInterval == interval {
                                    Capsule(style: .continuous)
                                        .fill(wakapiColor)
                                } else {
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.surface.opacity(0.75))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var activeFilterBanner: some View {
        if let activeFilter {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizer.t.wakapiActiveFilter)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                        .textCase(.uppercase)
                    Text(activeFilter.value)
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                Button(localizer.t.wakapiClearFilter) {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        self.activeFilter = nil
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surface.opacity(0.8), in: Capsule())
                .buttonStyle(.plain)
            }
            .padding(16)
            .glassCard(tint: wakapiColor.opacity(0.08))
        }
    }

    private func overviewCard(_ summary: WakapiSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(localizer.t.wakapiTotalTimeCoded)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(summary.grandTotal?.hours ?? 0)")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(wakapiColor)
                    Text(localizer.t.unitHours)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(summary.grandTotal?.minutes ?? 0)")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(wakapiColor)
                    Text(localizer.t.unitMinutes)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(wakapiColor.opacity(0.2))
        }
        .padding(20)
        .glassCard(tint: colorScheme == .dark ? wakapiColor.opacity(0.11) : wakapiColor.opacity(0.055))
    }

    private func statListCard(
        title: String,
        icon: String,
        items: [StatItem],
        filterDimension: WakapiSummaryFilter.Dimension? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(wakapiColor)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(items.prefix(5)) { item in
                    statRow(item: item, filterDimension: filterDimension)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    @ViewBuilder
    private func statRow(item: StatItem, filterDimension: WakapiSummaryFilter.Dimension?) -> some View {
        let row = statRowContent(item: item)

        if let filterDimension, let name = item.name, !name.isEmpty {
            Button {
                HapticManager.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    activeFilter = WakapiSummaryFilter(dimension: filterDimension, value: name)
                }
            } label: {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }

    private func statRowContent(item: StatItem) -> some View {
        let percent = item.percent ?? 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name ?? localizer.t.unknown)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Text(item.text ?? formatTime(hours: item.hours, minutes: item.minutes))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surface)
                    Capsule()
                        .fill(wakapiColor.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(percent / 100))
                }
            }
            .frame(height: 6)
        }
    }

    private func formatTime(hours: Int?, minutes: Int?) -> String {
        let h = hours ?? 0
        let m = minutes ?? 0
        if h > 0 {
            return "\(h)\(localizer.t.unitHours) \(m)\(localizer.t.unitMinutes)"
        } else {
            return "\(m)\(localizer.t.unitMinutes)"
        }
    }

    private var fetchTaskKey: String {
        "\(selectedInstanceId.uuidString)-\(selectedInterval.rawValue)-\(activeFilter?.cacheKey ?? "none")"
    }

    private func fetchSummary() async {
        do {
            if summary == nil {
                state = .loading
            }
            
            guard let client = await servicesStore.wakapiClient(instanceId: selectedInstanceId) else {
                state = .error(.notConfigured)
                return
            }

            let response = try await client.getSummary(
                interval: selectedInterval.rawValue,
                filter: activeFilter
            )
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                self.summary = response
                self.state = .loaded(())
            }
        } catch let apiError as APIError {
            if summary == nil {
                state = .error(apiError)
            } else {
                state = .loaded(())
            }
        } catch {
            if summary == nil {
                state = .error(.custom(error.localizedDescription))
            } else {
                state = .loaded(())
            }
        }
    }
}
