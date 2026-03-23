package com.homelab.app.data.remote.dto.plex

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PlexServerInfo(
    val name: String,
    val platform: String,
    val version: String
)

@Serializable
data class PlexLibrary(
    val id: String,
    val key: String,
    val title: String,
    val type: String,
    val scanner: String,
    val agent: String,
    val createdAt: Long,
    val updatedAt: Long?,
    val itemCount: Int = 0,
    val episodeCount: Int = 0,
    val totalSize: Long = 0,
    val sfSymbol: String = "folder.fill"
)

@Serializable
data class PlexSession(
    val id: String,
    val title: String,
    val parentTitle: String = "",
    val grandparentTitle: String = "",
    val type: String,
    val username: String,
    val playerPlatform: String,
    val playerState: String,
    val isLocal: Boolean,
    val resolution: String = "",
    val isTranscoding: Boolean = false,
    val progressRatio: Double = 0.0,
    val bandwidth: Long = 0,
    val posterUrl: String = "",
    val duration: Long = 0,
    val viewOffset: Long = 0
) {
    val displayTitle: String
        get() = if (type == "episode") "$grandparentTitle - $parentTitle" else title

    val displaySubtitle: String
        get() = if (type == "episode") title else ""

    val bandwidthMbps: Double
        get() = bandwidth / 1000.0

    val resolutionLabel: String
        get() {
            if (resolution.isEmpty()) return ""
            return if (resolution == "4k") "4K" else "${resolution}p"
        }
}

@Serializable
data class PlexRecentItem(
    val id: String,
    val title: String,
    val parentTitle: String = "",
    val grandparentTitle: String = "",
    val type: String,
    val year: Int? = null,
    val addedAt: Long,
    val sfSymbol: String = "film.fill"
) {
    val displayTitle: String
        get() = if (type == "episode") grandparentTitle else title
}

@Serializable
data class PlexHistoryItem(
    val id: String,
    val title: String,
    val parentTitle: String = "",
    val grandparentTitle: String = "",
    val type: String,
    val viewedAt: Long,
    val username: String,
    val playerPlatform: String
) {
    val displayTitle: String
        get() = if (type == "episode") grandparentTitle else title
}

@Serializable
data class PlexStats(
    val totalItems: Int = 0,
    val totalMovies: Int = 0,
    val totalShows: Int = 0,
    val totalEpisodes: Int = 0,
    val totalMusic: Int = 0,
    val totalPhotos: Int = 0
)

@Serializable
data class PlexDashboardData(
    val serverInfo: PlexServerInfo,
    val libraries: List<PlexLibrary>,
    val stats: PlexStats,
    val activeSessions: List<PlexSession>,
    val recentlyAdded: List<PlexRecentItem>,
    val watchHistory: List<PlexHistoryItem>
)
