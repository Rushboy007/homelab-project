import Foundation

enum PiHoleAuthMode: String, Codable, Equatable {
    case session
    case legacy
}

struct ServiceInstance: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let type: ServiceType
    var label: String
    var url: String
    var token: String
    var username: String?
    var apiKey: String?
    var piholePassword: String?
    var piholeAuthMode: PiHoleAuthMode?
    var fallbackUrl: String?
    var allowSelfSigned: Bool
    var password: String?

    init(
        id: UUID = UUID(),
        type: ServiceType,
        label: String,
        url: String,
        token: String = "",
        username: String? = nil,
        apiKey: String? = nil,
        piholePassword: String? = nil,
        piholeAuthMode: PiHoleAuthMode? = nil,
        fallbackUrl: String? = nil,
        allowSelfSigned: Bool = false,
        password: String? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? type.displayName : label.trimmingCharacters(in: .whitespacesAndNewlines)
        self.url = Self.cleanURL(url)
        self.token = token
        self.username = username?.trimmedNilIfEmpty
        self.apiKey = apiKey?.trimmedNilIfEmpty
        self.piholePassword = piholePassword?.trimmedNilIfEmpty
        self.piholeAuthMode = piholeAuthMode
        self.fallbackUrl = Self.cleanOptionalURL(fallbackUrl)
        self.allowSelfSigned = allowSelfSigned
        self.password = password?.trimmedNilIfEmpty
    }

    var displayLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? type.displayName : label
    }

    var piHoleStoredSecret: String? {
        if let piholePassword, !piholePassword.isEmpty {
            return piholePassword
        }
        if type == .pihole, let apiKey, !apiKey.isEmpty {
            return apiKey
        }
        return nil
    }

    func updatingToken(_ token: String, piholeAuthMode: PiHoleAuthMode? = nil) -> ServiceInstance {
        let migratedPiHolePassword = type == .pihole ? piHoleStoredSecret : piholePassword
        return ServiceInstance(
            id: id,
            type: type,
            label: displayLabel,
            url: url,
            token: token,
            username: username,
            apiKey: apiKey,
            piholePassword: migratedPiHolePassword,
            piholeAuthMode: piholeAuthMode ?? self.piholeAuthMode,
            fallbackUrl: fallbackUrl,
            password: password
        )
    }

    func updating(
        label: String? = nil,
        url: String? = nil,
        token: String? = nil,
        username: String? = nil,
        apiKey: String? = nil,
        piholePassword: String? = nil,
        piholeAuthMode: PiHoleAuthMode? = nil,
        fallbackUrl: String? = nil,
        allowSelfSigned: Bool? = nil,
        password: String? = nil
    ) -> ServiceInstance {
        ServiceInstance(
            id: id,
            type: type,
            label: label ?? displayLabel,
            url: url ?? self.url,
            token: token ?? self.token,
            username: username ?? self.username,
            apiKey: apiKey ?? self.apiKey,
            piholePassword: piholePassword ?? self.piholePassword,
            piholeAuthMode: piholeAuthMode ?? self.piholeAuthMode,
            fallbackUrl: fallbackUrl ?? self.fallbackUrl,
            allowSelfSigned: allowSelfSigned ?? self.allowSelfSigned,
            password: password ?? self.password
        )
    }

    private static func cleanURL(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    }

    private static func cleanOptionalURL(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = cleanURL(value)
        return cleaned.isEmpty ? nil : cleaned
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case label
        case url
        case token
        case username
        case apiKey
        case piholePassword
        case piholeAuthMode
        case fallbackUrl
        case allowSelfSigned
        case password
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            type: try container.decode(ServiceType.self, forKey: .type),
            label: try container.decode(String.self, forKey: .label),
            url: try container.decode(String.self, forKey: .url),
            token: try container.decodeIfPresent(String.self, forKey: .token) ?? "",
            username: try container.decodeIfPresent(String.self, forKey: .username),
            apiKey: try container.decodeIfPresent(String.self, forKey: .apiKey),
            piholePassword: try container.decodeIfPresent(String.self, forKey: .piholePassword),
            piholeAuthMode: try container.decodeIfPresent(PiHoleAuthMode.self, forKey: .piholeAuthMode),
            fallbackUrl: try container.decodeIfPresent(String.self, forKey: .fallbackUrl),
            allowSelfSigned: try container.decodeIfPresent(Bool.self, forKey: .allowSelfSigned) ?? false,
            password: try container.decodeIfPresent(String.self, forKey: .password)
        )
    }
}

struct ServiceStateV2: Codable, Equatable {
    var instances: [ServiceInstance]
    var preferredInstanceIdByType: [ServiceType: UUID]

    static let empty = ServiceStateV2(instances: [], preferredInstanceIdByType: [:])
}

