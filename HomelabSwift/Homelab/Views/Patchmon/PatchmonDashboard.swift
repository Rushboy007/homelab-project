import SwiftUI

struct PatchmonDashboard: View {
    let instanceId: UUID

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInstanceId: UUID
    @State private var hosts: [PatchmonHost] = []
    @State private var hostGroups: [String] = []
    @State private var selectedGroup: String? = nil
    @State private var state: LoadableState<Void> = .idle
    @State private var animateCriticalPulse = false
    @Namespace private var groupChipNamespace

    private let patchmonColor = ServiceType.patchmon.colors.primary
    private var summaryTint: Color {
        colorScheme == .dark ? patchmonColor.opacity(0.11) : patchmonColor.opacity(0.055)
    }
    private var hostCardTint: Color {
        colorScheme == .dark ? AppTheme.surface.opacity(0.26) : AppTheme.surface.opacity(0.12)
    }

    init(instanceId: UUID) {
        self.instanceId = instanceId
        _selectedInstanceId = State(initialValue: instanceId)
    }

    var body: some View {
        ServiceDashboardLayout(
            serviceType: .patchmon,
            instanceId: selectedInstanceId,
            state: state,
            onRefresh: fetchHosts
        ) {
            instancePicker
            overviewCard
            hostGroupFilter

            if hosts.isEmpty && !state.isLoading {
                emptyState
            } else {
                ForEach(Array(hosts.enumerated()), id: \.element.id) { index, host in
                    hostCard(host)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.98)), removal: .opacity))
                        .animation(.spring(response: 0.42, dampingFraction: 0.86).delay(Double(index) * 0.02), value: hosts)
                }
            }
        }
        .navigationTitle(localizer.t.servicePatchmon)
        .task(id: selectedInstanceId) {
            await fetchHosts(showLoading: hosts.isEmpty)
        }
        .onAppear {
            animateCriticalPulse = true
        }
        .navigationDestination(for: PatchmonHostRoute.self) { route in
            PatchmonHostDetailView(
                instanceId: route.instanceId,
                host: route.host,
                onHostDeleted: { deletedHostId in
                    hosts.removeAll { $0.id == deletedHostId }
                    Task { await fetchHosts(showLoading: false) }
                }
            )
        }
    }

    private var instancePicker: some View {
        let instances = servicesStore.instances(for: .patchmon)
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
                            servicesStore.setPreferredInstance(id: instance.id, for: .patchmon)
                            selectedGroup = nil
                            hostGroups = []
                            hosts = []
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(instance.id == selectedInstanceId ? patchmonColor : AppTheme.textMuted.opacity(0.4))
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
                            .glassCard(tint: instance.id == selectedInstanceId ? patchmonColor.opacity(0.1) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var overviewCard: some View {
        let securityTotal = hosts.reduce(0) { $0 + $1.securityUpdatesCount }
        let updatesTotal = hosts.reduce(0) { $0 + $1.updatesCount }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(securityTotal > 0 ? AppTheme.danger : patchmonColor)
                    .scaleEffect(securityTotal > 0 && animateCriticalPulse ? 1.06 : 1.0)
                    .animation(
                        securityTotal > 0
                            ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                            : .default,
                        value: animateCriticalPulse
                    )
                Text(localizer.t.patchmonHosts)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(hosts.count)")
                    .font(.system(size: 30, weight: .bold))
                    .contentTransition(.numericText())
            }

            HStack(spacing: 12) {
                miniStat(
                    value: "\(securityTotal)",
                    label: localizer.t.patchmonSecurity,
                    color: AppTheme.danger
                )
                miniStat(
                    value: "\(updatesTotal)",
                    label: localizer.t.patchmonUpdates,
                    color: AppTheme.warning
                )
                miniStat(
                    value: "\(hosts.filter(\.needsReboot).count)",
                    label: localizer.t.patchmonReboot,
                    color: patchmonColor
                )
            }
        }
        .padding(18)
        .glassCard(tint: summaryTint)
    }

    private var hostGroupFilter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizer.t.patchmonHostGroups)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
                    .textCase(.uppercase)
                Spacer()
                if let selectedGroup {
                    Text(selectedGroup)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(patchmonColor)
                        .lineLimit(1)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                groupChip(title: localizer.t.patchmonAllGroups, value: nil)
                ForEach(hostGroups, id: \.self) { group in
                    groupChip(title: group, value: group)
                }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func groupChip(title: String, value: String?) -> some View {
        let isSelected = selectedGroup == value
        return Button {
            guard selectedGroup != value else { return }
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedGroup = value
            }
            Task { await fetchHosts(showLoading: false) }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(patchmonColor)
                            .matchedGeometryEffect(id: "patchmon-group-chip", in: groupChipNamespace)
                    } else {
                        Capsule(style: .continuous)
                            .fill(AppTheme.surface.opacity(0.75))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(12)
        .background(
            AppTheme.surface.opacity(colorScheme == .dark ? 0.72 : 0.88),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
    }

    private func hostCard(_ host: PatchmonHost) -> some View {
        NavigationLink(value: PatchmonHostRoute(instanceId: selectedInstanceId, host: host)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(host.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if host.securityUpdatesCount > 0 {
                        badge("\(host.securityUpdatesCount)", color: AppTheme.danger)
                    }
                    if host.updatesCount > 0 {
                        badge("\(host.updatesCount)", color: AppTheme.warning)
                    }
                }

                Text(hostSummary(host))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        infoCell(
                            label: localizer.t.patchmonSecurity,
                            value: "\(host.securityUpdatesCount)",
                            color: AppTheme.danger
                        )
                        infoCell(
                            label: localizer.t.patchmonUpdates,
                            value: "\(host.updatesCount)",
                            color: AppTheme.warning
                        )
                    }
                    HStack(spacing: 8) {
                        statusIndicator(host)
                        infoCell(
                            label: localizer.t.patchmonPackages,
                            value: "\(host.totalPackages)",
                            color: patchmonColor
                        )
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(patchmonColor)
                    Text(localizer.t.patchmonOpenDetails)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    if let lastUpdate = host.lastUpdate, !lastUpdate.isEmpty {
                        Text("\(localizer.t.patchmonLastUpdate): \(Formatters.formatDate(lastUpdate))")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .glassCard(tint: hostCardTint)
        }
        .buttonStyle(.plain)
    }

    private func infoCell(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(10)
        .background(AppTheme.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func statusIndicator(_ host: PatchmonHost) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(host.isActive ? AppTheme.running : AppTheme.warning)
                    .frame(width: 8, height: 8)
                Text(statusText(host.status))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer(minLength: 0)
            }
            if host.needsReboot {
                Text(localizer.t.patchmonReboot)
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(AppTheme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(10)
        .background(AppTheme.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private func hostSummary(_ host: PatchmonHost) -> String {
        var parts: [String] = []
        if !host.ip.isEmpty {
            parts.append(host.ip)
        }
        let os = [host.osType, host.osVersion]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !os.isEmpty {
            parts.append(os)
        }
        return parts.isEmpty ? host.hostname : parts.joined(separator: " • ")
    }

    private func statusText(_ value: String) -> String {
        switch value.lowercased() {
        case "active":
            return localizer.t.patchmonStatusActive
        case "pending":
            return localizer.t.patchmonStatusPending
        default:
            return value.capitalized
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textMuted)
                .accessibilityHidden(true)
            Text(selectedGroup == nil ? localizer.t.patchmonNoHosts : localizer.t.patchmonNoHostsInGroup)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func fetchHosts() async {
        await fetchHosts(showLoading: true)
    }

    private func fetchHosts(showLoading: Bool) async {
        do {
            guard let client = await servicesStore.patchmonClient(instanceId: selectedInstanceId) else {
                state = .error(.notConfigured)
                return
            }

            let cached = await client.peekHosts(hostGroup: selectedGroup)
            if let cached, hosts.isEmpty {
                applyHostsResponse(cached, animated: false)
                state = .loaded(())
            }

            if (showLoading || hosts.isEmpty) && cached == nil {
                state = .loading
            }

            let response = try await client.getHosts(hostGroup: selectedGroup)
            applyHostsResponse(response, animated: true)
            state = .loaded(())
        } catch let apiError as APIError {
            if hosts.isEmpty {
                state = .error(apiError)
            } else {
                state = .loaded(())
            }
        } catch {
            if hosts.isEmpty {
                state = .error(.custom(error.localizedDescription))
            } else {
                state = .loaded(())
            }
        }
    }

    private func applyHostsResponse(_ response: PatchmonHostsResponse, animated: Bool) {
        let sortedHosts = response.hosts.sorted {
            if $0.securityUpdatesCount != $1.securityUpdatesCount {
                return $0.securityUpdatesCount > $1.securityUpdatesCount
            }
            if $0.updatesCount != $1.updatesCount {
                return $0.updatesCount > $1.updatesCount
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }

        let update = {
            hosts = sortedHosts
            updateHostGroups(from: response)
        }

        if animated {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                update()
            }
        } else {
            update()
        }
    }

    private func updateHostGroups(from response: PatchmonHostsResponse) {
        let serverGroups = response.filteredByGroups ?? []
        let hostDiscovered = response.hosts.flatMap { host in
            host.hostGroups.map(\.name).filter { !$0.isEmpty }
        }
        let merged = Set(hostGroups).union(serverGroups).union(hostDiscovered)
        hostGroups = merged.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

struct PatchmonHostRoute: Hashable {
    let instanceId: UUID
    let host: PatchmonHost
}
