import Foundation

public enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case unauthorized
    case bothURLsFailed(primaryError: Error, fallbackError: Error)
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
