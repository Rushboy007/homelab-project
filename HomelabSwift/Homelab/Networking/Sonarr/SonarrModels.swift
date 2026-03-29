import Foundation

// MARK: - Sonarr General

struct SonarrSystemStatus: Decodable, Sendable {
    let version: String
    let branch: String?
    let isOsx: Bool?
    let isLinux: Bool?
    let isWindows: Bool?

    private enum CodingKeys: String, CodingKey {
        case version
        case appVersion
        case branch
        case releaseBranch
        case isOsx
        case isLinux
        case isWindows
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = container.decodeString(forKeys: [.version, .appVersion], default: "Unknown")
        branch = container.decodeStringIfPresent(forKeys: [.branch, .releaseBranch])
        isOsx = try container.decodeIfPresent(Bool.self, forKey: .isOsx)
        isLinux = try container.decodeIfPresent(Bool.self, forKey: .isLinux)
        isWindows = try container.decodeIfPresent(Bool.self, forKey: .isWindows)
    }

    var displayBranch: String {
        branch?.capitalized ?? "Main"
    }
}

// MARK: - Sonarr Series

struct SonarrSeries: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String
    let status: String
    let episodeCount: Int
    let episodeFileCount: Int
    let sizeOnDisk: Int64
    let year: Int?
    let overview: String?
    let network: String?
    let tvdbId: Int?
    let tvMazeId: Int?
    let seasonCount: Int?
    let runtime: Int?
    let genres: [String]?
    let images: [SonarrImage]?
    private let directArtworkURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case sortTitle
        case status
        case episodeCount
        case totalEpisodeCount
        case episodeFileCount
        case sizeOnDisk
        case statistics
        case year
        case overview
        case network
        case tvdbId
        case tvMazeId
        case seasonCount
        case runtime
        case genres
        case images
        case poster
        case posterUrl
        case posterURL
        case image
        case imageUrl
        case cover
        case thumbnail
    }

    private enum StatisticsKeys: String, CodingKey {
        case episodeCount
        case totalEpisodeCount
        case episodeFileCount
        case sizeOnDisk
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statistics = try container.nestedContainerIfPresent(keyedBy: StatisticsKeys.self, forKey: .statistics)
        let directEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount)
        let totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount)
        let statisticsEpisodeCount = try statistics?.decodeIfPresent(Int.self, forKey: .episodeCount)
        let statisticsTotalEpisodeCount = try statistics?.decodeIfPresent(Int.self, forKey: .totalEpisodeCount)
        let directEpisodeFileCount = try container.decodeIfPresent(Int.self, forKey: .episodeFileCount)
        let statisticsEpisodeFileCount = try statistics?.decodeIfPresent(Int.self, forKey: .episodeFileCount)
        let directSizeOnDisk = try container.decodeIfPresent(Int64.self, forKey: .sizeOnDisk)
        let statisticsSizeOnDisk = try statistics?.decodeIfPresent(Int64.self, forKey: .sizeOnDisk)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = container.decodeString(forKeys: [.title, .sortTitle], default: "Unknown Series")
        status = container.decodeString(forKeys: [.status], default: "unknown")
        episodeCount = directEpisodeCount ?? totalEpisodeCount ?? statisticsEpisodeCount ?? statisticsTotalEpisodeCount ?? 0
        episodeFileCount = directEpisodeFileCount ?? statisticsEpisodeFileCount ?? 0
        sizeOnDisk = directSizeOnDisk ?? statisticsSizeOnDisk ?? 0
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        network = try container.decodeIfPresent(String.self, forKey: .network)
        tvdbId = try container.decodeIfPresent(Int.self, forKey: .tvdbId)
        tvMazeId = try container.decodeIfPresent(Int.self, forKey: .tvMazeId)
        seasonCount = try container.decodeIfPresent(Int.self, forKey: .seasonCount)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        genres = try container.decodeIfPresent([String].self, forKey: .genres)
        images = try container.decodeIfPresent([SonarrImage].self, forKey: .images)
        directArtworkURL = container.decodeStringIfPresent(
            forKeys: [.poster, .posterUrl, .posterURL, .image, .imageUrl, .cover, .thumbnail]
        )
    }

    var posterUrl: String? {
        let preferred = images?.first {
            let type = $0.coverType.lowercased()
            return type == "poster" || type == "cover"
        }?.resolvedURL
        return preferred ?? directArtworkURL ?? images?.compactMap(\.resolvedURL).first
    }

    var progress: Double {
        guard episodeCount > 0 else { return .zero }
        return min(max(Double(episodeFileCount) / Double(episodeCount), 0.0), 1.0)
    }
}

