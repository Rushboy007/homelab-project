import Foundation

struct PangolinEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
    let pagination: PangolinPagination?
}

struct PangolinOrgListData: Decodable, Sendable {
    let orgs: [PangolinOrg]
}

struct PangolinPagination: Decodable, Sendable {
    let total: Int?
    let pageSize: Int?
    let page: Int?
    let limit: Int?
    let offset: Int?
}

struct PangolinOrg: Decodable, Identifiable, Hashable, Sendable {
    let orgId: String
    let name: String
    let subnet: String?
    let utilitySubnet: String?
    let isBillingOrg: Bool?

    var id: String { orgId }
}

struct PangolinSite: Decodable, Identifiable, Hashable, Sendable {
    let siteId: Int
    let niceId: String
    let name: String
    let subnet: String?
    let megabytesIn: Double?
    let megabytesOut: Double?
    let type: String?
    let online: Bool
    let address: String?
    let newtVersion: String?
    let exitNodeName: String?
    let exitNodeEndpoint: String?
    let newtUpdateAvailable: Bool?

    var id: Int { siteId }
}

struct PangolinSitesData: Decodable, Sendable {
    let sites: [PangolinSite]
}

struct PangolinSiteResource: Decodable, Identifiable, Hashable, Sendable {
    let siteResourceId: Int
    let siteId: Int
    let orgId: String
    let niceId: String
    let name: String
    let mode: String?
    let protocolName: String?
    let proxyPort: Int?
    let destinationPort: Int?
    let destination: String?
    let enabled: Bool
    let alias: String?
    let aliasAddress: String?
    let tcpPortRangeString: String?
    let udpPortRangeString: String?
    let disableIcmp: Bool?
    let authDaemonMode: String?
    let authDaemonPort: Int?
    let siteName: String
    let siteNiceId: String
    let siteAddress: String?

    var id: Int { siteResourceId }

    enum CodingKeys: String, CodingKey {
        case siteResourceId, siteId, orgId, niceId, name, mode, proxyPort, destinationPort, destination, enabled, alias, aliasAddress, tcpPortRangeString, udpPortRangeString, disableIcmp, authDaemonMode, authDaemonPort, siteName, siteNiceId, siteAddress
        case protocolName = "protocol"
    }
}

struct PangolinSiteResourcesData: Decodable, Sendable {
    let siteResources: [PangolinSiteResource]
}

struct PangolinTarget: Decodable, Identifiable, Hashable, Sendable {
    let targetId: Int
    let ip: String
    let port: Int
    let enabled: Bool
    let healthStatus: String?
    let method: String?
    let resourceId: Int?
    let siteId: Int?
    let siteType: String?
    let hcEnabled: Bool?
    let hcPath: String?
    let hcScheme: String?
    let hcMode: String?
    let hcHostname: String?
    let hcPort: Int?
    let hcInterval: Int?
    let hcUnhealthyInterval: Int?
    let hcTimeout: Int?
    let hcHeaders: [PangolinHeader]?
    let hcFollowRedirects: Bool?
    let hcMethod: String?
    let hcStatus: String?
    let hcHealth: String?
    let hcTlsServerName: String?
    let path: String?
    let pathMatchType: String?
    let rewritePath: String?
    let rewritePathType: String?
    let priority: Int?

    var id: Int { targetId }
}

struct PangolinHeader: Decodable, Hashable, Sendable {
    let name: String
    let value: String
}

struct PangolinResource: Decodable, Identifiable, Hashable, Sendable {
    let resourceId: Int
    let name: String
    let ssl: Bool
    let fullDomain: String?
    let sso: Bool
    let whitelist: Bool
    let http: Bool
    let protocolName: String?
    let proxyPort: Int?
    let enabled: Bool
    let domainId: String?
    let niceId: String
    let targets: [PangolinTarget]

    var id: Int { resourceId }

