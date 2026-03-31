import SwiftUI

struct PangolinDashboard: View {
    let instanceId: UUID

    @Environment(ServicesStore.self) private var servicesStore
    @Environment(Localizer.self) private var localizer

    @State private var selectedInstanceId: UUID
    @State private var selectedOrgId: String?
    @State private var state: LoadableState<PangolinSnapshot> = .idle

    private let accent = ServiceType.pangolin.colors.primary

    init(instanceId: UUID) {
        self.instanceId = instanceId
        _selectedInstanceId = State(initialValue: instanceId)
    }

    var body: some View {
        ServiceDashboardLayout(
            serviceType: .pangolin,
            instanceId: selectedInstanceId,
            state: state,
            onRefresh: { await fetchSnapshot(forceLoading: false) }
        ) {
            instancePicker
            orgPicker
            if let snapshot = state.value {
                heroCard(snapshot)
                statsGrid(snapshot)
                sitesSection(snapshot)
                privateResourcesSection(snapshot)
                publicResourcesSection(snapshot)
                clientsSection(snapshot)
                domainsSection(snapshot)
            }
        }
        .navigationTitle(ServiceType.pangolin.displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await fetchSnapshot(forceLoading: false) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(state.isLoading)
            }
        }
        .task(id: fetchTaskKey) {
            await fetchSnapshot(forceLoading: true)
        }
    }

    private var fetchTaskKey: String {
        "\(selectedInstanceId.uuidString)|\(selectedOrgId ?? "default")"
    }

    private var selectedOrg: PangolinOrg? {
        guard let snapshot = state.value else { return nil }
        return snapshot.orgs.first { $0.orgId == snapshot.selectedOrgId }
    }

    private var strings: PangolinStrings {
        PangolinStrings.forLanguage(localizer.language)
    }

    private var instancePicker: some View {
        let instances = servicesStore.instances(for: .pangolin)
        return Group {
            if instances.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizer.t.dashboardInstances.sentenceCased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)

                    ForEach(instances) { instance in
                        Button {
                            HapticManager.light()
                            selectedInstanceId = instance.id
                            selectedOrgId = nil
                            state = .idle
                            servicesStore.setPreferredInstance(id: instance.id, for: .pangolin)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(instance.id == selectedInstanceId ? accent : AppTheme.textMuted.opacity(0.3))
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(instance.displayLabel)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(instance.url)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(14)
                            .glassCard(tint: instance.id == selectedInstanceId ? accent.opacity(0.12) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var orgPicker: some View {
        Group {
            if let snapshot = state.value, snapshot.orgs.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(strings.organizations, detail: "\(snapshot.orgs.count)")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(snapshot.orgs) { org in
                                let isSelected = org.orgId == snapshot.selectedOrgId
                                Button {
                                    guard selectedOrgId != org.orgId else { return }
                                    HapticManager.light()
                                    selectedOrgId = org.orgId
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: isSelected ? "checkmark.seal.fill" : "point.3.connected.trianglepath.dotted")
                                            .font(.caption.bold())
                                        Text(org.name)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(isSelected ? accent : AppTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? accent.opacity(0.16) : AppTheme.surface.opacity(0.9))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func heroCard(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ServiceIconView(type: .pangolin, size: 38)
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedOrg?.name ?? ServiceType.pangolin.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(strings.overviewSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 8) {
                        heroBadge(
                            snapshot.sites.filter(\.online).count == snapshot.sites.count && !snapshot.sites.isEmpty
                                ? strings.allSitesOnline
                                : strings.onlineSites(snapshot.sites.filter(\.online).count),
                            tint: snapshot.sites.contains(where: \.online) ? AppTheme.running : AppTheme.warning
                        )
                        if let org = selectedOrg?.subnet, !org.isEmpty {
                            heroBadge(org, tint: accent)
                        }
                    }
                }
            }

            if let org = selectedOrg {
                HStack(spacing: 10) {
                    infoPill(strings.org, org.orgId, tint: accent)
                    if let subnet = org.utilitySubnet, !subnet.isEmpty {
                        infoPill(strings.utility, subnet, tint: AppTheme.info)
                    }
                    if org.isBillingOrg == true {
                        infoPill(strings.billing, strings.enabled, tint: AppTheme.warning)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.20),
                            accent.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .glassCard(cornerRadius: 30, tint: accent.opacity(0.08))
    }

    private func statsGrid(_ snapshot: PangolinSnapshot) -> some View {
        LazyVGrid(columns: twoColumnGrid, spacing: AppTheme.gridSpacing) {
            GlassStatCard(
                title: strings.sites,
                value: "\(snapshot.sites.count)",
                icon: "point.3.connected.trianglepath.dotted",
                iconColor: accent,
                subtitle: strings.onlineCount(snapshot.sites.filter { $0.online }.count)
            )
            GlassStatCard(
                title: strings.privateResources,
                value: "\(snapshot.siteResources.count)",
                icon: "lock.shield.fill",
                iconColor: AppTheme.info,
                subtitle: strings.enabledCount(snapshot.siteResources.filter { $0.enabled }.count)
            )
            GlassStatCard(
                title: strings.publicResources,
                value: "\(snapshot.resources.count)",
                icon: "globe",
                iconColor: AppTheme.running,
                subtitle: strings.enabledCount(snapshot.resources.filter { $0.enabled }.count)
            )
            GlassStatCard(
                title: strings.clients,
                value: "\(snapshot.clients.count)",
                icon: "person.2.fill",
                iconColor: AppTheme.warning,
                subtitle: strings.onlineCount(snapshot.clients.filter { $0.online }.count)
            )
            GlassStatCard(
                title: strings.domains,
                value: "\(snapshot.domains.count)",
                icon: "network",
                iconColor: AppTheme.accent,
                subtitle: strings.verifiedCount(snapshot.domains.filter { $0.verified }.count)
            )
            GlassStatCard(
                title: strings.traffic,
                value: trafficValue(snapshot.sites, snapshot.clients),
                icon: "arrow.left.and.right.circle.fill",
                iconColor: accent,
                subtitle: strings.ingressEgress
            )
        }
    }

    private func sitesSection(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(strings.sites, detail: strings.onlineCount(snapshot.sites.filter { $0.online }.count))

            if snapshot.sites.isEmpty {
                placeholderCard(strings.noSites)
            } else {
                ForEach(snapshot.sites.prefix(8)) { site in
                    itemCard(
                        title: site.name,
                        subtitle: joined(site.address, site.subnet, site.type),
                        details: [
                            site.online ? strings.online : strings.offline,
                            site.newtVersion.map(strings.newtVersion),
                            site.exitNodeName.map(strings.exitNode),
                            trafficLabel(site),
                            site.newtUpdateAvailable == true ? strings.newtUpdate : nil,
                            site.exitNodeEndpoint.map(strings.endpoint)
                        ],
                        tint: site.online ? accent : AppTheme.warning
                    )
                }
            }
        }
    }

    private func privateResourcesSection(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(strings.privateResources, detail: strings.enabledCount(snapshot.siteResources.filter { $0.enabled }.count))

            if snapshot.siteResources.isEmpty {
                placeholderCard(strings.noPrivateResources)
            } else {
                ForEach(snapshot.siteResources.prefix(8)) { resource in
                    itemCard(
                        title: resource.name,
                        subtitle: joined(resource.siteName, resource.destination),
                        details: [
                            resource.enabled ? strings.enabled : strings.disabled,
                            resource.mode?.capitalized,
                            resource.protocolName?.uppercased(),
                            resource.proxyPort.map(strings.proxyPort),
                            resource.destinationPort.map(strings.destinationPort),
                            resource.alias.map(strings.alias),
                            resource.aliasAddress.map(strings.dns),
                            resource.tcpPortRangeString.map(strings.tcpPorts),
                            resource.udpPortRangeString.map(strings.udpPorts),
                            resource.authDaemonPort.map(strings.authDaemonPort),
                            resource.authDaemonMode?.uppercased(),
                            resource.disableIcmp == true ? strings.icmpOff : nil
                        ],
                        tint: resource.enabled ? AppTheme.info : AppTheme.textMuted
                    )
                }
            }
        }
    }

    private func publicResourcesSection(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(strings.publicResources, detail: strings.enabledCount(snapshot.resources.filter { $0.enabled }.count))

            if snapshot.resources.isEmpty {
                placeholderCard(strings.noPublicResources)
            } else {
                ForEach(snapshot.resources.prefix(8)) { resource in
                    publicResourceCard(
                        resource,
                        targets: snapshot.targetsByResourceId[resource.resourceId] ?? resource.targets
                    )
                }
            }
        }
    }

    private func clientsSection(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(strings.clients, detail: strings.onlineCount(snapshot.clients.filter { $0.online }.count))

            if snapshot.clients.isEmpty {
                placeholderCard(strings.noClients)
            } else {
                ForEach(snapshot.clients.prefix(8)) { client in
                    itemCard(
                        title: client.name,
                        subtitle: joined(client.subnet, client.type?.capitalized),
                        details: [
                            client.blocked ? strings.blocked : nil,
                            client.archived ? strings.archived : nil,
                            client.online ? strings.online : strings.offline,
                            client.olmVersion.map(strings.olmVersion),
                            client.approvalState.map(strings.approvalState),
                            client.sites.isEmpty ? nil : strings.linkedSites(client.sites.count),
                            clientTrafficLabel(client)
                        ],
                        tint: client.blocked ? AppTheme.danger : (client.online ? AppTheme.running : AppTheme.textMuted)
                    )
                }
            }
        }
    }

    private func domainsSection(_ snapshot: PangolinSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(strings.domains, detail: strings.verifiedCount(snapshot.domains.filter { $0.verified }.count))

            if snapshot.domains.isEmpty {
                placeholderCard(strings.noDomains)
            } else {
                ForEach(snapshot.domains.prefix(8)) { domain in
                    itemCard(
                        title: domain.baseDomain,
                        subtitle: joined(domain.type?.capitalized, domain.certResolver),
                        details: [
                            domain.verified ? strings.verified : strings.pending,
                            domain.failed ? strings.failed : nil,
                            domain.errorMessage,
                            domain.certResolver.map(strings.resolver),
                            domain.configManaged.map { $0 ? strings.managed : strings.manual },
                            domain.preferWildcardCert == true ? strings.wildcard : nil,
                            domain.tries.map(strings.tries)
                        ],
                        tint: domain.failed ? AppTheme.danger : (domain.verified ? accent : AppTheme.warning)
                    )
                }
            }
        }
    }

    private func publicResourceCard(_ resource: PangolinResource, targets: [PangolinTarget]) -> some View {
        let tint = resourceTint(resource, targets: targets)
        let detailItems = [
            resource.enabled ? strings.enabled : strings.disabled,
            resource.ssl ? "TLS" : nil,
            resource.sso ? "SSO" : nil,
            resource.whitelist ? strings.whitelist : nil,
            resource.http ? "HTTP" : nil,
            resource.proxyPort.map(strings.proxyPort),
            strings.targetsCount(targets.count),
            targetHealthLabel(targets)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            itemCard(
                title: resource.name,
                subtitle: joined(resource.fullDomain, resource.protocolName?.uppercased()),
                details: detailItems,
                tint: tint
            )

            if !targets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(targets.prefix(3)) { target in
                        targetCard(target, tint: targetTint(target))
                    }
                }
            }
        }
    }

    private func itemCard(
        title: String,
        subtitle: String?,
        details: [String?],
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "seal.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(tint)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            let trimmedDetails = details.compactMap { detail -> String? in
                guard let detail else { return nil }
                let value = detail.trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
            if !trimmedDetails.isEmpty {
                FlexiblePillRow(items: trimmedDetails, tint: tint)
            }
        }
        .padding(AppTheme.innerPadding)
        .glassCard(tint: tint.opacity(0.05))
    }

    private func placeholderCard(_ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .foregroundStyle(AppTheme.textMuted)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .padding(AppTheme.innerPadding)
        .glassCard()
    }

    private func targetCard(_ target: PangolinTarget, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(target.ip):\(target.port)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let subtitle = joined(target.method?.uppercased(), target.path, target.pathMatchType?.uppercased()) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            FlexiblePillRow(
                items: [
                    target.enabled ? strings.enabled : strings.disabled,
                    target.hcEnabled == true ? strings.healthCheck : nil,
                    target.hcHealth.map(strings.healthStatus),
                    target.hcPath.map(strings.healthPath),
                    target.priority.map(strings.priority),
                    target.rewritePath.map(strings.rewrite)
                ].compactMap { $0 },
                tint: tint
            )
        }
        .padding(AppTheme.innerPadding)
        .glassCard(tint: tint.opacity(0.05))
    }

    private func sectionHeader(_ title: String, detail: String?) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }

    private func heroBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
            )
    }

    private func infoPill(_ title: String, _ value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }

    private func fetchSnapshot(forceLoading: Bool) async {
        if forceLoading || state.value == nil {
            state = .loading
        }

        do {
            guard let client = await servicesStore.pangolinClient(instanceId: selectedInstanceId) else {
                state = .error(.notConfigured)
                return
            }

            let orgs = try await client.listOrgs()
            guard let orgId = selectedOrgId ?? orgs.first?.orgId else {
                state = .error(.custom(strings.noOrganizations))
                return
            }

            if selectedOrgId != orgId {
                selectedOrgId = orgId
            }

            let snapshot = try await client.fetchSnapshot(orgId: orgId, orgs: orgs)
            state = .loaded(snapshot)
        } catch let error as APIError {
            state = .error(error)
        } catch {
            state = .error(.networkError(error))
        }
    }

    private func trafficValue(_ sites: [PangolinSite], _ clients: [PangolinClient]) -> String {
        let siteMegabytes = sites.reduce(0.0) { partial, site in
            partial + (site.megabytesIn ?? 0) + (site.megabytesOut ?? 0)
        }
        let clientMegabytes = clients.reduce(0.0) { partial, client in
            partial + (client.megabytesIn ?? 0) + (client.megabytesOut ?? 0)
        }
        return Formatters.formatBytes((siteMegabytes + clientMegabytes) * 1_048_576)
    }

    private func trafficLabel(_ site: PangolinSite) -> String? {
        let incoming = site.megabytesIn ?? 0
        let outgoing = site.megabytesOut ?? 0
        guard incoming > 0 || outgoing > 0 else { return nil }
        return strings.trafficAmount(Formatters.formatBytes((incoming + outgoing) * 1_048_576))
    }

    private func clientTrafficLabel(_ client: PangolinClient) -> String? {
        let incoming = client.megabytesIn ?? 0
        let outgoing = client.megabytesOut ?? 0
        guard incoming > 0 || outgoing > 0 else { return nil }
        return strings.trafficAmount(Formatters.formatBytes((incoming + outgoing) * 1_048_576))
    }

    private func targetHealthLabel(_ targets: [PangolinTarget]) -> String? {
        guard !targets.isEmpty else { return nil }
        let unhealthy = targets.filter { (($0.hcHealth ?? $0.healthStatus) ?? "").localizedCaseInsensitiveContains("unhealthy") }.count
        if unhealthy > 0 {
            return strings.unhealthyCount(unhealthy)
        }
        let healthy = targets.filter {
            let status = ($0.hcHealth ?? $0.healthStatus) ?? ""
            return status.localizedCaseInsensitiveContains("healthy")
                && !status.localizedCaseInsensitiveContains("unhealthy")
        }.count
        if healthy > 0 {
            return strings.healthyCount(healthy)
        }
        return nil
    }

    private func resourceTint(_ resource: PangolinResource, targets: [PangolinTarget]) -> Color {
        if targets.contains(where: { (($0.hcHealth ?? $0.healthStatus) ?? "").localizedCaseInsensitiveContains("unhealthy") }) {
            return AppTheme.danger
        }
        return resource.enabled ? accent : AppTheme.textMuted
    }

    private func targetTint(_ target: PangolinTarget) -> Color {
        let status = (target.hcHealth ?? target.healthStatus) ?? ""
        if status.localizedCaseInsensitiveContains("unhealthy") {
            return AppTheme.danger
        }
        if status.localizedCaseInsensitiveContains("healthy") {
            return AppTheme.running
        }
        return target.enabled ? accent : AppTheme.textMuted
    }

    private func joined(_ values: String?...) -> String? {
        let filtered = values.compactMap { value -> String? in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return filtered.isEmpty ? nil : filtered.joined(separator: " • ")
    }
}

