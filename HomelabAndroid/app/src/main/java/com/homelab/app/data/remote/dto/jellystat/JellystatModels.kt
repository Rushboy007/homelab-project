package com.homelab.app.data.remote.dto.jellystat

data class JellystatLibraryTypeViews(
    val audio: Int,
    val movie: Int,
    val series: Int,
    val other: Int
) {
    val totalViews: Int get() = audio + movie + series + other
}

data class JellystatCountDuration(
    val count: Int,
    val durationSeconds: Double
)

data class JellystatSeriesPoint(
    val key: String,
    val totalViews: Int,
    val totalDurationSeconds: Double,
    val breakdown: Map<String, JellystatCountDuration>
)

data class JellystatWatchSummary(
    val days: Int,
    val totalHours: Double,
    val totalViews: Int,
    val activeDays: Int,
    val topLibraryName: String?,
    val topLibraryHours: Double,
    val viewsByType: JellystatLibraryTypeViews,
    val points: List<JellystatSeriesPoint>
)
