import Foundation

struct BeszelSystem: Codable, Identifiable {
    let id: String
    let collectionId: String?
    let collectionName: String?
    let name: String
    let host: String
    var port: Int?
    let status: String
    let info: BeszelSystemInfo?
    let created: String?
    let updated: String?

    var isOnline: Bool { status == "up" }

    enum CodingKeys: String, CodingKey {
        case id, collectionId, collectionName, name, host, port, status, info, created, updated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
        collectionName = try container.decodeIfPresent(String.self, forKey: .collectionName)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)

        if let p = try? container.decodeIfPresent(Int.self, forKey: .port) {
            port = p
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .port) {
            port = Int(s)
        }

        status = try container.decode(String.self, forKey: .status)
        info = try container.decodeIfPresent(BeszelSystemInfo.self, forKey: .info)
        created = try container.decodeIfPresent(String.self, forKey: .created)
        updated = try container.decodeIfPresent(String.self, forKey: .updated)
    }
}

struct BeszelSystemInfo: Codable {
    // All fields optional with defaults — API may omit fields for offline systems
    let cpu: Double?
    let mp: Double?       // Memory %
    let m: Double?        // Memory used (GB)
    let mt: Double?       // Memory total (GB)
    let dp: Double?       // Disk %
    let d: Double?        // Disk used (GB)
    let dt: Double?       // Disk total (GB)
    let ns: Double?       // Network sent (MB/s)
    let nr: Double?       // Network received (MB/s)
    let u: Double?        // Uptime (seconds)
    let cm: String?       // CPU model
    let os: String?       // Operating system
    let k: String?        // Kernel
    let h: String?        // Hostname
    let t: Double?        // Temperature
    let c: Int?           // CPU cores

    // Safe accessors with defaults
    var cpuValue: Double { cpu ?? 0 }
    var mpValue: Double { mp ?? 0 }
    var mValue: Double { m ?? 0 }
    var mtValue: Double { mt ?? 0 }
    var dpValue: Double { dp ?? 0 }
    var dValue: Double { d ?? 0 }
    var dtValue: Double { dt ?? 0 }
    var nsValue: Double { ns ?? 0 }
    var nrValue: Double { nr ?? 0 }
    var uValue: Double { u ?? 0 }

    static let empty = BeszelSystemInfo(cpu: nil, mp: nil, m: nil, mt: nil, dp: nil, d: nil, dt: nil, ns: nil, nr: nil, u: nil, cm: nil, os: nil, k: nil, h: nil, t: nil, c: nil)
}

struct BeszelSystemsResponse: Codable {
    let items: [BeszelSystem]
    let totalItems: Int?
    let page: Int?
    let perPage: Int?
}

struct BeszelSystemRecord: Codable, Identifiable {
    let id: String
    let system: String?
    let stats: BeszelRecordStats
    let created: String?
    let updated: String?
}

struct BeszelRecordStats: Codable {
    let cpu: Double?
    let mp: Double?
    let m: Double?
    let mt: Double?
    let dp: Double?
    let d: Double?
    let dt: Double?
    let ns: Double?
    let nr: Double?
    let t: [Double]?     // Temperature array
    let dc: [BeszelContainer]? // Docker containers

    var cpuValue: Double { cpu ?? 0 }
    var mpValue: Double { mp ?? 0 }
    var mValue: Double { m ?? 0 }
    var mtValue: Double { mt ?? 0 }
    var dpValue: Double { dp ?? 0 }
    var dValue: Double { d ?? 0 }
    var dtValue: Double { dt ?? 0 }
    var nsValue: Double { ns ?? 0 }
    var nrValue: Double { nr ?? 0 }
}

struct BeszelContainer: Codable, Identifiable {
    let n: String       // name
    let cpu: Double?    // CPU %
    let m: Double?      // Memory (MB)

    var id: String { n }
    var name: String { n }
    var cpuValue: Double { cpu ?? 0 }
    var mValue: Double { m ?? 0 }
}

struct BeszelRecordsResponse: Codable {
    let items: [BeszelSystemRecord]
    let totalItems: Int?
    let page: Int?
    let perPage: Int?
}

// MARK: - Auth

struct BeszelAuthResponse: Codable {
    let token: String
    let record: BeszelUserRecord?
}

struct BeszelUserRecord: Codable {
    let id: String
    let email: String?
    let username: String?
}
