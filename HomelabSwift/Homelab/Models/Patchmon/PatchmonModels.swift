import Foundation

struct PatchmonHostsResponse: Codable {
    let hosts: [PatchmonHost]
    let total: Int?
    let filteredByGroups: [String]?

    enum CodingKeys: String, CodingKey {
        case hosts
        case total
        case filteredByGroups = "filtered_by_groups"
    }
}

struct PatchmonHost: Codable, Identifiable, Hashable {
    let id: String
    let friendlyName: String
    let hostname: String
    let ip: String
    let hostGroups: [PatchmonHostGroup]
    let osType: String
    let osVersion: String
    let lastUpdate: String?
    let status: String
    let needsReboot: Bool
    let updatesCount: Int
    let securityUpdatesCount: Int
    let totalPackages: Int

    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case hostname
        case ip
        case hostGroups = "host_groups"
        case osType = "os_type"
        case osVersion = "os_version"
        case lastUpdate = "last_update"
        case status
        case needsReboot = "needs_reboot"
        case updatesCount = "updates_count"
        case securityUpdatesCount = "security_updates_count"
        case totalPackages = "total_packages"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        friendlyName = (try? container.decode(String.self, forKey: .friendlyName)) ?? "Unknown Host"
        hostname = (try? container.decode(String.self, forKey: .hostname)) ?? ""
        ip = (try? container.decode(String.self, forKey: .ip)) ?? ""
        hostGroups = (try? container.decode([PatchmonHostGroup].self, forKey: .hostGroups)) ?? []
        osType = (try? container.decode(String.self, forKey: .osType)) ?? ""
        osVersion = (try? container.decode(String.self, forKey: .osVersion)) ?? ""
        lastUpdate = try? container.decodeIfPresent(String.self, forKey: .lastUpdate)
        status = (try? container.decode(String.self, forKey: .status)) ?? "unknown"
        needsReboot = (try? container.decode(Bool.self, forKey: .needsReboot)) ?? false
        updatesCount = (try? container.decode(Int.self, forKey: .updatesCount)) ?? 0
        securityUpdatesCount = (try? container.decode(Int.self, forKey: .securityUpdatesCount)) ?? 0
        totalPackages = (try? container.decode(Int.self, forKey: .totalPackages)) ?? 0
    }

    var displayName: String {
        let candidate = friendlyName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.isEmpty { return candidate }
        let host = hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !host.isEmpty { return host }
        return id
    }

    var isActive: Bool {
        status.lowercased() == "active"
    }
}

struct PatchmonHostGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeLossyString(forKey: .id) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
    }
}

// MARK: - Host Detail

struct PatchmonHostInfo: Codable {
    let id: String
    let machineId: String?
    let friendlyName: String
    let hostname: String
    let ip: String
    let osType: String
    let osVersion: String
    let agentVersion: String?
    let hostGroups: [PatchmonHostGroup]

    enum CodingKeys: String, CodingKey {
        case id
        case machineId = "machine_id"
        case friendlyName = "friendly_name"
        case hostname
        case ip
        case osType = "os_type"
        case osVersion = "os_version"
        case agentVersion = "agent_version"
        case hostGroups = "host_groups"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        machineId = c.decodeLossyString(forKey: .machineId)
        friendlyName = (try? c.decode(String.self, forKey: .friendlyName)) ?? ""
        hostname = (try? c.decode(String.self, forKey: .hostname)) ?? ""
        ip = (try? c.decode(String.self, forKey: .ip)) ?? ""
        osType = (try? c.decode(String.self, forKey: .osType)) ?? ""
        osVersion = (try? c.decode(String.self, forKey: .osVersion)) ?? ""
        agentVersion = c.decodeLossyString(forKey: .agentVersion)
        hostGroups = (try? c.decode([PatchmonHostGroup].self, forKey: .hostGroups)) ?? []
    }
}

struct PatchmonHostStats: Codable {
    let hostId: String
    let totalInstalledPackages: Int
    let outdatedPackages: Int
    let securityUpdates: Int
    let totalRepos: Int

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case totalInstalledPackages = "total_installed_packages"
        case outdatedPackages = "outdated_packages"
        case securityUpdates = "security_updates"
        case totalRepos = "total_repos"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hostId = c.decodeLossyString(forKey: .hostId) ?? ""
        totalInstalledPackages = c.decodeLossyInt(forKey: .totalInstalledPackages) ?? 0
        outdatedPackages = c.decodeLossyInt(forKey: .outdatedPackages) ?? 0
        securityUpdates = c.decodeLossyInt(forKey: .securityUpdates) ?? 0
        totalRepos = c.decodeLossyInt(forKey: .totalRepos) ?? 0
    }
}

