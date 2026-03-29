import Foundation

struct LinuxUpdateDashboardStatsResponse: Decodable, Sendable {
    let stats: LinuxUpdateDashboardStats
}

struct LinuxUpdateDashboardSystemsResponse: Decodable, Sendable {
    let systems: [LinuxUpdateSystem]
}

struct LinuxUpdateSystemDetailResponse: Decodable, Sendable {
    let system: LinuxUpdateSystem
    let updates: [LinuxUpdatePackageUpdate]
    let hiddenUpdates: [LinuxUpdatePackageUpdate]
    let history: [LinuxUpdateHistoryEntry]

    enum CodingKeys: String, CodingKey {
        case system
        case updates
        case hiddenUpdates
        case history
    }

    init(
        system: LinuxUpdateSystem,
        updates: [LinuxUpdatePackageUpdate],
        hiddenUpdates: [LinuxUpdatePackageUpdate],
        history: [LinuxUpdateHistoryEntry]
    ) {
        self.system = system
        self.updates = updates
        self.hiddenUpdates = hiddenUpdates
        self.history = history
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        system = (try? container.decode(LinuxUpdateSystem.self, forKey: .system)) ?? LinuxUpdateSystem.placeholder
        updates = (try? container.decode([LinuxUpdatePackageUpdate].self, forKey: .updates)) ?? []
        hiddenUpdates = (try? container.decode([LinuxUpdatePackageUpdate].self, forKey: .hiddenUpdates)) ?? []
        history = (try? container.decode([LinuxUpdateHistoryEntry].self, forKey: .history)) ?? []
    }
}

struct LinuxUpdateDashboardStats: Decodable, Sendable {
    let total: Int
    let upToDate: Int
    let needsUpdates: Int
    let unreachable: Int
    let checkIssues: Int
    let totalUpdates: Int
    let needsReboot: Int

    enum CodingKeys: String, CodingKey {
        case total
        case upToDate
        case needsUpdates
        case unreachable
        case checkIssues
        case totalUpdates
        case needsReboot
    }

    init(
        total: Int,
        upToDate: Int,
        needsUpdates: Int,
        unreachable: Int,
        checkIssues: Int,
        totalUpdates: Int,
        needsReboot: Int
    ) {
        self.total = total
        self.upToDate = upToDate
        self.needsUpdates = needsUpdates
        self.unreachable = unreachable
        self.checkIssues = checkIssues
        self.totalUpdates = totalUpdates
        self.needsReboot = needsReboot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = LinuxUpdateDecode.int(container, key: .total)
        upToDate = LinuxUpdateDecode.int(container, key: .upToDate)
        needsUpdates = LinuxUpdateDecode.int(container, key: .needsUpdates)
        unreachable = LinuxUpdateDecode.int(container, key: .unreachable)
        checkIssues = LinuxUpdateDecode.int(container, key: .checkIssues)
        totalUpdates = LinuxUpdateDecode.int(container, key: .totalUpdates)
        needsReboot = LinuxUpdateDecode.int(container, key: .needsReboot)
    }
}

struct LinuxUpdateLastCheckSummary: Decodable, Sendable {
    let status: String
    let error: String?
    let startedAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case error
        case startedAt
        case completedAt
    }
}

struct LinuxUpdateActiveOperation: Decodable, Sendable {
    let type: String
    let startedAt: String?
    let packageName: String?

    enum CodingKeys: String, CodingKey {
        case type
        case startedAt
        case packageName
    }
}

