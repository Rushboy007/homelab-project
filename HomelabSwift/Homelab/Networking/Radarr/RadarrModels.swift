import Foundation

// MARK: - Radarr General

struct RadarrSystemStatus: Decodable, Sendable {
    let version: String
    let branch: String?
    let isOsx: Bool?
    let isLinux: Bool?
    let isWindows: Bool?
    
    var displayBranch: String {
        branch?.capitalized ?? "Master"
    }
}

// MARK: - Radarr Books / Movies

struct RadarrMovie: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String
    let status: String
    let hasFile: Bool
    let sizeOnDisk: Int64
    let year: Int?
    let overview: String?
    let added: String?
    let tmdbId: Int?
    let imdbId: String?
    let studio: String?
    let runtime: Int?
    
    // Sometimes images are available
    let images: [RadarrImage]?
    
    var posterUrl: String? {
        images?.first { $0.coverType.lowercased() == "poster" }?.resolvedURL
            ?? images?.compactMap(\.resolvedURL).first
    }
    
    var isDownloaded: Bool {
        hasFile || status.lowercased() == "downloaded"
    }
}

struct RadarrImage: Decodable, Sendable {
    let coverType: String
    let url: String?
    let remoteUrl: String?

    private enum CodingKeys: String, CodingKey {
        case coverType
        case url
        case remoteUrl
    }

    var resolvedURL: String? {
        let remote = remoteUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let remote, !remote.isEmpty { return remote }
        let local = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (local?.isEmpty == false) ? local : nil
    }
}

// MARK: - Radarr Queue

struct RadarrQueueResponse: Decodable, Sendable {
    let page: Int
    let pageSize: Int
    let totalRecords: Int
    let records: [RadarrQueueRecord]
}

struct RadarrQueueRecord: Decodable, Identifiable, Sendable {
    let id: Int
    let movieId: Int
    let title: String
    let size: Double
    let sizeleft: Double
    let timeleft: String?
    let status: String
    let trackedDownloadState: String?
    
    var progress: Double {
        guard size > 0 else { return 0 }
        let p = 1.0 - (sizeleft / size)
        return min(max(p, 0.0), 1.0)
    }
    
    var isWarning: Bool {
        trackedDownloadState?.lowercased() == "warning" || status.lowercased() == "warning"
    }
}

// MARK: - Radarr History

struct RadarrHistoryResponse: Decodable, Sendable {
    let page: Int
    let pageSize: Int
    let totalRecords: Int
    let records: [RadarrHistoryRecord]
}

struct RadarrHistoryRecord: Decodable, Identifiable, Sendable {
    let id: Int
    let movieId: Int
    let sourceTitle: String?
    let eventType: String?
    let date: String?
}