private struct FlexiblePillRow: View {
    let items: [String]
    let tint: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(tint.opacity(0.12))
                        )
                }
            }
        }
    }
}

struct PangolinStrings {
    let serviceDescription: String
    let loginHint: String
    let orgIdPlaceholder: String
    let sitesClientsLabel: String
    let overviewSubtitle: String
    let organizations: String
    let sites: String
    let privateResources: String
    let publicResources: String
    let clients: String
    let domains: String
    let traffic: String
    let ingressEgress: String
    let org: String
    let utility: String
    let billing: String
    let enabled: String
    let disabled: String
    let online: String
    let offline: String
    let blocked: String
    let archived: String
    let pending: String
    let verified: String
    let failed: String
    let managed: String
    let manual: String
    let wildcard: String
    let whitelist: String
    let healthCheck: String
    let agentUpdate: String
    let newtUpdate: String
    let icmpOff: String
    let noOrganizations: String
    let noSites: String
    let noPrivateResources: String
    let noPublicResources: String
    let noClients: String
    let noDomains: String
    let site: String
    let healthy: String
    let unhealthy: String
    let allSitesOnline: String
    let onlineSitesFormat: String
    let onlineCountFormat: String
    let enabledCountFormat: String
    let verifiedCountFormat: String
    let targetsCountFormat: String
    let linkedSitesFormat: String
    let triesFormat: String
    let healthyCountFormat: String
    let unhealthyCountFormat: String
    let newtVersionFormat: String
    let exitNodeFormat: String
    let endpointFormat: String
    let proxyPortFormat: String
    let destinationPortFormat: String
    let aliasFormat: String
    let dnsFormat: String
    let tcpPortsFormat: String
    let udpPortsFormat: String
    let authDaemonPortFormat: String
    let olmVersionFormat: String
    let resolverFormat: String
    let rewriteFormat: String
    let healthPathFormat: String
    let priorityFormat: String
    let trafficAmountFormat: String