struct LinuxUpdateSystem: Identifiable, Decodable, Sendable {
    let id: Int
    let sortOrder: Int
    let name: String
    let hostname: String
    let osName: String?
    let osVersion: String?
    let arch: String?
    let updateCount: Int
    let securityCount: Int
    let keptBackCount: Int
    let needsReboot: Int
    let isReachable: Int
    let lastSeenAt: String?
    let lastCheck: LinuxUpdateLastCheckSummary?
    let cacheAge: String?
    let isStale: Bool
    let activeOperation: LinuxUpdateActiveOperation?
    let supportsFullUpgrade: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sortOrder
        case name
        case hostname
        case osName
        case osVersion
        case arch
        case updateCount
        case securityCount
        case keptBackCount
        case needsReboot
        case isReachable
        case lastSeenAt
        case lastCheck
        case cacheAge
        case isStale
        case activeOperation
        case supportsFullUpgrade
    }

    init(
        id: Int,
        sortOrder: Int,
        name: String,
        hostname: String,
        osName: String?,
        osVersion: String?,
        arch: String?,
        updateCount: Int,
        securityCount: Int,
        keptBackCount: Int,
        needsReboot: Int,
        isReachable: Int,
        lastSeenAt: String?,
        lastCheck: LinuxUpdateLastCheckSummary?,
        cacheAge: String?,
        isStale: Bool,
        activeOperation: LinuxUpdateActiveOperation?,
        supportsFullUpgrade: Bool
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.name = name
        self.hostname = hostname
        self.osName = osName
        self.osVersion = osVersion
        self.arch = arch
        self.updateCount = updateCount
        self.securityCount = securityCount
        self.keptBackCount = keptBackCount
        self.needsReboot = needsReboot
        self.isReachable = isReachable
        self.lastSeenAt = lastSeenAt
        self.lastCheck = lastCheck
        self.cacheAge = cacheAge
        self.isStale = isStale
        self.activeOperation = activeOperation
        self.supportsFullUpgrade = supportsFullUpgrade
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = LinuxUpdateDecode.int(container, key: .id)
        sortOrder = LinuxUpdateDecode.int(container, key: .sortOrder)
        name = (try? container.decode(String.self, forKey: .name)) ?? "System"
        hostname = (try? container.decode(String.self, forKey: .hostname)) ?? "-"
        osName = try? container.decodeIfPresent(String.self, forKey: .osName)
        osVersion = try? container.decodeIfPresent(String.self, forKey: .osVersion)
        arch = try? container.decodeIfPresent(String.self, forKey: .arch)
        updateCount = LinuxUpdateDecode.int(container, key: .updateCount)
        securityCount = LinuxUpdateDecode.int(container, key: .securityCount)
        keptBackCount = LinuxUpdateDecode.int(container, key: .keptBackCount)
        needsReboot = LinuxUpdateDecode.int(container, key: .needsReboot)
        isReachable = LinuxUpdateDecode.int(container, key: .isReachable)
        lastSeenAt = try? container.decodeIfPresent(String.self, forKey: .lastSeenAt)
        lastCheck = try? container.decodeIfPresent(LinuxUpdateLastCheckSummary.self, forKey: .lastCheck)
        cacheAge = try? container.decodeIfPresent(String.self, forKey: .cacheAge)
        isStale = LinuxUpdateDecode.bool(container, key: .isStale)
        activeOperation = try? container.decodeIfPresent(LinuxUpdateActiveOperation.self, forKey: .activeOperation)
        supportsFullUpgrade = LinuxUpdateDecode.bool(container, key: .supportsFullUpgrade)
    }

    static let placeholder = LinuxUpdateSystem(
        id: 0,
        sortOrder: 0,
        name: "System",
        hostname: "-",
        osName: nil,
        osVersion: nil,
        arch: nil,
        updateCount: 0,
        securityCount: 0,
        keptBackCount: 0,
        needsReboot: 0,
        isReachable: 0,
        lastSeenAt: nil,
        lastCheck: nil,
        cacheAge: nil,
        isStale: false,
        activeOperation: nil,
        supportsFullUpgrade: false
    )

    var needsRebootFlag: Bool {
        needsReboot == 1
    }

    var isReachableFlag: Bool? {
        switch isReachable {
        case 1: return true
        case -1: return false
        default: return nil
        }
    }

    var hasCheckIssue: Bool {
        let status = lastCheck?.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return status == "failed" || status == "warning"
    }

    var osSummary: String {
        let parts = [osName, osVersion, arch]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !parts.isEmpty { return parts.joined(separator: " • ") }
        if !hostname.isEmpty { return hostname }
        return name
    }
}

