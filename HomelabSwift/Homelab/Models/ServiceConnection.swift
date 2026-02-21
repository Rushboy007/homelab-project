import Foundation

struct ServiceConnection: Codable, Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: ServiceType
    var url: String
    var token: String
    var username: String?
    var apiKey: String?
    var fallbackUrl: String?

    init(type: ServiceType, url: String, token: String = "", username: String? = nil, apiKey: String? = nil, fallbackUrl: String? = nil) {
        self.type = type
        self.url = url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        self.token = token
        self.username = username
        self.apiKey = apiKey
        self.fallbackUrl = fallbackUrl?.isEmpty == true ? nil : fallbackUrl
    }
}
