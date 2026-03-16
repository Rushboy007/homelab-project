import SwiftUI
import Charts

struct BeszelContainersView: View {
    let instanceId: UUID
    let systemId: String
    let records: [BeszelSystemRecord]

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer

    @State private var containerRecords: [BeszelContainerRecord] = []
    @State private var containerStats: [BeszelContainerStatsRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedContainer: BeszelContainerRecord?
    @State private var searchText = ""
    @State private var healthFilter: ContainerHealthFilter = .all
    @State private var selectedChartType: StackedChartType?
    @State private var cachedCpuPoints: [ContainerStackedPoint] = []
    @State private var cachedMemoryPoints: [ContainerStackedPoint] = []
    @State private var cachedNetworkPoints: [ContainerStackedPoint] = []
    @AppStorage("beszel_showCpuChart") private var showCpuChart = true
    @AppStorage("beszel_showMemoryChart") private var showMemoryChart = true
    @AppStorage("beszel_showNetworkChart") private var showNetworkChart = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showCpuChart && !containerCpuPoints.isEmpty {
                    Button { selectedChartType = .cpu } label: {
                        ContainerMetricChart(
                            title: localizer.t.beszelDockerCpuUsage,
                            points: containerCpuPoints,
                            formatY: { String(format: "%.0f%%", $0) }
                        )
                    }
                    .buttonStyle(.plain)
                }

                if showMemoryChart && !containerMemoryPoints.isEmpty {
                    Button { selectedChartType = .memory } label: {
                        ContainerMetricChart(
                            title: localizer.t.beszelDockerMemoryUsage,
                            points: containerMemoryPoints,
                            formatY: { BeszelFormatters.formatMB($0) }
                        )
                    }
                    .buttonStyle(.plain)
                }

                if showNetworkChart && hasNetworkData {
                    Button { selectedChartType = .network } label: {
                        ContainerMetricChart(
                            title: localizer.t.beszelDockerNetworkIO,
                            points: containerNetworkPoints,
                            formatY: { BeszelFormatters.formatBytesRate($0) }
                        )
                    }
                    .buttonStyle(.plain)
                }

                if filteredRecords.isEmpty {
                    Text(localizer.t.beszelNoContainers)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, container in
                            Button {
                                selectedContainer = container
                            } label: {
                                BeszelContainerRow(container: container, localizer: localizer)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < filteredRecords.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(AppTheme.padding)
        }
        .navigationTitle(localizer.t.beszelContainers)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: localizer.t.containersSearch)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(localizer.t.beszelContainerFilter, selection: $healthFilter) {
                        ForEach(ContainerHealthFilter.allCases, id: \.self) { option in
                            Text(option.title(localizer: localizer)).tag(option)
                        }
                    }

                    Divider()

                    Menu {
                        Toggle(isOn: Binding(
                            get: { showCpuChart },
                            set: { val in withAnimation(.easeInOut(duration: 0.25)) { showCpuChart = val } }
                        )) {
                            Label(localizer.t.beszelCpu, systemImage: "cpu")
                        }
                        Toggle(isOn: Binding(
                            get: { showMemoryChart },
                            set: { val in withAnimation(.easeInOut(duration: 0.25)) { showMemoryChart = val } }
                        )) {
                            Label(localizer.t.beszelMemory, systemImage: "memorychip")
                        }
                        Toggle(isOn: Binding(
                            get: { showNetworkChart },
                            set: { val in withAnimation(.easeInOut(duration: 0.25)) { showNetworkChart = val } }
                        )) {
                            Label(localizer.t.beszelNetwork, systemImage: "network")
                        }
                    } label: {
                        Label(localizer.t.beszelShowCharts, systemImage: "chart.xyaxis.line")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable { await fetchAll() }
        .task { await fetchAll() }
        .overlay {
            if isLoading {
                ProgressView().tint(AppTheme.info)
            } else if let errorMessage, containerRecords.isEmpty {
                ContentUnavailableView {
                    Label(localizer.t.error, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                }
            }
        }
        .sheet(item: $selectedContainer) { container in
            BeszelContainerDetailSheet(container: container, instanceId: instanceId, systemId: systemId, containerStats: containerStats)
        }
        .sheet(item: $selectedChartType) { chartType in
            StackedChartDetailSheet(
                title: chartType.title(localizer: localizer),
                points: chartType.points(cpu: containerCpuPoints, memory: containerMemoryPoints, network: containerNetworkPoints),
                formatValue: chartType.formatValue
            )
        }
    }

    private var sortedRecords: [BeszelContainerRecord] {
        containerRecords.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filteredRecords: [BeszelContainerRecord] {
        sortedRecords.filter { record in
            let matchesSearch = searchText.isEmpty ||
                record.name.localizedCaseInsensitiveContains(searchText) ||
                (record.image?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesSearch && healthFilter.matches(record)
        }
    }

    private var hasNetworkData: Bool {
        cachedNetworkPoints.contains { $0.yEnd > 0 }
    }

    private var containerCpuPoints: [ContainerStackedPoint] { cachedCpuPoints }
    private var containerMemoryPoints: [ContainerStackedPoint] { cachedMemoryPoints }
    private var containerNetworkPoints: [ContainerStackedPoint] { cachedNetworkPoints }

    private func rebuildChartCaches() {
        if !containerStats.isEmpty {
            cachedCpuPoints = buildStackedPoints(fromStats: containerStats) { $0.cpu }
            cachedMemoryPoints = buildStackedPoints(fromStats: containerStats) { $0.memory }
            cachedNetworkPoints = buildStackedPoints(fromStats: containerStats) { $0.netSent + $0.netReceived }
        } else {
            cachedCpuPoints = buildStackedPoints(fromRecords: records) { $0.cpuValue }
            cachedMemoryPoints = buildStackedPoints(fromRecords: records) { $0.mValue }
            cachedNetworkPoints = buildStackedPoints(fromRecords: records) { ($0.bandwidthUpBytesPerSec ?? 0) + ($0.bandwidthDownBytesPerSec ?? 0) }
        }
    }

    private func buildStackedPoints(fromStats stats: [BeszelContainerStatsRecord], value: (BeszelContainerStat) -> Double) -> [ContainerStackedPoint] {
        let sorted = stats.sorted { ($0.created ?? "") < ($1.created ?? "") }
        var names = Set<String>()
        var series: [(Date, [String: Double])] = []

        for record in sorted {
            guard let date = parseDate(record.created) else { continue }
            var values: [String: Double] = [:]
            for stat in record.stats {
                values[stat.name] = max(0, value(stat))
                names.insert(stat.name)
            }
            series.append((date, values))
        }

        return stack(series: series, names: names.sorted())
    }

    private func buildStackedPoints(fromRecords records: [BeszelSystemRecord], value: (BeszelContainer) -> Double) -> [ContainerStackedPoint] {
        let sorted = records.sorted { ($0.created ?? "") < ($1.created ?? "") }
        var names = Set<String>()
        var series: [(Date, [String: Double])] = []

        for record in sorted {
            guard let date = parseDate(record.created) else { continue }
            var values: [String: Double] = [:]
            for stat in record.stats.dc ?? [] {
                values[stat.name] = max(0, value(stat))
                names.insert(stat.name)
            }
            series.append((date, values))
        }

        return stack(series: series, names: names.sorted())
    }

    private func stack(series: [(Date, [String: Double])], names: [String]) -> [ContainerStackedPoint] {
        var lastKnown: [String: Double] = [:]
        var points: [ContainerStackedPoint] = []
        points.reserveCapacity(series.count * max(names.count, 1))

        for (date, values) in series {
            for (name, value) in values {
                lastKnown[name] = value
            }
            var running = 0.0
            for name in names {
                let value = lastKnown[name] ?? 0
                let start = running
                running += value
                points.append(ContainerStackedPoint(date: date, name: name, yStart: start, yEnd: running))
            }
        }

        return points
    }

    private static let pbDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let pbDateFormatterNoMillis: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        if let date = Self.pbDateFormatter.date(from: value) { return date }
        return Self.pbDateFormatterNoMillis.date(from: value)
    }

    private func fetchAll() async {
        isLoading = true
        errorMessage = nil
        guard let client = await servicesStore.beszelClient(instanceId: instanceId) else {
            errorMessage = localizer.t.launcherNotConfigured
            isLoading = false
            return
        }
        do {
            async let recordsTask = client.getContainers(systemId: systemId)
            async let statsTask = client.getContainerStats(systemId: systemId, limit: 240)
            let records = try await recordsTask
            let stats = try await statsTask
            await MainActor.run {
                containerRecords = records
                containerStats = stats
                rebuildChartCaches()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct ContainerStackedPoint: Identifiable {
    let date: Date
    let name: String
    let yStart: Double
    let yEnd: Double
    var id: String { "\(date.timeIntervalSince1970)-\(name)" }
}

private enum StackedChartType: String, Identifiable {
    case cpu, memory, network
    var id: String { rawValue }

    @MainActor func title(localizer: Localizer) -> String {
        switch self {
        case .cpu: return localizer.t.beszelDockerCpuUsage
        case .memory: return localizer.t.beszelDockerMemoryUsage
        case .network: return localizer.t.beszelDockerNetworkIO
        }
    }

    func points(cpu: [ContainerStackedPoint], memory: [ContainerStackedPoint], network: [ContainerStackedPoint]) -> [ContainerStackedPoint] {
        switch self {
        case .cpu: return cpu
        case .memory: return memory
        case .network: return network
        }
    }

    var formatValue: (Double) -> String {
        switch self {
        case .cpu: return { String(format: "%.1f%%", $0) }
        case .memory: return { BeszelFormatters.formatMB($0) }
        case .network: return { BeszelFormatters.formatBytesRate($0) }
        }
    }
}

private struct ContainerMetricChart: View {
    let title: String
    let points: [ContainerStackedPoint]
    let formatY: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }

            if points.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                stackedChart
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .glassCard()
    }

    private var stackedChart: some View {
        let names = Array(Set(points.map(\.name))).sorted()
        let gradients = generateGradients(for: names)
        let maxValue = max(points.map(\.yEnd).max() ?? 0, 1)
        return Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Start", point.yStart),
                yEnd: .value("End", point.yEnd)
            )
            .foregroundStyle(by: .value("Container", point.name))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(domain: names, range: gradients)
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(formatY(v)).font(.system(size: 9))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYScale(domain: 0...maxValue)
        .padding(.top, 4)
        .frame(height: 200)
    }
}

// MARK: - Stacked Chart Detail Sheet

private struct StackedChartDetailSheet: View {
    let title: String
    let points: [ContainerStackedPoint]
    let formatValue: (Double) -> String

    @Environment(Localizer.self) private var localizer
    @State private var snappedDate: Date?
    @State private var cachedDates: [Date]
    @State private var cachedNames: [String]
    @State private var cachedGradients: [LinearGradient]
    @State private var cachedMaxValue: Double
    @State private var dateIndex: [Date: [ContainerStackedPoint]]
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    init(title: String, points: [ContainerStackedPoint], formatValue: @escaping (Double) -> String) {
        self.title = title
        self.points = points
        self.formatValue = formatValue

        let dates = Array(Set(points.map(\.date))).sorted()
        let names = Array(Set(points.map(\.name))).sorted()
        var index: [Date: [ContainerStackedPoint]] = [:]
        for p in points { index[p.date, default: []].append(p) }

        _cachedDates = State(initialValue: dates)
        _cachedNames = State(initialValue: names)
        _cachedGradients = State(initialValue: generateGradients(for: names))
        _cachedMaxValue = State(initialValue: max(points.map(\.yEnd).max() ?? 0, 1))
        _dateIndex = State(initialValue: index)
    }

    private func valuesAt(_ date: Date?) -> [String: Double] {
        guard let date, let atDate = dateIndex[date] else { return [:] }
        var dict: [String: Double] = [:]
        for p in atDate { dict[p.name] = p.yEnd - p.yStart }
        return dict
    }

    private func nearestDate(to target: Date) -> Date? {
        guard !cachedDates.isEmpty else { return nil }
        var lo = 0, hi = cachedDates.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cachedDates[mid] < target { lo = mid + 1 } else { hi = mid }
        }
        if lo == 0 { return cachedDates[0] }
        let prev = cachedDates[lo - 1]
        let curr = cachedDates[lo]
        return abs(prev.timeIntervalSince(target)) <= abs(curr.timeIntervalSince(target)) ? prev : curr
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    chartSection
                    valuesSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .onAppear { hapticGenerator.prepare() }
    }

    private var chartSection: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Start", point.yStart),
                yEnd: .value("End", point.yEnd)
            )
            .foregroundStyle(by: .value("Container", point.name))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(domain: cachedNames, range: cachedGradients)
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(formatValue(v)).font(.system(size: 9))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYScale(domain: 0...cachedMaxValue)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    if let date = snappedDate, let xPos = proxy.position(forX: date) {
                        Path { path in
                            path.move(to: CGPoint(x: xPos, y: 0))
                            path.addLine(to: CGPoint(x: xPos, y: geometry.size.height))
                        }
                        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }

                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let date = proxy.value(atX: value.location.x, as: Date.self) {
                                        let nearest = nearestDate(to: date)
                                        if nearest != snappedDate {
                                            var transaction = Transaction()
                                            transaction.disablesAnimations = true
                                            withTransaction(transaction) {
                                                snappedDate = nearest
                                            }
                                            hapticGenerator.impactOccurred()
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    snappedDate = nil
                                }
                        )
                }
            }
        }
        .drawingGroup()
        .padding(.top, 4)
        .frame(height: 280)
        .glassCard()
    }

    private var valuesSection: some View {
        let displayDate = snappedDate ?? cachedDates.last
        let vals = valuesAt(displayDate)
        let total = vals.values.reduce(0, +)
        let sorted = cachedNames.sorted { (vals[$0] ?? 0) > (vals[$1] ?? 0) }
        return VStack(spacing: 0) {
            if let d = displayDate {
                HStack {
                    Text(d.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            HStack {
                Text(localizer.t.beszelTotal)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(formatValue(total))
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            ForEach(Array(sorted.enumerated()), id: \.element) { index, name in
                HStack(spacing: 8) {
                    Circle()
                        .fill(containerColor(for: name, in: cachedNames))
                        .frame(width: 10, height: 10)
                    Text(name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(formatValue(vals[name] ?? 0))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if index < sorted.count - 1 {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Shared Color Helpers

private func generateColors(count: Int) -> [Color] {
    guard count > 0 else { return [] }
    if count == 1 { return [Color(hue: 0.6, saturation: 0.8, brightness: 0.95)] }
    return (0..<count).map { i in
        let progress = Double(i) / Double(count - 1)
        return Color(hue: 0.8 * (1.0 - progress), saturation: 0.8, brightness: 0.95)
    }
}

private func generateGradients(for names: [String]) -> [LinearGradient] {
    let colors = generateColors(count: names.count)
    return colors.map { color in
        LinearGradient(colors: [color.opacity(0.6), color.opacity(0.6)], startPoint: .top, endPoint: .bottom)
    }
}

private func containerColor(for name: String, in names: [String]) -> Color {
    guard let index = names.firstIndex(of: name) else { return .gray }
    let colors = generateColors(count: names.count)
    return colors[index]
}

private struct BeszelContainerRow: View {
    let container: BeszelContainerRecord
    let localizer: Localizer

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.caption)
                .foregroundStyle(Color(hex: "#0EA5E9"))
                .frame(width: 28, height: 28)
                .background(Color(hex: "#0EA5E9").opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(container.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    metricLabel(systemImage: "cpu", value: String(format: "%.1f%%", container.cpuValue))
                    metricLabel(systemImage: "memorychip", value: BeszelFormatters.formatMB(container.memoryValue))
                    if container.netValue > 0 {
                        metricLabel(systemImage: "network", value: BeszelFormatters.formatBytesRate(container.netValue))
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

                if let image = container.image, !image.isEmpty {
                    Label(image, systemImage: "shippingbox")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let health = container.health, health != .none {
                    Text(healthLabel(health))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(healthColor(health).opacity(0.15), in: Capsule())
                        .foregroundStyle(healthColor(health))
                }
                if let status = container.status, !status.isEmpty {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
        }
    }

    private func metricLabel(systemImage: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10))
            Text(value)
        }
    }

    private func healthLabel(_ health: BeszelContainerHealth) -> String {
        switch health {
        case .none: return localizer.t.beszelHealthNone
        case .starting: return localizer.t.beszelHealthStarting
        case .healthy: return localizer.t.beszelHealthHealthy
        case .unhealthy: return localizer.t.beszelHealthUnhealthy
        }
    }

    private func healthColor(_ health: BeszelContainerHealth) -> Color {
        switch health {
        case .none: return AppTheme.textMuted
        case .starting: return AppTheme.warning
        case .healthy: return AppTheme.running
        case .unhealthy: return AppTheme.stopped
        }
    }
}

private enum ContainerHealthFilter: String, CaseIterable {
    case all
    case healthy
    case unhealthy
    case starting
    case none

    @MainActor func title(localizer: Localizer) -> String {
        switch self {
        case .all: return localizer.t.containersAll
        case .healthy: return localizer.t.beszelHealthHealthy
        case .unhealthy: return localizer.t.beszelHealthUnhealthy
        case .starting: return localizer.t.beszelHealthStarting
        case .none: return localizer.t.beszelHealthNone
        }
    }

    func matches(_ record: BeszelContainerRecord) -> Bool {
        guard self != .all else { return true }
        let health = record.health ?? .none
        switch self {
        case .healthy: return health == .healthy
        case .unhealthy: return health == .unhealthy
        case .starting: return health == .starting
        case .none: return health == .none
        case .all: return true
        }
    }
}