    func onlineSites(_ count: Int) -> String { String(format: onlineSitesFormat, count) }
    func onlineCount(_ count: Int) -> String { String(format: onlineCountFormat, count) }
    func enabledCount(_ count: Int) -> String { String(format: enabledCountFormat, count) }
    func verifiedCount(_ count: Int) -> String { String(format: verifiedCountFormat, count) }
    func targetsCount(_ count: Int) -> String { String(format: targetsCountFormat, count) }
    func linkedSites(_ count: Int) -> String { String(format: linkedSitesFormat, count) }
    func tries(_ count: Int) -> String { String(format: triesFormat, count) }
    func healthyCount(_ count: Int) -> String { String(format: healthyCountFormat, count) }
    func unhealthyCount(_ count: Int) -> String { String(format: unhealthyCountFormat, count) }
    func newtVersion(_ value: String) -> String { String(format: newtVersionFormat, value) }
    func exitNode(_ value: String) -> String { String(format: exitNodeFormat, value) }
    func endpoint(_ value: String) -> String { String(format: endpointFormat, value) }
    func proxyPort(_ value: Int) -> String { String(format: proxyPortFormat, value) }
    func destinationPort(_ value: Int) -> String { String(format: destinationPortFormat, value) }
    func alias(_ value: String) -> String { String(format: aliasFormat, value) }
    func dns(_ value: String) -> String { String(format: dnsFormat, value) }
    func tcpPorts(_ value: String) -> String { String(format: tcpPortsFormat, value) }
    func udpPorts(_ value: String) -> String { String(format: udpPortsFormat, value) }
    func authDaemonPort(_ value: Int) -> String { String(format: authDaemonPortFormat, value) }
    func olmVersion(_ value: String) -> String { String(format: olmVersionFormat, value) }
    func resolver(_ value: String) -> String { String(format: resolverFormat, value) }
    func rewrite(_ value: String) -> String { String(format: rewriteFormat, value) }
    func healthPath(_ value: String) -> String { String(format: healthPathFormat, value) }
    func priority(_ value: Int) -> String { String(format: priorityFormat, value) }
    func trafficAmount(_ value: String) -> String { String(format: trafficAmountFormat, value) }
    func approvalState(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "approved": return verified
        case "pending": return pending
        case "blocked": return blocked
        case "archived": return archived
        default: return value.capitalized
        }
    }
    func healthStatus(_ value: String) -> String {
        let lowered = value.lowercased()
        if lowered.contains("unhealthy") { return unhealthy }
        if lowered.contains("healthy") { return healthy }
        if lowered.contains("pending") { return pending }
        return value.capitalized
    }
}