struct PatchmonHostSystem: Codable {
    let id: String
    let architecture: String?
    let kernelVersion: String?
    let installedKernelVersion: String?
    let selinuxStatus: String?
    let systemUptime: String?
    let cpuModel: String?
    let cpuCores: Int?
    let ramInstalled: String?
    let swapSize: String?
    let loadAverage: PatchmonLoadAverage?
    let diskDetails: [PatchmonDiskDetail]
    let needsReboot: Bool
    let rebootReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case architecture
        case kernelVersion = "kernel_version"
        case installedKernelVersion = "installed_kernel_version"
        case selinuxStatus = "selinux_status"
        case systemUptime = "system_uptime"
        case cpuModel = "cpu_model"
        case cpuCores = "cpu_cores"
        case ramInstalled = "ram_installed"
        case swapSize = "swap_size"
        case loadAverage = "load_average"
        case diskDetails = "disk_details"
        case needsReboot = "needs_reboot"
        case rebootReason = "reboot_reason"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? ""
        architecture = c.decodeLossyString(forKey: .architecture)
        kernelVersion = c.decodeLossyString(forKey: .kernelVersion)
        installedKernelVersion = c.decodeLossyString(forKey: .installedKernelVersion)
        selinuxStatus = c.decodeLossyString(forKey: .selinuxStatus)
        systemUptime = c.decodeLossyString(forKey: .systemUptime)
        cpuModel = c.decodeLossyString(forKey: .cpuModel)
        cpuCores = c.decodeLossyInt(forKey: .cpuCores)
        ramInstalled = c.decodeLossyString(forKey: .ramInstalled)
        swapSize = c.decodeLossyString(forKey: .swapSize)
        loadAverage = try? c.decodeIfPresent(PatchmonLoadAverage.self, forKey: .loadAverage)
        diskDetails = (try? c.decode([PatchmonDiskDetail].self, forKey: .diskDetails)) ?? []
        needsReboot = c.decodeLossyBool(forKey: .needsReboot) ?? false
        rebootReason = c.decodeLossyString(forKey: .rebootReason)
    }
}

struct PatchmonLoadAverage: Codable, Hashable {
    let oneMinute: Double
    let fiveMinutes: Double
    let fifteenMinutes: Double

    enum CodingKeys: String, CodingKey {
        case oneMinute = "1min"
        case fiveMinutes = "5min"
        case fifteenMinutes = "15min"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        oneMinute = c.decodeLossyDouble(forKey: .oneMinute) ?? 0
        fiveMinutes = c.decodeLossyDouble(forKey: .fiveMinutes) ?? 0
        fifteenMinutes = c.decodeLossyDouble(forKey: .fifteenMinutes) ?? 0
    }
}

struct PatchmonDiskDetail: Codable, Hashable, Identifiable {
    let id: String
    let filesystem: String
    let size: String
    let used: String
    let available: String
    let usePercent: String
    let mountedOn: String

    enum CodingKeys: String, CodingKey {
        case filesystem
        case size
        case used
        case available
        case usePercent = "use_percent"
        case mountedOn = "mounted_on"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        filesystem = c.decodeLossyString(forKey: .filesystem) ?? ""
        size = c.decodeLossyString(forKey: .size) ?? ""
        used = c.decodeLossyString(forKey: .used) ?? ""
        available = c.decodeLossyString(forKey: .available) ?? ""
        usePercent = c.decodeLossyString(forKey: .usePercent) ?? ""
        mountedOn = c.decodeLossyString(forKey: .mountedOn) ?? ""
        id = [filesystem, mountedOn].joined(separator: "@")
    }
}

struct PatchmonHostNetwork: Codable {
    let id: String
    let ip: String
    let gatewayIP: String?
    let dnsServers: [String]
    let networkInterfaces: [PatchmonNetworkInterface]

    enum CodingKeys: String, CodingKey {
        case id
        case ip
        case gatewayIP = "gateway_ip"
        case dnsServers = "dns_servers"
        case networkInterfaces = "network_interfaces"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? ""
        ip = c.decodeLossyString(forKey: .ip) ?? ""
        gatewayIP = c.decodeLossyString(forKey: .gatewayIP)
        dnsServers = (try? c.decode([String].self, forKey: .dnsServers)) ?? []
        networkInterfaces = (try? c.decode([PatchmonNetworkInterface].self, forKey: .networkInterfaces)) ?? []
    }
}