struct LinuxUpdatePackageUpdate: Identifiable, Decodable, Sendable {
    let id: Int
    let systemId: Int
    let pkgManager: String
    let packageName: String
    let currentVersion: String?
    let newVersion: String?
    let architecture: String?
    let repository: String?
    let isSecurity: Int
    let isKeptBack: Int
    let cachedAt: String?
    let active: Int
    let createdAt: String?
    let updatedAt: String?
    let lastMatchedAt: String?
    let inactiveSince: String?

    enum CodingKeys: String, CodingKey {
        case id
        case systemId
        case pkgManager
        case packageName
        case currentVersion
        case newVersion
        case architecture
        case repository
        case isSecurity
        case isKeptBack
        case cachedAt
        case active
        case createdAt
        case updatedAt
        case lastMatchedAt
        case inactiveSince
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = LinuxUpdateDecode.int(container, key: .id)
        systemId = LinuxUpdateDecode.int(container, key: .systemId)
        pkgManager = (try? container.decode(String.self, forKey: .pkgManager)) ?? ""
        packageName = (try? container.decode(String.self, forKey: .packageName)) ?? ""
        currentVersion = try? container.decodeIfPresent(String.self, forKey: .currentVersion)
        newVersion = try? container.decodeIfPresent(String.self, forKey: .newVersion)
        architecture = try? container.decodeIfPresent(String.self, forKey: .architecture)
        repository = try? container.decodeIfPresent(String.self, forKey: .repository)
        isSecurity = LinuxUpdateDecode.int(container, key: .isSecurity)
        isKeptBack = LinuxUpdateDecode.int(container, key: .isKeptBack)
        cachedAt = try? container.decodeIfPresent(String.self, forKey: .cachedAt)
        active = LinuxUpdateDecode.int(container, key: .active)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
        lastMatchedAt = try? container.decodeIfPresent(String.self, forKey: .lastMatchedAt)
        inactiveSince = try? container.decodeIfPresent(String.self, forKey: .inactiveSince)
    }

    var isSecurityFlag: Bool {
        isSecurity == 1
    }

    var isKeptBackFlag: Bool {
        isKeptBack == 1
    }
}

struct LinuxUpdateHistoryStep: Decodable, Sendable {
    let label: String?
    let pkgManager: String
    let command: String
    let output: String?
    let error: String?
    let status: String
    let startedAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case label
        case pkgManager
        case command
        case output
        case error
        case status
        case startedAt
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try? container.decodeIfPresent(String.self, forKey: .label)
        pkgManager = (try? container.decode(String.self, forKey: .pkgManager)) ?? ""
        command = (try? container.decode(String.self, forKey: .command)) ?? ""
        output = try? container.decodeIfPresent(String.self, forKey: .output)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
        status = (try? container.decode(String.self, forKey: .status)) ?? ""
        startedAt = try? container.decodeIfPresent(String.self, forKey: .startedAt)
        completedAt = try? container.decodeIfPresent(String.self, forKey: .completedAt)
    }
}

