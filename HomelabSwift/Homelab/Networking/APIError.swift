import Foundation

public struct ArrRequestOption: Identifiable, Equatable, Sendable {
    public let key: String
    public let label: String
    public let idValue: Int?
    public let pathValue: String?

    public var id: String { key }

    public init(key: String, label: String, idValue: Int?, pathValue: String?) {
        self.key = key
        self.label = label
        self.idValue = idValue
        self.pathValue = pathValue
    }
}

public struct ArrRequestConfiguration: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let title: String
    public let qualityProfiles: [ArrRequestOption]
    public let rootFolders: [ArrRequestOption]
    public let languageProfiles: [ArrRequestOption]
    public let metadataProfiles: [ArrRequestOption]

    public var requiresExplicitSelection: Bool {
        qualityProfiles.count > 1 ||
        rootFolders.count > 1 ||
        languageProfiles.count > 1 ||
        metadataProfiles.count > 1
    }

    public init(
        title: String,
        qualityProfiles: [ArrRequestOption],
        rootFolders: [ArrRequestOption],
        languageProfiles: [ArrRequestOption],
        metadataProfiles: [ArrRequestOption]
    ) {
        self.title = title
        self.qualityProfiles = qualityProfiles
        self.rootFolders = rootFolders
        self.languageProfiles = languageProfiles
        self.metadataProfiles = metadataProfiles
    }
}

public struct ArrRequestSelection: Equatable, Sendable {
    public let qualityProfile: ArrRequestOption?
    public let rootFolder: ArrRequestOption?
    public let languageProfile: ArrRequestOption?
    public let metadataProfile: ArrRequestOption?

    public init(
        qualityProfile: ArrRequestOption?,
        rootFolder: ArrRequestOption?,
        languageProfile: ArrRequestOption?,
        metadataProfile: ArrRequestOption?
    ) {
        self.qualityProfile = qualityProfile
        self.rootFolder = rootFolder
        self.languageProfile = languageProfile
        self.metadataProfile = metadataProfile
    }
}

public enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case unauthorized
    case bothURLsFailed(primaryError: Error, fallbackError: Error)
    case requestConfigurationRequired(ArrRequestConfiguration)
    case custom(String)

    public var errorDescription: String? {
        let t = Translations.current()
        switch self {
        case .notConfigured:
            return t.errorNotConfigured
        case .invalidURL:
            return t.errorInvalidURL
        case .networkError(let e):
            if let mapped = APIError.localizedNetworkError(e) {
                return mapped
            }
            return String(format: t.errorNetwork, e.localizedDescription)
        case .httpError(let code, let body):
            return String(format: t.errorHttp, code, body.isEmpty ? t.errorUnknown : body)
        case .decodingError(let e):
            return String(format: t.errorDecoding, e.localizedDescription)
        case .unauthorized:
            return t.errorUnauthorized
        case .bothURLsFailed(let primaryError, let fallbackError):
            if let mapped = APIError.localizedNetworkError(primaryError) ?? APIError.localizedNetworkError(fallbackError) {
                return mapped
            }
            return t.errorBothFailed
        case .requestConfigurationRequired:
            return "Additional request configuration required"
        case .custom(let msg):
            return msg
        }
    }

    static func localizedNetworkError(_ error: Error) -> String? {
        let t = Translations.current()
        if let urlError = error as? URLError {
            if urlError.code == .appTransportSecurityRequiresSecureConnection {
                return t.errorAtsRequiresSecure
            }
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
            return t.errorAtsRequiresSecure
        }
        return nil
    }
}
