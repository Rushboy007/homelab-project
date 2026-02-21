import Foundation
import Observation

@Observable
@MainActor
final class ServicesStore {

    // MARK: - State (mirrors useServicesStore.ts)

    private(set) var connections: [ServiceType: ServiceConnection] = [:]
    private(set) var isReady: Bool = false
    private(set) var reachability: [ServiceType: Bool?] = [:]  // nil = checking, true = up, false = down
    private(set) var pinging: [ServiceType: Bool] = [:]

    /// Tracks last reachability check time to debounce rapid checks
    private var lastReachabilityCheck: Date?

    /// Periodic health check task (runs every 30 seconds while app is active)
    private var healthCheckTask: Task<Void, Never>?

    // MARK: - API Clients (one per service)

    let portainerClient = PortainerAPIClient()
    let piholeClient = PiHoleAPIClient()
    let beszelClient = BeszelAPIClient()
    let giteaClient = GiteaAPIClient()

    // MARK: - Computed

    var connectedCount: Int { connections.count }

    func isConnected(_ type: ServiceType) -> Bool { connections[type] != nil }

    func isReachable(_ type: ServiceType) -> Bool? {
        guard connections[type] != nil else { return nil }
        return reachability[type] ?? nil
    }

    func isPinging(_ type: ServiceType) -> Bool { pinging[type] ?? false }

    func connection(for type: ServiceType) -> ServiceConnection? { connections[type] }

    // MARK: - Init: listen for 401 notifications

    init() {
        NotificationCenter.default.addObserver(
            forName: .serviceUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let serviceType = notification.userInfo?["serviceType"] as? ServiceType {
                Task { @MainActor in
                    self?.disconnectService(serviceType)
                }
            }
        }
    }

    // MARK: - Initialize (mirrors init() in useServicesStore.ts)

    func initialize() async {
        let saved = KeychainService.loadConnections()
        connections = saved

        // Configure API clients
        for (type, conn) in saved {
            await configureClient(for: type, with: conn)
        }

        // Set initial reachability to nil (checking)
        for type in saved.keys {
            reachability[type] = nil
        }

        isReady = true

        // Fire-and-forget health checks
        Task {
            await checkAllReachability()
        }

        // Start periodic health checks (every 30 seconds)
        startPeriodicHealthChecks()
    }

    // MARK: - Connect (mirrors connectService)

    func connectService(_ connection: ServiceConnection) async {
        connections[connection.type] = connection
        await configureClient(for: connection.type, with: connection)
        KeychainService.saveConnections(connections)
        reachability[connection.type] = nil
        Task { await checkReachability(for: connection.type) }
    }

    // MARK: - Disconnect (mirrors disconnectService)

    func disconnectService(_ type: ServiceType) {
        connections.removeValue(forKey: type)
        reachability.removeValue(forKey: type)
        pinging.removeValue(forKey: type)
        KeychainService.saveConnections(connections)
    }

    // MARK: - Update fallback URL

    func updateFallbackURL(for type: ServiceType, fallbackUrl: String) async {
        guard var conn = connections[type] else { return }
        conn = ServiceConnection(
            type: type,
            url: conn.url,
            token: conn.token,
            username: conn.username,
            apiKey: conn.apiKey,
            fallbackUrl: fallbackUrl.isEmpty ? nil : fallbackUrl
        )
        connections[type] = conn
        await configureClient(for: type, with: conn)
        KeychainService.saveConnections(connections)
    }

    // MARK: - Reachability

    func checkReachability(for type: ServiceType) async {
        pinging[type] = true
        reachability[type] = nil
        defer { pinging[type] = false }

        let ok: Bool
        switch type {
        case .portainer: ok = await portainerClient.ping()
        case .pihole:    ok = await piholeClient.ping()
        case .beszel:    ok = await beszelClient.ping()
        case .gitea:     ok = await giteaClient.ping()
        }

        reachability[type] = ok
    }

    func checkAllReachability() async {
        // Debounce: don't check if we already checked within last 5 seconds
        if let last = lastReachabilityCheck, Date().timeIntervalSince(last) < 5 {
            return
        }
        lastReachabilityCheck = Date()

        let types = Array(connections.keys)
        guard !types.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for type in types {
                group.addTask { await self.checkReachability(for: type) }
            }
        }
    }

    // MARK: - Periodic Health Checks

    /// Start periodic health checks that run every 30 seconds.
    /// Lightweight — only sends ping requests (3-second timeout each).
    /// Automatically detects when services go offline (e.g., leaving home network).
    func startPeriodicHealthChecks() {
        healthCheckTask?.cancel()
        healthCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                await self?.checkAllReachability()
            }
        }
    }

    /// Stop periodic health checks (e.g., when app goes to background).
    func stopPeriodicHealthChecks() {
        healthCheckTask?.cancel()
        healthCheckTask = nil
    }

    // MARK: - Private: configure clients

    private func configureClient(for type: ServiceType, with conn: ServiceConnection) async {
        switch type {
        case .portainer:
            if let apiKey = conn.apiKey, !apiKey.isEmpty {
                await portainerClient.configureWithApiKey(url: conn.url, apiKey: apiKey, fallbackUrl: conn.fallbackUrl)
            } else {
                await portainerClient.configure(url: conn.url, jwt: conn.token, fallbackUrl: conn.fallbackUrl)
            }
        case .pihole:
            await piholeClient.configure(url: conn.url, sid: conn.token, fallbackUrl: conn.fallbackUrl)
        case .beszel:
            await beszelClient.configure(url: conn.url, token: conn.token, fallbackUrl: conn.fallbackUrl)
        case .gitea:
            await giteaClient.configure(url: conn.url, token: conn.token, fallbackUrl: conn.fallbackUrl)
        }
    }
}