struct ServiceConnection: Codable, Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: ServiceType
    var url: String
    var token: String
    var username: String?
    var apiKey: String?
    var piholePassword: String?
    var piholeAuthMode: PiHoleAuthMode?
    var fallbackUrl: String?
    var allowSelfSigned: Bool

    init(
        type: ServiceType,
        url: String,
        token: String = "",
        username: String? = nil,
        apiKey: String? = nil,
        piholePassword: String? = nil,
        piholeAuthMode: PiHoleAuthMode? = nil,
        fallbackUrl: String? = nil,
        allowSelfSigned: Bool = false
    ) {
        self.type = type
        self.url = url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        self.token = token
        self.username = username
        self.apiKey = apiKey
        self.piholePassword = piholePassword
        self.piholeAuthMode = piholeAuthMode
        self.fallbackUrl = fallbackUrl?.isEmpty == true ? nil : fallbackUrl
        self.allowSelfSigned = allowSelfSigned
    }

    var piHoleStoredSecret: String? {
        if let piholePassword, !piholePassword.isEmpty {
            return piholePassword
        }
        if type == .pihole, let apiKey, !apiKey.isEmpty {
            return apiKey
        }
        return nil
    }

    func updatingToken(_ token: String, piholeAuthMode: PiHoleAuthMode? = nil) -> ServiceConnection {
        let migratedPiHolePassword = type == .pihole ? piHoleStoredSecret : piholePassword
        return ServiceConnection(
            type: type,
            url: url,
            token: token,
            username: username,
            apiKey: apiKey,
            piholePassword: migratedPiHolePassword,
            piholeAuthMode: piholeAuthMode ?? self.piholeAuthMode,
            fallbackUrl: fallbackUrl,
            allowSelfSigned: allowSelfSigned
        )
    }

    func migratedInstance(id: UUID = UUID()) -> ServiceInstance {
        ServiceInstance(
            id: id,
            type: type,
            label: type.displayName,
            url: url,
            token: token,
            username: username,
            apiKey: apiKey,
            piholePassword: type == .pihole ? piHoleStoredSecret : piholePassword,
            piholeAuthMode: piholeAuthMode,
            fallbackUrl: fallbackUrl,
            allowSelfSigned: allowSelfSigned
        )
    }

    enum CodingKeys: String, CodingKey {
        case type
        case url
        case token
        case username
        case apiKey
        case piholePassword
        case piholeAuthMode
        case fallbackUrl
        case allowSelfSigned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            type: try container.decode(ServiceType.self, forKey: .type),
            url: try container.decode(String.self, forKey: .url),
            token: try container.decodeIfPresent(String.self, forKey: .token) ?? "",
            username: try container.decodeIfPresent(String.self, forKey: .username),
            apiKey: try container.decodeIfPresent(String.self, forKey: .apiKey),
            piholePassword: try container.decodeIfPresent(String.self, forKey: .piholePassword),
            piholeAuthMode: try container.decodeIfPresent(PiHoleAuthMode.self, forKey: .piholeAuthMode),
            fallbackUrl: try container.decodeIfPresent(String.self, forKey: .fallbackUrl),
            allowSelfSigned: try container.decodeIfPresent(Bool.self, forKey: .allowSelfSigned) ?? false
        )
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

func resolvedServiceArtworkURL(_ raw: String?, instance: ServiceInstance?) -> String? {
    guard let instance else {
        return normalizedArtworkURLString(raw)
    }
    return resolvedServiceArtworkURL(
        raw,
        baseURL: instance.url,
        fallbackURL: instance.fallbackUrl,
        apiKey: instance.apiKey
    )
}

func serviceArtworkHeaders(for resolvedURL: String?, instance: ServiceInstance?) -> [String: String] {
    guard
        let resolvedURL,
        let instance,
        let apiKey = instance.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
        !apiKey.isEmpty,
        isServiceHostedArtworkURL(resolvedURL, baseURL: instance.url) || isServiceHostedArtworkURL(resolvedURL, baseURL: instance.fallbackUrl)
    else {
        return [:]
    }
    return ["X-Api-Key": apiKey]
}

func resolvedServiceArtworkURL(
    _ raw: String?,
    baseURL: String,
    fallbackURL: String? = nil,
    apiKey: String? = nil
) -> String? {
    guard let value = normalizedArtworkURLString(raw) else { return nil }
    if value.hasPrefix("http://") || value.hasPrefix("https://") {
        let isHostedByService = isServiceHostedArtworkURL(value, baseURL: baseURL)
            || isServiceHostedArtworkURL(value, baseURL: fallbackURL)
        return isHostedByService ? appendingArtworkAPIKey(apiKey, to: value) : value
    }

    let cleanBase = baseURL
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    guard !cleanBase.isEmpty else { return value }
    let absolute = cleanBase + (value.hasPrefix("/") ? value : "/\(value)")
    return appendingArtworkAPIKey(apiKey, to: absolute)
}

private func normalizedArtworkURLString(_ raw: String?) -> String? {
    guard let raw else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
}

private func isServiceHostedArtworkURL(_ raw: String, baseURL: String?) -> Bool {
    guard
        let baseURL,
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let artworkURL = URL(string: raw),
        let serviceURL = URL(string: baseURL)
    else {
        return false
    }

    guard artworkURL.host?.lowercased() == serviceURL.host?.lowercased() else {
        return false
    }
    return (artworkURL.port ?? artworkURL.defaultPort) == (serviceURL.port ?? serviceURL.defaultPort)
}

private func appendingArtworkAPIKey(_ apiKey: String?, to raw: String) -> String {
    guard let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty else {
        return raw
    }
    guard var components = URLComponents(string: raw) else { return raw }
    let existingItems = components.queryItems ?? []
    if existingItems.contains(where: { $0.name.caseInsensitiveCompare("apikey") == .orderedSame }) {
        return raw
    }
    components.queryItems = existingItems + [URLQueryItem(name: "apikey", value: apiKey)]
    return components.string ?? raw
}

private extension URL {
    var defaultPort: Int? {
        switch scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }
}