struct SonarrImage: Decodable, Sendable {
    let coverType: String
    let url: String?
    let remoteUrl: String?

    private enum CodingKeys: String, CodingKey {
        case coverType
        case url
        case remoteUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coverType = container.decodeString(forKeys: [.coverType], default: "poster")
        url = try container.decodeIfPresent(String.self, forKey: .url)
        remoteUrl = try container.decodeIfPresent(String.self, forKey: .remoteUrl)
    }

    var resolvedURL: String? {
        let remote = remoteUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let remote, !remote.isEmpty { return remote }
        let local = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (local?.isEmpty == false) ? local : nil
    }
}

// MARK: - Sonarr Queue

struct SonarrQueueResponse: Decodable, Sendable {
    let page: Int
    let pageSize: Int
    let totalRecords: Int
    let records: [SonarrQueueRecord]

    private enum CodingKeys: String, CodingKey {
        case page
        case pageSize
        case totalRecords
        case records
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize) ?? 0
        totalRecords = try container.decodeIfPresent(Int.self, forKey: .totalRecords) ?? 0
        records = try container.decodeIfPresent([SonarrQueueRecord].self, forKey: .records) ?? []
    }
}

struct SonarrQueueRecord: Decodable, Identifiable, Sendable {
    let id: Int
    let seriesId: Int
    let title: String
    let size: Double
    let sizeleft: Double
    let timeleft: String?
    let status: String
    let trackedDownloadState: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case seriesId
        case title
        case size
        case sizeleft
        case sizeLeft
        case timeleft
        case timeLeft
        case status
        case trackedDownloadState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let directSizeLeft = try container.decodeIfPresent(Double.self, forKey: .sizeleft)
        let camelSizeLeft = try container.decodeIfPresent(Double.self, forKey: .sizeLeft)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        seriesId = try container.decodeIfPresent(Int.self, forKey: .seriesId) ?? 0
        title = container.decodeString(forKeys: [.title], default: "Unknown Episode")
        size = try container.decodeIfPresent(Double.self, forKey: .size) ?? 0
        sizeleft = directSizeLeft ?? camelSizeLeft ?? 0
        timeleft = container.decodeStringIfPresent(forKeys: [.timeleft, .timeLeft])
        status = container.decodeString(forKeys: [.status], default: "unknown")
        trackedDownloadState = container.decodeStringIfPresent(forKeys: [.trackedDownloadState])
    }

    var progress: Double {
        guard size > 0 else { return 0 }
        let p = 1.0 - (sizeleft / size)
        return min(max(p, 0.0), 1.0)
    }

    var isWarning: Bool {
        trackedDownloadState?.lowercased() == "warning" || status.lowercased() == "warning"
    }
}

// MARK: - Sonarr History

struct SonarrHistoryResponse: Decodable, Sendable {
    let page: Int
    let pageSize: Int
    let totalRecords: Int
    let records: [SonarrHistoryRecord]

    private enum CodingKeys: String, CodingKey {
        case page
        case pageSize
        case totalRecords
        case records
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize) ?? 0
        totalRecords = try container.decodeIfPresent(Int.self, forKey: .totalRecords) ?? 0
        records = try container.decodeIfPresent([SonarrHistoryRecord].self, forKey: .records) ?? []
    }
}

struct SonarrHistoryRecord: Decodable, Identifiable, Sendable {
    let id: Int
    let seriesId: Int
    let sourceTitle: String?
    let eventType: String?
    let date: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case seriesId
        case sourceTitle
        case eventType
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        seriesId = try container.decodeIfPresent(Int.self, forKey: .seriesId) ?? 0
        sourceTitle = try container.decodeIfPresent(String.self, forKey: .sourceTitle)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
        date = try container.decodeIfPresent(String.self, forKey: .date)
    }
}

private extension KeyedDecodingContainer {
    func decodeString(forKeys keys: [K], default defaultValue: String) -> String {
        for key in keys {
            if let value = try? decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return defaultValue
    }

    func decodeStringIfPresent(forKeys keys: [K]) -> String? {
        for key in keys {
            if let value = try? decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    func nestedContainerIfPresent<NestedKeys: CodingKey>(
        keyedBy type: NestedKeys.Type,
        forKey key: K
    ) throws -> KeyedDecodingContainer<NestedKeys>? {
        guard contains(key), (try decodeNil(forKey: key)) == false else { return nil }
        return try nestedContainer(keyedBy: type, forKey: key)
    }
}
