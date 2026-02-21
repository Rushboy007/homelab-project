import SwiftUI

// Maps to app/(tabs)/(home)/DashboardSummary.tsx
// Shows summary cards for each connected service.

struct DashboardSummary: View {
    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer

    @State private var portainerData: PortainerSummaryData?
    @State private var piholeData: PiholeSummaryData?
    @State private var beszelData: BeszelSummaryData?
    @State private var giteaData: GiteaSummaryData?
    @State private var isLoading = false
    @State private var refreshID = UUID()

    private var hasAnyConnection: Bool {
        ServiceType.allCases.contains { servicesStore.isConnected($0) }
    }

    /// Simple hash representing which services are reachable
    private var reachabilityHash: String {
        ServiceType.allCases.map { type in
            let r = servicesStore.isReachable(type)
            return "\(type.rawValue):\(r.map { $0 ? "1" : "0" } ?? "?")"
        }.joined(separator: ",")
    }

    var body: some View {
        if hasAnyConnection {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizer.t.summaryTitle)
                    .font(.title3.bold())

                GlassGroup(spacing: 12) {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        if servicesStore.isConnected(.portainer) {
                            portainerCard
                        }
                        if servicesStore.isConnected(.pihole) {
                            piholeCard
                        }
                        if servicesStore.isConnected(.beszel) {
                            beszelCard
                        }
                        if servicesStore.isConnected(.gitea) {
                            giteaCard
                        }
                    }
                }
            }
            .padding(.top, 24)
            .task(id: refreshID) { await fetchSummaryData() }
            .onChange(of: reachabilityHash) { _, _ in
                // When reachability changes (service comes online/offline), re-fetch
                refreshID = UUID()
                // Clear data for unreachable services
                for type in ServiceType.allCases {
                    if servicesStore.isReachable(type) == false {
                        clearDataForService(type)
                    }
                }
            }
        }
    }

    // MARK: - Cards

    private var portainerCard: some View {
        SummaryCard(
            title: localizer.t.portainerContainers,
            value: portainerData.map { "\($0.running)" } ?? "—",
            subValue: portainerData.map { "/ \($0.total)" },
            icon: "shippingbox.fill",
            color: ServiceType.portainer.colors.primary,
            isLoading: portainerData == nil && isLoading,
            isUnreachable: servicesStore.isReachable(.portainer) == false
        )
    }

    private var piholeCard: some View {
        SummaryCard(
            title: localizer.t.summaryQueryTotal,
            value: piholeData.map { Formatters.formatNumber($0.totalQueries) } ?? "—",
            icon: "shield.fill",
            color: ServiceType.pihole.colors.primary,
            isLoading: piholeData == nil && isLoading,
            isUnreachable: servicesStore.isReachable(.pihole) == false
        )
    }

    private var beszelCard: some View {
        SummaryCard(
            title: localizer.t.summarySystemsOnline,
            value: beszelData.map { "\($0.online)" } ?? "—",
            subValue: beszelData.map { "/ \($0.total)" },
            icon: "server.rack",
            color: ServiceType.beszel.colors.primary,
            isLoading: beszelData == nil && isLoading,
            isUnreachable: servicesStore.isReachable(.beszel) == false
        )
    }

    private var giteaCard: some View {
        SummaryCard(
            title: localizer.t.giteaRepos,
            value: giteaData.map { "\($0.totalRepos)" } ?? "—",
            icon: "arrow.triangle.branch",
            color: ServiceType.gitea.colors.primary,
            isLoading: giteaData == nil && isLoading,
            isUnreachable: servicesStore.isReachable(.gitea) == false
        )
    }

    // MARK: - Data Fetching

    private func fetchSummaryData() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            if servicesStore.isConnected(.portainer) && servicesStore.isReachable(.portainer) != false {
                group.addTask { await fetchPortainer() }
            }
            if servicesStore.isConnected(.pihole) && servicesStore.isReachable(.pihole) != false {
                group.addTask { await fetchPihole() }
            }
            if servicesStore.isConnected(.beszel) && servicesStore.isReachable(.beszel) != false {
                group.addTask { await fetchBeszel() }
            }
            if servicesStore.isConnected(.gitea) && servicesStore.isReachable(.gitea) != false {
                group.addTask { await fetchGitea() }
            }
        }
    }

    private func clearDataForService(_ type: ServiceType) {
        switch type {
        case .portainer: portainerData = nil
        case .pihole: piholeData = nil
        case .beszel: beszelData = nil
        case .gitea: giteaData = nil
        }
    }

    @MainActor
    private func fetchPortainer() async {
        do {
            let endpoints = try await servicesStore.portainerClient.getEndpoints()
            guard let first = endpoints.first else { return }
            let containers = try await servicesStore.portainerClient.getContainers(endpointId: first.Id)
            let running = containers.filter { $0.State == "running" }.count
            portainerData = PortainerSummaryData(running: running, total: containers.count)
        } catch { /* silent */ }
    }

    @MainActor
    private func fetchPihole() async {
        do {
            let stats = try await servicesStore.piholeClient.getStats()
            piholeData = PiholeSummaryData(totalQueries: stats.queries.total)
        } catch { /* silent */ }
    }

    @MainActor
    private func fetchBeszel() async {
        do {
            let response = try await servicesStore.beszelClient.getSystems()
            let online = response.items.filter { $0.isOnline }.count
            beszelData = BeszelSummaryData(online: online, total: response.items.count)
        } catch { /* silent */ }
    }

    @MainActor
    private func fetchGitea() async {
        do {
            let repos = try await servicesStore.giteaClient.getUserRepos(page: 1, limit: 100)
            giteaData = GiteaSummaryData(totalRepos: repos.count)
        } catch { /* silent */ }
    }
}

// MARK: - Summary Data Models

private struct PortainerSummaryData {
    let running: Int
    let total: Int
}

private struct PiholeSummaryData {
    let totalQueries: Int
}

private struct BeszelSummaryData {
    let online: Int
    let total: Int
}

private struct GiteaSummaryData {
    let totalRepos: Int
}

// MARK: - SummaryCard

private struct SummaryCard: View {
    let title: String
    let value: String
    var subValue: String? = nil
    let icon: String
    let color: Color
    var isLoading: Bool = false
    var isUnreachable: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundStyle(isUnreachable ? AppTheme.textMuted : color)
                .frame(width: 36, height: 36)
                .background((isUnreachable ? AppTheme.textMuted : color).opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            if isLoading {
                SkeletonLoader(height: 24, cornerRadius: 6)
                    .frame(width: 60)
            } else if isUnreachable {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("—")
                        .font(.title2.bold())
                }
                .foregroundStyle(AppTheme.textMuted)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let subValue {
                        Text(subValue)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}
