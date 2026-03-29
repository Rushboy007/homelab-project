import Foundation

struct LidarrSystemStatus: Decodable, Sendable {
    let version: String
    let branch: String?
    
    var displayBranch: String {
        branch?.capitalized ?? "Master"
    }
}

struct LidarrQueueResponse: Decodable, Sendable {
    let totalRecords: Int
    let records: [LidarrQueueRecord]
}

struct LidarrQueueRecord: Decodable, Identifiable, Sendable {
    let id: Int
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

struct LidarrAlbum: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String
    let artistId: Int
    let artistName: String?
    let releaseDate: String?
    let monitored: Bool?
    let overview: String?
    
    let images: [LidarrImage]?
    
    var coverUrl: String? {
        let preferred = images?.first {
            let type = $0.coverType.lowercased()
            return type == "cover" || type == "poster"
        }?.resolvedURL
        return preferred ?? images?.compactMap(\.resolvedURL).first
    }
}

struct LidarrImage: Decodable, Sendable {
    let coverType: String
    let url: String?
    let remoteUrl: String?

    var resolvedURL: String? {
        let remote = remoteUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let remote, !remote.isEmpty { return remote }
        let local = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (local?.isEmpty == false) ? local : nil
    }
}

struct LidarrHistoryResponse: Decodable, Sendable {
    let totalRecords: Int
    let records: [LidarrHistoryRecord]
}

struct LidarrHistoryRecord: Decodable, Identifiable, Sendable {
    let id: Int
    let sourceTitle: String?
    let eventType: String?
    let date: String?
}
