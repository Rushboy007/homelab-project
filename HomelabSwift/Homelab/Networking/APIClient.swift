import Foundation

// MARK: - Notifications for 401 interception

extension Notification.Name {
    static let serviceUnauthorized = Notification.Name("serviceUnauthorized")
}

// MARK: - Base networking engine (used via composition, NOT inheritance)
// Swift actors cannot inherit from other actors. Each API client actor
// owns a BaseNetworkEngine instance to share the common request logic.

final class BaseNetworkEngine: Sendable {
    let serviceType: ServiceType
    let instanceId: UUID
    private let timeoutInterval: TimeInterval = 8
    private let pingTimeout: TimeInterval = 3

    private static let insecureDelegate = InsecureTrustDelegate()
    static let insecureDelegateForPortainerAuth = insecureDelegate

    init(serviceType: ServiceType, instanceId: UUID) {
        self.serviceType = serviceType
        self.instanceId = instanceId
    }

    // MARK: - Core Request (primary → fallback)

    func request<T: Decodable>(
        baseURL: String,
        fallbackURL: String,
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }

        do {
            return try await performRequest(baseURL: baseURL, path: path, method: method, headers: headers, body: body)
        } catch let primaryError {
            guard !fallbackURL.isEmpty else { throw primaryError }
            do {
                return try await performRequest(baseURL: fallbackURL, path: path, method: method, headers: headers, body: body)
            } catch let fallbackError {
                throw APIError.bothURLsFailed(primaryError: primaryError, fallbackError: fallbackError)
            }
        }
    }

    /// Request that returns raw String (for logs)
    func requestString(
        baseURL: String,
        fallbackURL: String,
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> String {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }

        do {
            return try await performStringRequest(baseURL: baseURL, path: path, method: method, headers: headers, body: body)
        } catch let primaryError {
            guard !fallbackURL.isEmpty else { throw primaryError }
            do {
                return try await performStringRequest(baseURL: fallbackURL, path: path, method: method, headers: headers, body: body)
            } catch let fallbackError {
                throw APIError.bothURLsFailed(primaryError: primaryError, fallbackError: fallbackError)
            }
        }
    }

    /// Request that ignores response body (for actions like start/stop)
    func requestVoid(
        baseURL: String,
        fallbackURL: String,
        path: String,
        method: String = "POST",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }

        do {
            try await performVoidRequest(baseURL: baseURL, path: path, method: method, headers: headers, body: body)
        } catch let primaryError {
            guard !fallbackURL.isEmpty else { throw primaryError }
            do {
                try await performVoidRequest(baseURL: fallbackURL, path: path, method: method, headers: headers, body: body)
            } catch let fallbackError {
                throw APIError.bothURLsFailed(primaryError: primaryError, fallbackError: fallbackError)
            }
        }
    }

    /// Request that returns raw Data (for PiHole dynamic JSON parsing)
    func requestData(
        baseURL: String,
        fallbackURL: String,
        path: String,
        method: String = "GET",
        headers: [String: String] = [:]
    ) async throws -> Data {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }

        do {
            return try await performDataRequest(baseURL: baseURL, path: path, method: method, headers: headers)
        } catch let primaryError {
            guard !fallbackURL.isEmpty else { throw primaryError }
            do {
                return try await performDataRequest(baseURL: fallbackURL, path: path, method: method, headers: headers)
            } catch let fallbackError {
                throw APIError.bothURLsFailed(primaryError: primaryError, fallbackError: fallbackError)
            }
        }
    }

    // MARK: - Ping Helper

    func pingURL(_ urlString: String, extraHeaders: [String: String] = [:]) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = pingTimeout
        let session = URLSession(configuration: config, delegate: BaseNetworkEngine.insecureDelegate, delegateQueue: nil)
        var request = URLRequest(url: url)
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode < 600
        } catch {
            return false
        }
    }

    // MARK: - Private

    private var urlSession: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        return URLSession(configuration: config, delegate: BaseNetworkEngine.insecureDelegate, delegateQueue: nil)
    }

    private func performRequest<T: Decodable>(
        baseURL: String,
        path: String,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> T {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeoutInterval
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        req.httpBody = body

        logRequest(req)
        let (data, response) = try await urlSession.data(for: req)
        logResponse(response, data: data)
        try interceptResponse(response, data: data)

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performStringRequest(
        baseURL: String,
        path: String,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> String {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeoutInterval
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        req.httpBody = body

        logRequest(req)
        let (data, response) = try await urlSession.data(for: req)
        logResponse(response, data: data)
        try interceptResponse(response, data: data)

        return String(data: data, encoding: .utf8) ?? ""
    }

    private func performVoidRequest(
        baseURL: String,
        path: String,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeoutInterval
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        req.httpBody = body

        logRequest(req)
        let (data, response) = try await urlSession.data(for: req)
        logResponse(response, data: data)
        try interceptResponse(response, data: data)
    }

    private func performDataRequest(
        baseURL: String,
        path: String,
        method: String,
        headers: [String: String]
    ) async throws -> Data {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeoutInterval
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }

        req.httpBody = nil

        logRequest(req)
        let (data, response) = try await urlSession.data(for: req)
        logResponse(response, data: data)
        try interceptResponse(response)
        return data
    }

    private func logRequest(_ request: URLRequest) {
        let url = request.url?.absoluteString ?? "unknown"
        let method = request.httpMethod ?? "GET"
        AppLogger.shared.network("--> \(method) \(url)")
    }

    private func logResponse(_ response: URLResponse, data: Data?) {
        guard let http = response as? HTTPURLResponse else { return }
        let url = response.url?.absoluteString ?? "unknown"
        let status = http.statusCode
        let size = data?.count ?? 0
        AppLogger.shared.network("<-- \(status) \(url) (\(size) bytes)")
    }

    private func interceptResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { return }

        // Detection of HTML when expecting JSON (likely a redirect to a login page)
        if let contentType = http.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("text/html") {
            // Check if this is a known HTML error or a potential login page
            let bodySnippet = data.flatMap { String(data: $0.prefix(500), encoding: .utf8) } ?? ""
            if bodySnippet.lowercased().contains("<html") {
                 throw APIError.custom("Received an HTML response instead of JSON. This often happens when the service is behind a login page or proxy (OAuth/SSO). Please check your configuration.")
            }
        }

        if http.statusCode == 401 {
            let type = serviceType
            let instanceId = instanceId
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .serviceUnauthorized,
                    object: nil,
                    userInfo: [
                        "serviceType": type,
                        "instanceId": instanceId
                    ]
                )
            }
            throw APIError.unauthorized
        }

        if http.statusCode >= 400 {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            throw APIError.httpError(statusCode: http.statusCode, body: body)
        }
    }
}

final class InsecureTrustDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Encoding helpers

extension Encodable {
    func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    func toJSONBody() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