struct LinuxUpdateHistoryEntry: Identifiable, Decodable, Sendable {
    let id: Int
    let systemId: Int
    let action: String
    let pkgManager: String
    let packageCount: Int?
    let packages: String?
    let packagesList: [String]
    let command: String?
    let steps: [LinuxUpdateHistoryStep]
    let status: String
    let output: String?
    let error: String?
    let startedAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case systemId
        case action
        case pkgManager
        case packageCount
        case packages
        case packagesList
        case command
        case steps
        case status
        case output
        case error
        case startedAt
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = LinuxUpdateDecode.int(container, key: .id)
        systemId = LinuxUpdateDecode.int(container, key: .systemId)
        action = (try? container.decode(String.self, forKey: .action)) ?? ""
        pkgManager = (try? container.decode(String.self, forKey: .pkgManager)) ?? ""
        packageCount = LinuxUpdateDecode.optionalInt(container, key: .packageCount)
        packages = try? container.decodeIfPresent(String.self, forKey: .packages)
        packagesList = (try? container.decode([String].self, forKey: .packagesList)) ?? []
        command = try? container.decodeIfPresent(String.self, forKey: .command)
        steps = (try? container.decode([LinuxUpdateHistoryStep].self, forKey: .steps)) ?? []
        status = (try? container.decode(String.self, forKey: .status)) ?? ""
        output = try? container.decodeIfPresent(String.self, forKey: .output)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
        startedAt = try? container.decodeIfPresent(String.self, forKey: .startedAt)
        completedAt = try? container.decodeIfPresent(String.self, forKey: .completedAt)
    }
}

struct LinuxUpdateJobStartResponse: Decodable, Sendable {
    let status: String
    let job: String?
    let jobAlias: String?
    let id: String?
    let jobId: String?
    let error: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case job
        case jobAlias = "job_id"
        case id
        case jobId
        case error
        case message
    }

    init(
        status: String = "",
        job: String? = nil,
        jobAlias: String? = nil,
        id: String? = nil,
        jobId: String? = nil,
        error: String? = nil,
        message: String? = nil
    ) {
        self.status = status
        self.job = job
        self.jobAlias = jobAlias
        self.id = id
        self.jobId = jobId
        self.error = error
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decode(String.self, forKey: .status)) ?? ""
        job = LinuxUpdateDecode.lossyString(container, key: .job)
        jobAlias = LinuxUpdateDecode.lossyString(container, key: .jobAlias)
        id = LinuxUpdateDecode.lossyString(container, key: .id)
        jobId = try? container.decodeIfPresent(String.self, forKey: .jobId)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
    }

    var resolvedJobId: String? {
        let candidates = [jobId, job, jobAlias, id]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return candidates.first
    }
}

struct LinuxUpdateJobResult: Decodable, Sendable {
    let status: String?
    let output: String?
    let message: String?
    let error: String?
    let packageName: String?

    enum CodingKeys: String, CodingKey {
        case status
        case output
        case message
        case error
        case packageName = "package"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        output = try? container.decodeIfPresent(String.self, forKey: .output)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
        packageName = try? container.decodeIfPresent(String.self, forKey: .packageName)
    }
}

struct LinuxUpdateJobStatusResponse: Decodable, Sendable {
    let status: String
    let result: LinuxUpdateJobResult?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case status
        case result
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decode(String.self, forKey: .status)) ?? ""
        result = try? container.decodeIfPresent(LinuxUpdateJobResult.self, forKey: .result)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
    }
}

struct LinuxUpdateRebootResponse: Decodable, Sendable {
    let success: Bool
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = LinuxUpdateDecode.bool(container, key: .success)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        error = try? container.decodeIfPresent(String.self, forKey: .error)
    }
}

private enum LinuxUpdateDecode {
    static func int<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(Double.self, forKey: key) { return Int(value) }
        if let value = try? container.decode(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if let parsed = Int(trimmed) { return parsed }
            if let parsedDouble = Double(trimmed) { return Int(parsedDouble) }
            if trimmed.lowercased() == "true" { return 1 }
            if trimmed.lowercased() == "false" { return 0 }
        }
        return 0
    }

    static func optionalInt<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.lowercased() == "null" { return nil }
            if let parsed = Int(trimmed) { return parsed }
            if let parsedDouble = Double(trimmed) { return Int(parsedDouble) }
        }
        return nil
    }

    static func bool<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return value != 0 }
        if let value = try? container.decode(Double.self, forKey: key) { return value != 0 }
        if let value = try? container.decode(String.self, forKey: key) {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes": return true
            case "false", "0", "no": return false
            default: return false
            }
        }
        return false
    }

    static func lossyString<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }
}
