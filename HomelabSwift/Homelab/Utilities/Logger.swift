import Foundation
import os
import Observation

/// A centralized structured logger for the Homelab application.
public struct AppLogger: Sendable {
    public static let shared = AppLogger()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.homelab.app", category: "General")
    
    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(message, level: .debug)
        }
    }
    
    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(message, level: .info)
        }
    }
    
    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(message, level: .error)
        }
    }
    
    public func error(_ error: Error) {
        let msg = "Error: \(error.localizedDescription)"
        logger.error("\(msg, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(msg, level: .error)
        }
    }

    public func network(_ message: String) {
        logger.info("[Network] \(message, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(message, level: .network)
        }
    }

    /// Logs state transitions for ViewModels using LoadableState
    public func stateTransition<T>(service: String, state: LoadableState<T>) {
        let stateString: String
        switch state {
        case .idle: stateString = "Idle"
        case .loading: stateString = "Loading"
        case .loaded: stateString = "Loaded"
        case .error(let err): stateString = "Error (\(err.errorDescription ?? "unknown"))"
        case .offline: stateString = "Offline"
        }
        let msg = "[\(service)] State Transition -> \(stateString)"
        logger.debug("\(msg, privacy: .public)")
        Task { @MainActor in
            LogStore.shared.add(msg, level: .debug)
        }
    }
}

// MARK: - LogStore

@MainActor
@Observable
public final class LogStore {
    public static let shared = LogStore()
    
    public struct LogEntry: Identifiable {
        public let id = UUID()
        public let timestamp = Date()
        public let level: LogLevel
        public let message: String
        
        public var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }
    
    public enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case error = "ERROR"
        case network = "NET"
        
        public var icon: String {
            switch self {
            case .debug: return "ladybug.fill"
            case .info: return "info.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .network: return "network"
            }
        }
    }
    
    public private(set) var entries: [LogEntry] = []
    private let maxEntries = 500
    
    private init() {}
    
    public func add(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(level: level, message: message)
        entries.append(entry)
        
        if entries.count > maxEntries {
            entries.removeFirst()
        }
    }
    
    public func clear() {
        entries.removeAll()
    }
    
    public func export() -> String {
        entries.map { "[\($0.formattedTime)] [\($0.level.rawValue)] \($0.message)" }
            .joined(separator: "\n")
    }
}
