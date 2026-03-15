import Foundation

actor NginxProxyManagerAPIClient {
    private let engine: BaseNetworkEngine
    private var baseURL: String = ""
    private var fallbackURL: String = ""
    private var token: String = ""

    init(instanceId: UUID) {
        self.engine = BaseNetworkEngine(serviceType: .nginxProxyManager, instanceId: instanceId)
    }

    // MARK: - Configuration

    func configure(url: String, token: String, fallbackUrl: String? = nil) {
        self.baseURL = Self.cleanURL(url)
        self.fallbackURL = Self.cleanURL(fallbackUrl ?? "")
        self.token = token
    }

    private func authHeaders() -> [String: String] {
        ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
    }

    // MARK: - Ping

    func ping() async -> Bool {
        if baseURL.isEmpty { return false }
        if await engine.pingURL("\(baseURL)/api/", extraHeaders: [:]) { return true }
        if !fallbackURL.isEmpty {
            return await engine.pingURL("\(fallbackURL)/api/", extraHeaders: [:])
        }
        return false
    }

    // MARK: - Authentication

    func authenticate(url: String, email: String, password: String) async throws -> String {
        let cleanURL = Self.cleanURL(url)
        guard let authURL = URL(string: "\(cleanURL)/api/tokens") else {
            throw APIError.invalidURL
        }

        let body = try JSONEncoder().encode(["identity": email, "secret": password])
        var req = URLRequest(url: authURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        req.timeoutInterval = 8

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.custom("Authentication failed. Check your email and password.")
        }

        let decoded = try JSONDecoder().decode(NpmTokenResponse.self, from: data)
        let resolvedToken = decoded.resolvedToken
        guard !resolvedToken.isEmpty else {
            throw APIError.custom("Authentication failed. Empty token received.")
        }
        return resolvedToken
    }

    // MARK: - Host Report

    func getHostReport() async throws -> NpmHostReport {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/reports/hosts",
            headers: authHeaders()
        )
    }

    // MARK: - Proxy Hosts

    func getProxyHosts() async throws -> [NpmProxyHost] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts?expand=certificate",
            headers: authHeaders()
        )
    }

    func createProxyHost(_ request: NpmProxyHostRequest) async throws -> NpmProxyHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func updateProxyHost(id: Int, _ request: NpmProxyHostRequest) async throws -> NpmProxyHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteProxyHost(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    func enableProxyHost(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts/\(id)/enable",
            method: "POST",
            headers: authHeaders()
        )
    }

    func disableProxyHost(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/proxy-hosts/\(id)/disable",
            method: "POST",
            headers: authHeaders()
        )
    }

    // MARK: - Redirection Hosts

    func getRedirectionHosts() async throws -> [NpmRedirectionHost] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/redirection-hosts?expand=certificate",
            headers: authHeaders()
        )
    }

    func createRedirectionHost(_ request: NpmRedirectionHostRequest) async throws -> NpmRedirectionHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/redirection-hosts",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func updateRedirectionHost(id: Int, _ request: NpmRedirectionHostRequest) async throws -> NpmRedirectionHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/redirection-hosts/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteRedirectionHost(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/redirection-hosts/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    // MARK: - Streams

    func getStreams() async throws -> [NpmStream] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/streams",
            headers: authHeaders()
        )
    }

    func createStream(_ request: NpmStreamRequest) async throws -> NpmStream {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/streams",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func updateStream(id: Int, _ request: NpmStreamRequest) async throws -> NpmStream {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/streams/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteStream(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/streams/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    // MARK: - Dead Hosts

    func getDeadHosts() async throws -> [NpmDeadHost] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/dead-hosts",
            headers: authHeaders()
        )
    }

    func createDeadHost(_ request: NpmDeadHostRequest) async throws -> NpmDeadHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/dead-hosts",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func updateDeadHost(id: Int, _ request: NpmDeadHostRequest) async throws -> NpmDeadHost {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/dead-hosts/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteDeadHost(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/dead-hosts/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    // MARK: - Certificates

    func getCertificates() async throws -> [NpmCertificate] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/certificates",
            headers: authHeaders()
        )
    }

    func createCertificate(_ request: NpmCertificateRequest) async throws -> NpmCertificate {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/certificates",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteCertificate(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/certificates/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    func renewCertificate(id: Int) async throws -> NpmCertificate {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/certificates/\(id)/renew",
            method: "POST",
            headers: authHeaders()
        )
    }

    // MARK: - Access Lists

    func getAccessLists() async throws -> [NpmAccessList] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/access-lists?expand=items,clients",
            headers: authHeaders()
        )
    }

    // MARK: - Users / Audit Logs / Settings

    func getUsers() async throws -> [NpmUser] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/users",
            headers: authHeaders()
        )
    }

    func createUser(_ request: NpmUserRequest) async throws -> NpmUser {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/users",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func updateUser(id: Int, _ request: NpmUserRequest) async throws -> NpmUser {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/users/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }

    func deleteUser(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/users/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    func getAuditLogs() async throws -> [NpmAuditLog] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/audit-log",
            headers: authHeaders()
        )
    }

    func getSettings() async throws -> [NpmSetting] {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/settings",
            headers: authHeaders()
        )
    }
    
    func createAccessList(_ request: NpmAccessListRequest) async throws -> NpmAccessList {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/access-lists",
            method: "POST",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }
    
    func updateAccessList(id: Int, _ request: NpmAccessListRequest) async throws -> NpmAccessList {
        return try await engine.request(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/access-lists/\(id)",
            method: "PUT",
            headers: authHeaders(),
            body: try request.toJSONData()
        )
    }
    
    func deleteAccessList(id: Int) async throws {
        try await engine.requestVoid(
            baseURL: baseURL, fallbackURL: fallbackURL,
            path: "/api/nginx/access-lists/\(id)",
            method: "DELETE",
            headers: authHeaders()
        )
    }

    // MARK: - Helpers

    private static func cleanURL(_ url: String) -> String {
        url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    }
}