    enum CodingKeys: String, CodingKey {
        case resourceId, name, ssl, fullDomain, sso, whitelist, http, proxyPort, enabled, domainId, niceId, targets
        case protocolName = "protocol"
    }
}

struct PangolinResourcesData: Decodable, Sendable {
    let resources: [PangolinResource]
}

struct PangolinTargetsData: Decodable, Sendable {
    let targets: [PangolinTarget]
}

struct PangolinClientSite: Decodable, Hashable, Sendable {
    let siteId: Int
    let siteName: String?
    let siteNiceId: String?
}

struct PangolinClient: Decodable, Identifiable, Hashable, Sendable {
    let clientId: Int
    let orgId: String
    let name: String
    let subnet: String?
    let megabytesIn: Double?
    let megabytesOut: Double?
    let type: String?
    let online: Bool
    let olmVersion: String?
    let niceId: String
    let approvalState: String?
    let archived: Bool
    let blocked: Bool
    let olmUpdateAvailable: Bool?
    let sites: [PangolinClientSite]

    var id: Int { clientId }
}

struct PangolinClientsData: Decodable, Sendable {
    let clients: [PangolinClient]
}

struct PangolinDomain: Decodable, Identifiable, Hashable, Sendable {
    let domainId: String
    let baseDomain: String
    let verified: Bool
    let type: String?
    let failed: Bool
    let tries: Int?
    let configManaged: Bool?
    let certResolver: String?
    let preferWildcardCert: Bool?
    let errorMessage: String?

    var id: String { domainId }
}

struct PangolinDomainsData: Decodable, Sendable {
    let domains: [PangolinDomain]
}

struct PangolinSnapshot: Sendable {
    let orgs: [PangolinOrg]
    let selectedOrgId: String
    let sites: [PangolinSite]
    let siteResources: [PangolinSiteResource]
    let resources: [PangolinResource]
    let targetsByResourceId: [Int: [PangolinTarget]]
    let clients: [PangolinClient]
    let domains: [PangolinDomain]
}