struct PatchmonNetworkInterface: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let ip: String
    let mac: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.decodeLossyString(forKey: .name) ?? ""
        ip = c.decodeLossyString(forKey: .ip) ?? ""
        mac = c.decodeLossyString(forKey: .mac) ?? ""
        id = [name, ip, mac].joined(separator: "|")
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case ip
        case mac
    }
}

struct PatchmonPackagesResponse: Codable {
    let host: PatchmonPackageHost?
    let packages: [PatchmonPackage]
    let total: Int

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        host = try? c.decodeIfPresent(PatchmonPackageHost.self, forKey: .host)
        packages = (try? c.decode([PatchmonPackage].self, forKey: .packages)) ?? []
        total = c.decodeLossyInt(forKey: .total) ?? packages.count
    }

    private enum CodingKeys: String, CodingKey {
        case host
        case packages
        case total
    }
}

struct PatchmonPackageHost: Codable, Hashable {
    let id: String
    let hostname: String
    let friendlyName: String

    enum CodingKeys: String, CodingKey {
        case id
        case hostname
        case friendlyName = "friendly_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? ""
        hostname = c.decodeLossyString(forKey: .hostname) ?? ""
        friendlyName = c.decodeLossyString(forKey: .friendlyName) ?? ""
    }
}

struct PatchmonPackage: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let currentVersion: String?
    let availableVersion: String?
    let needsUpdate: Bool
    let isSecurityUpdate: Bool
    let lastChecked: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case currentVersion = "current_version"
        case availableVersion = "available_version"
        case needsUpdate = "needs_update"
        case isSecurityUpdate = "is_security_update"
        case lastChecked = "last_checked"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        name = c.decodeLossyString(forKey: .name) ?? ""
        description = c.decodeLossyString(forKey: .description)
        category = c.decodeLossyString(forKey: .category)
        currentVersion = c.decodeLossyString(forKey: .currentVersion)
        availableVersion = c.decodeLossyString(forKey: .availableVersion)
        needsUpdate = c.decodeLossyBool(forKey: .needsUpdate) ?? false
        isSecurityUpdate = c.decodeLossyBool(forKey: .isSecurityUpdate) ?? false
        lastChecked = c.decodeLossyString(forKey: .lastChecked)
    }
}

struct PatchmonReportsResponse: Codable {
    let hostId: String
    let reports: [PatchmonPackageReport]
    let total: Int

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case reports
        case total
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hostId = c.decodeLossyString(forKey: .hostId) ?? ""
        reports = (try? c.decode([PatchmonPackageReport].self, forKey: .reports)) ?? []
        total = c.decodeLossyInt(forKey: .total) ?? reports.count
    }
}

struct PatchmonPackageReport: Codable, Hashable, Identifiable {
    let id: String
    let status: String
    let date: String?
    let totalPackages: Int
    let outdatedPackages: Int
    let securityUpdates: Int
    let payloadKB: Double?
    let executionTimeSeconds: Double?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case date
        case totalPackages = "total_packages"
        case outdatedPackages = "outdated_packages"
        case securityUpdates = "security_updates"
        case payloadKB = "payload_kb"
        case executionTimeSeconds = "execution_time_seconds"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        status = c.decodeLossyString(forKey: .status) ?? ""
        date = c.decodeLossyString(forKey: .date)
        totalPackages = c.decodeLossyInt(forKey: .totalPackages) ?? 0
        outdatedPackages = c.decodeLossyInt(forKey: .outdatedPackages) ?? 0
        securityUpdates = c.decodeLossyInt(forKey: .securityUpdates) ?? 0
        payloadKB = c.decodeLossyDouble(forKey: .payloadKB)
        executionTimeSeconds = c.decodeLossyDouble(forKey: .executionTimeSeconds)
        errorMessage = c.decodeLossyString(forKey: .errorMessage)
    }
}