extension PangolinStrings {
    static func forLanguage(_ language: Language) -> PangolinStrings {
        switch language {
        case .it:
            return PangolinStrings(
                serviceDescription: "Reverse proxy, tunneling e networking zero-trust",
                loginHint: "Usa una Integration API key di Pangolin. Per una chiave con accesso a una sola organizzazione (Org-Scoped Key), inserisci anche l'ID Organizzazione.",
                orgIdPlaceholder: "ID Organizzazione (opzionale)",
                sitesClientsLabel: "Siti / client",
                overviewSubtitle: "Panoramica di reverse proxy, tunneling e rete zero-trust",
                organizations: "Organizzazioni",
                sites: "Siti",
                privateResources: "Risorse private",
                publicResources: "Risorse pubbliche",
                clients: "Client",
                domains: "Domini",
                traffic: "Traffico",
                ingressEgress: "Ingresso + uscita",
                org: "Org",
                utility: "Utility",
                billing: "Billing",
                enabled: "Attivo",
                disabled: "Disattivato",
                online: "Online",
                offline: "Offline",
                blocked: "Bloccato",
                archived: "Archiviato",
                pending: "In attesa",
                verified: "Verificato",
                failed: "Errore",
                managed: "Gestito",
                manual: "Manuale",
                wildcard: "Wildcard",
                whitelist: "Whitelist",
                healthCheck: "Health check",
                agentUpdate: "Aggiornamento agent",
                newtUpdate: "Aggiornamento Newt",
                icmpOff: "ICMP disattivato",
                noOrganizations: "Nessuna organizzazione Pangolin disponibile per questa API key",
                noSites: "Nessun sito Pangolin trovato",
                noPrivateResources: "Nessuna risorsa privata configurata",
                noPublicResources: "Nessuna risorsa pubblica configurata",
                noClients: "Nessun client registrato",
                noDomains: "Nessun dominio gestito",
                site: "Sito",
                healthy: "Sano",
                unhealthy: "Non sano",
                allSitesOnline: "Tutti i siti online",
                onlineSitesFormat: "%d siti online",
                onlineCountFormat: "%d online",
                enabledCountFormat: "%d attivi",
                verifiedCountFormat: "%d verificati",
                targetsCountFormat: "%d target",
                linkedSitesFormat: "%d siti collegati",
                triesFormat: "%d tentativi",
                healthyCountFormat: "%d sani",
                unhealthyCountFormat: "%d non sani",
                newtVersionFormat: "Newt %@",
                exitNodeFormat: "Exit %@",
                endpointFormat: "Endpoint %@",
                proxyPortFormat: "Proxy %d",
                destinationPortFormat: "Dest %d",
                aliasFormat: "Alias %@",
                dnsFormat: "DNS %@",
                tcpPortsFormat: "TCP %@",
                udpPortsFormat: "UDP %@",
                authDaemonPortFormat: "Authd %d",
                olmVersionFormat: "OLM %@",
                resolverFormat: "Resolver %@",
                rewriteFormat: "Rewrite %@",
                healthPathFormat: "HC %@",
                priorityFormat: "Priorità %d",
                trafficAmountFormat: "Traffico %@"
            )
        case .fr:
            return PangolinStrings(
                serviceDescription: "Reverse proxy, tunneling et réseau zero-trust",
                loginHint: "Utilisez une clé Integration API Pangolin. Pour une clé limitée à une organisation (Org-Scoped Key), indiquez aussi l'ID d'organisation.",
                orgIdPlaceholder: "ID d'organisation (optionnel)",
                sitesClientsLabel: "Sites / clients",
                overviewSubtitle: "Vue d’ensemble du reverse proxy, du tunneling et du réseau zero-trust",
                organizations: "Organisations",
                sites: "Sites",
                privateResources: "Ressources privées",
                publicResources: "Ressources publiques",
                clients: "Clients",
                domains: "Domaines",
                traffic: "Trafic",
                ingressEgress: "Entrant + sortant",
                org: "Org",
                utility: "Utility",
                billing: "Facturation",
                enabled: "Activé",
                disabled: "Désactivé",
                online: "En ligne",
                offline: "Hors ligne",
                blocked: "Bloqué",
                archived: "Archivé",
                pending: "En attente",
                verified: "Vérifié",
                failed: "Échec",
                managed: "Géré",
                manual: "Manuel",
                wildcard: "Wildcard",
                whitelist: "Liste blanche",
                healthCheck: "Contrôle de santé",
                agentUpdate: "Mise à jour agent",
                newtUpdate: "Mise à jour Newt",
                icmpOff: "ICMP désactivé",
                noOrganizations: "Aucune organisation Pangolin disponible pour cette clé API",
                noSites: "Aucun site Pangolin trouvé",
                noPrivateResources: "Aucune ressource privée configurée",
                noPublicResources: "Aucune ressource publique configurée",
                noClients: "Aucun client inscrit",
                noDomains: "Aucun domaine géré",
                site: "Site",
                healthy: "Sain",
                unhealthy: "Dégradé",
                allSitesOnline: "Tous les sites sont en ligne",
                onlineSitesFormat: "%d sites en ligne",
                onlineCountFormat: "%d en ligne",
                enabledCountFormat: "%d activés",
                verifiedCountFormat: "%d vérifiés",
                targetsCountFormat: "%d cibles",
                linkedSitesFormat: "%d sites liés",
                triesFormat: "%d tentatives",
                healthyCountFormat: "%d sains",
                unhealthyCountFormat: "%d dégradés",
                newtVersionFormat: "Newt %@",
                exitNodeFormat: "Sortie %@",
                endpointFormat: "Endpoint %@",
                proxyPortFormat: "Proxy %d",
                destinationPortFormat: "Destination %d",
                aliasFormat: "Alias %@",
                dnsFormat: "DNS %@",
                tcpPortsFormat: "TCP %@",
                udpPortsFormat: "UDP %@",
                authDaemonPortFormat: "Authd %d",
                olmVersionFormat: "OLM %@",
                resolverFormat: "Résolveur %@",
                rewriteFormat: "Réécriture %@",
                healthPathFormat: "HC %@",
                priorityFormat: "Priorité %d",
                trafficAmountFormat: "Trafic %@"
            )
        case .es:
            return PangolinStrings(
                serviceDescription: "Reverse proxy, tunneling y red zero-trust",
                loginHint: "Usa una clave Integration API de Pangolin. Para una clave de ámbito de organización (Org-Scoped Key), introduce también el ID de organización.",
                orgIdPlaceholder: "ID de organización (opcional)",
                sitesClientsLabel: "Sitios / clientes",
                overviewSubtitle: "Resumen de reverse proxy, tunneling y red zero-trust",
                organizations: "Organizaciones",
                sites: "Sitios",
                privateResources: "Recursos privados",
                publicResources: "Recursos públicos",
                clients: "Clientes",
                domains: "Dominios",
                traffic: "Tráfico",
                ingressEgress: "Entrada + salida",
                org: "Org",
                utility: "Utility",
                billing: "Facturación",
                enabled: "Activo",
                disabled: "Desactivado",
                online: "En línea",
                offline: "Sin conexión",
                blocked: "Bloqueado",
                archived: "Archivado",
                pending: "Pendiente",
                verified: "Verificado",
                failed: "Error",
                managed: "Gestionado",
                manual: "Manual",
                wildcard: "Wildcard",
                whitelist: "Lista blanca",
                healthCheck: "Health check",
                agentUpdate: "Actualización del agente",
                newtUpdate: "Actualización de Newt",
                icmpOff: "ICMP desactivado",
                noOrganizations: "No hay organizaciones Pangolin disponibles para esta API key",
                noSites: "No se encontraron sitios Pangolin",
                noPrivateResources: "No hay recursos privados configurados",
                noPublicResources: "No hay recursos públicos configurados",
                noClients: "No hay clientes registrados",
                noDomains: "No hay dominios gestionados",
                site: "Sitio",
                healthy: "Saludable",
                unhealthy: "No saludable",
                allSitesOnline: "Todos los sitios en línea",
                onlineSitesFormat: "%d sitios en línea",
                onlineCountFormat: "%d en línea",
                enabledCountFormat: "%d activos",
                verifiedCountFormat: "%d verificados",
                targetsCountFormat: "%d destinos",
                linkedSitesFormat: "%d sitios vinculados",
                triesFormat: "%d intentos",
                healthyCountFormat: "%d saludables",
                unhealthyCountFormat: "%d no saludables",
                newtVersionFormat: "Newt %@",
                exitNodeFormat: "Salida %@",
                endpointFormat: "Endpoint %@",
                proxyPortFormat: "Proxy %d",
                destinationPortFormat: "Destino %d",
                aliasFormat: "Alias %@",
                dnsFormat: "DNS %@",
                tcpPortsFormat: "TCP %@",
                udpPortsFormat: "UDP %@",
                authDaemonPortFormat: "Authd %d",
                olmVersionFormat: "OLM %@",
                resolverFormat: "Resolver %@",
                rewriteFormat: "Reescritura %@",
                healthPathFormat: "HC %@",
                priorityFormat: "Prioridad %d",
                trafficAmountFormat: "Tráfico %@"
            )
        case .de:
            return PangolinStrings(
                serviceDescription: "Reverse Proxy, Tunneling und Zero-Trust-Networking",
                loginHint: "Verwende einen Pangolin-Integration-API-Schlüssel. Bei einem auf eine Organisation begrenzten Schlüssel (Org-Scoped Key) auch die Organisations-ID eintragen.",
                orgIdPlaceholder: "Organisations-ID (optional)",
                sitesClientsLabel: "Sites / Clients",
                overviewSubtitle: "Übersicht über Reverse Proxy, Tunneling und Zero-Trust-Netzwerk",
                organizations: "Organisationen",
                sites: "Sites",
                privateResources: "Private Ressourcen",
                publicResources: "Öffentliche Ressourcen",
                clients: "Clients",
                domains: "Domains",
                traffic: "Traffic",
                ingressEgress: "Ingress + Egress",
                org: "Org",
                utility: "Utility",
                billing: "Abrechnung",
                enabled: "Aktiviert",
                disabled: "Deaktiviert",
                online: "Online",
                offline: "Offline",
                blocked: "Blockiert",
                archived: "Archiviert",
                pending: "Ausstehend",
                verified: "Verifiziert",
                failed: "Fehler",
                managed: "Verwaltet",
                manual: "Manuell",
                wildcard: "Wildcard",
                whitelist: "Whitelist",
                healthCheck: "Health Check",
                agentUpdate: "Agent-Update",
                newtUpdate: "Newt-Update",
                icmpOff: "ICMP aus",
                noOrganizations: "Keine Pangolin-Organisationen für diesen API-Schlüssel verfügbar",
                noSites: "Keine Pangolin-Sites gefunden",
                noPrivateResources: "Keine privaten Ressourcen konfiguriert",
                noPublicResources: "Keine öffentlichen Ressourcen konfiguriert",
                noClients: "Keine Clients registriert",
                noDomains: "Keine verwalteten Domains",
                site: "Site",
                healthy: "Gesund",
                unhealthy: "Ungesund",
                allSitesOnline: "Alle Sites online",
                onlineSitesFormat: "%d Sites online",
                onlineCountFormat: "%d online",
                enabledCountFormat: "%d aktiviert",
                verifiedCountFormat: "%d verifiziert",
                targetsCountFormat: "%d Ziele",
                linkedSitesFormat: "%d verknüpfte Sites",
                triesFormat: "%d Versuche",
                healthyCountFormat: "%d gesund",
                unhealthyCountFormat: "%d ungesund",
                newtVersionFormat: "Newt %@",
                exitNodeFormat: "Exit %@",
                endpointFormat: "Endpoint %@",
                proxyPortFormat: "Proxy %d",
                destinationPortFormat: "Ziel %d",
                aliasFormat: "Alias %@",
                dnsFormat: "DNS %@",
                tcpPortsFormat: "TCP %@",
                udpPortsFormat: "UDP %@",
                authDaemonPortFormat: "Authd %d",
                olmVersionFormat: "OLM %@",
                resolverFormat: "Resolver %@",
                rewriteFormat: "Rewrite %@",
                healthPathFormat: "HC %@",
                priorityFormat: "Priorität %d",
                trafficAmountFormat: "Traffic %@"
            )
        case .en:
            return PangolinStrings(
                serviceDescription: "Reverse proxy, tunneling and zero-trust networking",
                loginHint: "Use a Pangolin integration API key. If using an org-scoped key (no root access), also enter your Organization ID.",
                orgIdPlaceholder: "Organization ID (optional)",
                sitesClientsLabel: "Sites / clients",
                overviewSubtitle: "Reverse proxy, tunneling and zero-trust network overview",
                organizations: "Organizations",
                sites: "Sites",
                privateResources: "Private Resources",
                publicResources: "Public Resources",
                clients: "Clients",
                domains: "Domains",
                traffic: "Traffic",
                ingressEgress: "Ingress + egress",
                org: "Org",
                utility: "Utility",
                billing: "Billing",
                enabled: "Enabled",
                disabled: "Disabled",
                online: "Online",
                offline: "Offline",
                blocked: "Blocked",
                archived: "Archived",
                pending: "Pending",
                verified: "Verified",
                failed: "Failed",
                managed: "Managed",
                manual: "Manual",
                wildcard: "Wildcard",
                whitelist: "Whitelist",
                healthCheck: "Health check",
                agentUpdate: "Agent update",
                newtUpdate: "Newt update",
                icmpOff: "ICMP off",
                noOrganizations: "No Pangolin organizations available for this API key",
                noSites: "No Pangolin sites found",
                noPrivateResources: "No private resources configured",
                noPublicResources: "No public resources configured",
                noClients: "No clients enrolled",
                noDomains: "No managed domains",
                site: "Site",
                healthy: "Healthy",
                unhealthy: "Unhealthy",
                allSitesOnline: "All sites online",
                onlineSitesFormat: "%d sites online",
                onlineCountFormat: "%d online",
                enabledCountFormat: "%d enabled",
                verifiedCountFormat: "%d verified",
                targetsCountFormat: "%d targets",
                linkedSitesFormat: "%d linked sites",
                triesFormat: "%d tries",
                healthyCountFormat: "%d healthy",
                unhealthyCountFormat: "%d unhealthy",
                newtVersionFormat: "Newt %@",
                exitNodeFormat: "Exit %@",
                endpointFormat: "Endpoint %@",
                proxyPortFormat: "Proxy %d",
                destinationPortFormat: "Dest %d",
                aliasFormat: "Alias %@",
                dnsFormat: "DNS %@",
                tcpPortsFormat: "TCP %@",
                udpPortsFormat: "UDP %@",
                authDaemonPortFormat: "Authd %d",
                olmVersionFormat: "OLM %@",
                resolverFormat: "Resolver %@",
                rewriteFormat: "Rewrite %@",
                healthPathFormat: "HC %@",
                priorityFormat: "Priority %d",
                trafficAmountFormat: "Traffic %@"
            )
        }
    }
}