actor PangolinAPIClient {
    private let engine: BaseNetworkEngine
    private var baseURL: String = ""
    private var fallbackURL: String = ""
    private var apiKey: String = ""
    private var scopedOrgId: String = ""

    var isOrgScoped: Bool { !scopedOrgId.isEmpty }

    init(instanceId: UUID) {
        self.engine = BaseNetworkEngine(serviceType: .pangolin, instanceId: instanceId)
    }

    func configure(url: String, apiKey: String, fallbackUrl: String? = nil, orgId: String? = nil) {
        self.baseURL = Self.cleanURL(url)
        self.fallbackURL = Self.cleanURL(fallbackUrl ?? "")
        self.apiKey = Self.cleanToken(apiKey)
        self.scopedOrgId = orgId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func ping() async -> Bool {
        guard !baseURL.isEmpty else { return false }
        let pingPath = isOrgScoped ? "/v1/org/\(scopedOrgId)/sites?pageSize=1&page=1" : "/v1/orgs"
        let primary = await engine.pingURL("\(baseURL)\(pingPath)", extraHeaders: authHeaders())
        if primary { return true }
        guard !fallbackURL.isEmpty else { return false }
        return await engine.pingURL("\(fallbackURL)\(pingPath)", extraHeaders: authHeaders())
    }

    func authenticate(url: String, apiKey: String, fallbackUrl: String? = nil, orgId: String? = nil) async throws {
        let token = Self.cleanToken(apiKey)
        guard !Self.cleanURL(url).isEmpty, !token.isEmpty else {
            throw APIError.notConfigured
        }
        let cleanedOrgId = orgId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let path = cleanedOrgId.isEmpty ? "/v1/orgs" : "/v1/org/\(cleanedOrgId)/sites?pageSize=1&page=1"
        _ = try await engine.requestData(
            baseURL: Self.cleanURL(url),
            fallbackURL: Self.cleanURL(fallbackUrl ?? ""),
            path: path,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    func listOrgs() async throws -> [PangolinOrg] {
        if isOrgScoped {
            return [PangolinOrg(orgId: scopedOrgId, name: scopedOrgId, subnet: nil, utilitySubnet: nil, isBillingOrg: nil)]
        }
        let response: PangolinEnvelope<PangolinOrgListData> = try await engine.request(
            baseURL: baseURL,
            fallbackURL: fallbackURL,
            path: "/v1/orgs?limit=1000&offset=0",
            headers: authHeaders()
        )
        return response.data.orgs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func listSites(orgId: String) async throws -> [PangolinSite] {
        var collected: [PangolinSite] = []
        var page = 1

        while true {
            let response: PangolinEnvelope<PangolinSitesData> = try await request("/v1/org/\(orgId)/sites?pageSize=100&page=\(page)")
            let batch = response.data.sites
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            if total > 0, collected.count >= total { break }
            page += 1
        }

        return collected.sorted { lhs, rhs in
            if lhs.online != rhs.online { return lhs.online && !rhs.online }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func listSiteResources(orgId: String) async throws -> [PangolinSiteResource] {
        var collected: [PangolinSiteResource] = []
        var page = 1

        while true {
            let response: PangolinEnvelope<PangolinSiteResourcesData> = try await request("/v1/org/\(orgId)/site-resources?pageSize=100&page=\(page)")
            let batch = response.data.siteResources
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            if total > 0, collected.count >= total { break }
            page += 1
        }

        return collected.sorted { lhs, rhs in
            if lhs.enabled != rhs.enabled { return lhs.enabled && !rhs.enabled }
            if lhs.siteName != rhs.siteName {
                return lhs.siteName.localizedCaseInsensitiveCompare(rhs.siteName) == .orderedAscending
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func listResources(orgId: String) async throws -> [PangolinResource] {
        var collected: [PangolinResource] = []
        var page = 1

        while true {
            let response: PangolinEnvelope<PangolinResourcesData> = try await request("/v1/org/\(orgId)/resources?pageSize=100&page=\(page)")
            let batch = response.data.resources
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            if total > 0, collected.count >= total { break }
            page += 1
        }

        return collected.sorted { lhs, rhs in
            if lhs.enabled != rhs.enabled { return lhs.enabled && !rhs.enabled }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func listClients(orgId: String) async throws -> [PangolinClient] {
        var collected: [PangolinClient] = []
        var page = 1

        while true {
            let response: PangolinEnvelope<PangolinClientsData> = try await request("/v1/org/\(orgId)/clients?pageSize=100&page=\(page)&status=active,blocked,archived")
            let batch = response.data.clients
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            if total > 0, collected.count >= total { break }
            page += 1
        }

        return collected.sorted { lhs, rhs in
            if lhs.online != rhs.online { return lhs.online && !rhs.online }
            if lhs.blocked != rhs.blocked { return !lhs.blocked && rhs.blocked }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func listDomains(orgId: String) async throws -> [PangolinDomain] {
        var collected: [PangolinDomain] = []
        var offset = 0

        while true {
            let response: PangolinEnvelope<PangolinDomainsData> = try await request("/v1/org/\(orgId)/domains?limit=1000&offset=\(offset)")
            let batch = response.data.domains
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            offset += 1000
            if total > 0, collected.count >= total { break }
        }

        return collected.sorted { lhs, rhs in
            if lhs.verified != rhs.verified { return lhs.verified && !rhs.verified }
            return lhs.baseDomain.localizedCaseInsensitiveCompare(rhs.baseDomain) == .orderedAscending
        }
    }

    func listTargets(resourceId: Int) async throws -> [PangolinTarget] {
        var collected: [PangolinTarget] = []
        var offset = 0

        while true {
            let response: PangolinEnvelope<PangolinTargetsData> = try await request("/v1/resource/\(resourceId)/targets?limit=1000&offset=\(offset)")
            let batch = response.data.targets
            if batch.isEmpty { break }
            collected.append(contentsOf: batch)
            let total = response.pagination?.total ?? 0
            offset += 1000
            if total > 0, collected.count >= total { break }
        }

        return collected.sorted { lhs, rhs in
            if lhs.enabled != rhs.enabled { return lhs.enabled && !rhs.enabled }
            if lhs.priority != rhs.priority { return (lhs.priority ?? Int.max) < (rhs.priority ?? Int.max) }
            if lhs.ip != rhs.ip { return lhs.ip.localizedCaseInsensitiveCompare(rhs.ip) == .orderedAscending }
            return lhs.port < rhs.port
        }
    }

    func fetchSnapshot(orgId: String, orgs preloadedOrgs: [PangolinOrg]? = nil) async throws -> PangolinSnapshot {
        async let sitesTask = listSites(orgId: orgId)
        async let siteResourcesTask = listSiteResources(orgId: orgId)
        async let resourcesTask = listResources(orgId: orgId)
        async let clientsTask = listClients(orgId: orgId)
        async let domainsTask = listDomains(orgId: orgId)

        let orgs: [PangolinOrg]
        if let preloadedOrgs {
            orgs = preloadedOrgs
        } else {
            orgs = try await listOrgs()
        }
        let resources = try await resourcesTask
        let targetsByResourceId = try await fetchTargetsByResource(resources)

        return try await PangolinSnapshot(
            orgs: orgs,
            selectedOrgId: orgId,
            sites: sitesTask,
            siteResources: siteResourcesTask,
            resources: resources,
            targetsByResourceId: targetsByResourceId,
            clients: clientsTask,
            domains: domainsTask
        )
    }

    func aggregateSummary() async throws -> (sites: Int, resources: Int, clients: Int) {
        let orgs = try await listOrgs()
        var sites = 0
        var resources = 0
        var clients = 0

        for org in orgs {
            async let orgSites = listSites(orgId: org.orgId)
            async let orgSiteResources = listSiteResources(orgId: org.orgId)
            async let orgResources = listResources(orgId: org.orgId)
            async let orgClients = listClients(orgId: org.orgId)

            sites += try await orgSites.count
            resources += try await orgResources.count
            resources += try await orgSiteResources.count
            clients += try await orgClients.count
        }

        return (sites, resources, clients)
    }

    private func fetchTargetsByResource(_ resources: [PangolinResource]) async throws -> [Int: [PangolinTarget]] {
        var resolved: [Int: [PangolinTarget]] = [:]
        for batch in resources.chunked(into: 4) {
            let batchPairs = try await withThrowingTaskGroup(of: (Int, [PangolinTarget]).self) { group in
                for resource in batch {
                    group.addTask {
                        (resource.resourceId, try await self.listTargets(resourceId: resource.resourceId))
                    }
                }

                var pairs: [(Int, [PangolinTarget])] = []
                for try await pair in group {
                    pairs.append(pair)
                }
                return pairs
            }

            for (resourceId, targets) in batchPairs {
                resolved[resourceId] = targets
            }
        }
        return resolved
    }

    private func request<T: Decodable>(_ path: String) async throws -> T {
        try await engine.request(
            baseURL: baseURL,
            fallbackURL: fallbackURL,
            path: path,
            headers: authHeaders()
        )
    }

    private func authHeaders() -> [String: String] {
        guard !apiKey.isEmpty else { return [:] }
        return ["Authorization": "Bearer \(apiKey)"]
    }

    private static func cleanURL(_ url: String) -> String {
        url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    }

    private static func cleanToken(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("bearer ") {
            return String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return isEmpty ? [] : [self] }
        return stride(from: 0, to: count, by: size).map { index in
            Array(self[index..<Swift.min(index + size, count)])
        }
    }
}