struct PatchmonAgentQueueResponse: Codable {
    let hostId: String
    let queueStatus: PatchmonQueueStatus
    let jobHistory: [PatchmonAgentJob]
    let totalJobs: Int

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case queueStatus = "queue_status"
        case jobHistory = "job_history"
        case totalJobs = "total_jobs"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hostId = c.decodeLossyString(forKey: .hostId) ?? ""
        queueStatus = (try? c.decode(PatchmonQueueStatus.self, forKey: .queueStatus)) ?? .init(waiting: 0, active: 0, delayed: 0, failed: 0)
        jobHistory = (try? c.decode([PatchmonAgentJob].self, forKey: .jobHistory)) ?? []
        totalJobs = c.decodeLossyInt(forKey: .totalJobs) ?? jobHistory.count
    }
}

struct PatchmonQueueStatus: Codable, Hashable {
    let waiting: Int
    let active: Int
    let delayed: Int
    let failed: Int

    init(waiting: Int, active: Int, delayed: Int, failed: Int) {
        self.waiting = waiting
        self.active = active
        self.delayed = delayed
        self.failed = failed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        waiting = c.decodeLossyInt(forKey: .waiting) ?? 0
        active = c.decodeLossyInt(forKey: .active) ?? 0
        delayed = c.decodeLossyInt(forKey: .delayed) ?? 0
        failed = c.decodeLossyInt(forKey: .failed) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case waiting
        case active
        case delayed
        case failed
    }
}

struct PatchmonAgentJob: Codable, Hashable, Identifiable {
    let id: String
    let jobId: String?
    let jobName: String
    let status: String
    let attempt: Int
    let createdAt: String?
    let completedAt: String?
    let errorMessage: String?
    let output: String?

    enum CodingKeys: String, CodingKey {
        case id
        case jobId = "job_id"
        case jobName = "job_name"
        case status
        case attempt
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case errorMessage = "error_message"
        case output
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeLossyString(forKey: .id) ?? UUID().uuidString
        jobId = c.decodeLossyString(forKey: .jobId)
        jobName = c.decodeLossyString(forKey: .jobName) ?? ""
        status = c.decodeLossyString(forKey: .status) ?? ""
        attempt = c.decodeLossyInt(forKey: .attempt) ?? 0
        createdAt = c.decodeLossyString(forKey: .createdAt)
        completedAt = c.decodeLossyString(forKey: .completedAt)
        errorMessage = c.decodeLossyString(forKey: .errorMessage)
        output = c.decodeLossyString(forKey: .output)
    }
}

struct PatchmonNotesResponse: Codable {
    let hostId: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hostId = c.decodeLossyString(forKey: .hostId) ?? ""
        notes = c.decodeLossyString(forKey: .notes)
    }
}

struct PatchmonIntegrationsResponse: Codable {
    let hostId: String
    let integrations: [String: PatchmonIntegrationStatus]

    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case integrations
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hostId = c.decodeLossyString(forKey: .hostId) ?? ""
        integrations = (try? c.decode([String: PatchmonIntegrationStatus].self, forKey: .integrations)) ?? [:]
    }
}

struct PatchmonIntegrationStatus: Codable, Hashable {
    let enabled: Bool
    let containersCount: Int?
    let volumesCount: Int?
    let networksCount: Int?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case enabled
        case containersCount = "containers_count"
        case volumesCount = "volumes_count"
        case networksCount = "networks_count"
        case description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = c.decodeLossyBool(forKey: .enabled) ?? false
        containersCount = c.decodeLossyInt(forKey: .containersCount)
        volumesCount = c.decodeLossyInt(forKey: .volumesCount)
        networksCount = c.decodeLossyInt(forKey: .networksCount)
        description = c.decodeLossyString(forKey: .description)
    }
}

struct PatchmonDeleteResponse: Codable {
    let message: String?
    let deleted: PatchmonDeletedHost?
}

struct PatchmonDeletedHost: Codable, Hashable {
    let id: String
    let friendlyName: String?
    let hostname: String?

    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case hostname
    }
}

// MARK: - Lossy Decoding Helpers

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Bool.self, forKey: key) {
            return value ? "true" : "false"
        }
        if let object = try? decodeIfPresent([String: String].self, forKey: key),
           let data = try? JSONSerialization.data(withJSONObject: object, options: []),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        if let array = try? decodeIfPresent([String].self, forKey: key) {
            return array.joined(separator: ", ")
        }
        return nil
    }

    func decodeLossyInt(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        return nil
    }

    func decodeLossyDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }

    func decodeLossyBool(forKey key: Key) -> Bool? {
        if let value = try? decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            switch value.lowercased() {
            case "1", "true", "yes", "on":
                return true
            case "0", "false", "no", "off":
                return false
            default:
                return nil
            }
        }
        return nil
    }
}
