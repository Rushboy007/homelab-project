import Foundation

actor WakapiAPIClient {
    private let engine: BaseNetworkEngine
    private var baseURL: String = ""
    private var fallbackURL: String = ""
    private var apiKey: String = ""

    init(instanceId: UUID) {
        self.engine = BaseNetworkEngine(serviceType: .wakapi, instanceId: instanceId)
    }

    // MARK: - Configuration

    func configure(url: String, apiKey: String, fallbackUrl: String? = nil) {
        self.baseURL = Self.cleanURL(url)
        self.fallbackURL = Self.cleanURL(fallbackUrl ?? "")
        self.apiKey = apiKey
    }

    private func authHeaders() -> [String: String] {
        let authString = Data("\(apiKey)".utf8).base64EncodedString()
        return [
            "Authorization": "Basic \(authString)",
            "Content-Type": "application/json"
        ]
    }

    // MARK: - Ping / Auth

    func ping() async -> Bool {
        guard !baseURL.isEmpty else { return false }
        let primary = await engine.pingURL("\(baseURL)/api/health")
        if primary { return true }
        guard !fallbackURL.isEmpty else { return false }
        return await engine.pingURL("\(fallbackURL)/api/health")
    }

    func authenticate(url: String, apiKey: String, fallbackUrl: String? = nil) async throws {
        let cleanURL = Self.cleanURL(url)
        let authString = Data("\(apiKey)".utf8).base64EncodedString()
        let headers = ["Authorization": "Basic \(authString)", "Content-Type": "application/json"]
        
        // Use the same explicit interval as Android for a deterministic auth check.
        _ = try await engine.requestData(
            baseURL: cleanURL,
            fallbackURL: Self.cleanURL(fallbackUrl ?? ""),
            path: "/api/summary?interval=today",
            headers: headers
        )
    }

    // MARK: - API Methods

    func getSummary(interval: String = "today", filter: WakapiSummaryFilter? = nil) async throws -> WakapiSummary {
        try await engine.request(
            baseURL: baseURL,
            fallbackURL: fallbackURL,
            path: summaryPath(interval: interval, filter: filter),
            headers: authHeaders()
        )
    }

    // MARK: - Helpers

    private static func cleanURL(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    }

    private func summaryPath(interval: String, filter: WakapiSummaryFilter?) -> String {
        var components = URLComponents()
        components.path = "/api/summary"
        var queryItems = [URLQueryItem(name: "interval", value: interval)]
        if let filter {
            queryItems.append(URLQueryItem(name: filter.dimension.queryItemName, value: filter.value))
        }
        components.queryItems = queryItems
        return components.string ?? "/api/summary?interval=\(interval)"
    }
}

// MARK: - Models

struct WakapiSummaryFilter: Equatable, Sendable {
    enum Dimension: String, Sendable {
        case project
        case language
        case editor
        case operatingSystem
        case machine
        case label

        var queryItemName: String {
            switch self {
            case .project: return "project"
            case .language: return "language"
            case .editor: return "editor"
            case .operatingSystem: return "operating_system"
            case .machine: return "machine"
            case .label: return "label"
            }
        }
    }

    let dimension: Dimension
    let value: String

    var cacheKey: String {
        "\(dimension.rawValue):\(value)"
    }
}

struct WakapiSummary: Codable, Sendable {
    let grandTotal: GrandTotal?
    let projects: [StatItem]?
    let languages: [StatItem]?
    let machines: [StatItem]?
    let operatingSystems: [StatItem]?
    let editors: [StatItem]?
    let labels: [StatItem]?
    let categories: [StatItem]?
    let branches: [StatItem]?

    enum CodingKeys: String, CodingKey {
        case grandTotal = "grand_total"
        case projects, languages, machines, editors, labels, categories, branches
        case operatingSystems = "operating_systems"
    }
}

struct GrandTotal: Codable, Sendable {
    let digital: String?
    let hours: Int?
    let minutes: Int?
    let text: String?
    let totalSeconds: Double?

    enum CodingKeys: String, CodingKey {
        case digital, hours, minutes, text
        case totalSeconds = "total_seconds"
    }
}

struct StatItem: Codable, Sendable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    let name: String?
    let totalSeconds: Double?
    let percent: Double?
    let digital: String?
    let text: String?
    let hours: Int?
    let minutes: Int?

    enum CodingKeys: String, CodingKey {
        case name, percent, digital, text, hours, minutes
        case totalSeconds = "total_seconds"
    }
}
