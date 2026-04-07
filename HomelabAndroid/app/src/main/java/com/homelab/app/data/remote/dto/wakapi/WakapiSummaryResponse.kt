package com.homelab.app.data.remote.dto.wakapi

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class WakapiSummaryResponse(
    @SerialName("grand_total") val grandTotal: WakapiGrandTotal? = null,
    val projects: List<WakapiStatItem>? = null,
    val languages: List<WakapiStatItem>? = null,
    val machines: List<WakapiStatItem>? = null,
    @SerialName("operating_systems") val operatingSystems: List<WakapiStatItem>? = null,
    val editors: List<WakapiStatItem>? = null,
    val labels: List<WakapiStatItem>? = null,
    val categories: List<WakapiStatItem>? = null,
    val branches: List<WakapiStatItem>? = null
)

@Keep
@Serializable
data class WakapiGrandTotal(
    val digital: String? = null,
    val hours: Int? = null,
    val minutes: Int? = null,
    val text: String? = null,
    @SerialName("total_seconds") val totalSeconds: Double? = null
)

@Keep
@Serializable
data class WakapiStatItem(
    val name: String? = null,
    @SerialName("total_seconds") val totalSeconds: Double? = null,
    val percent: Double? = null,
    val digital: String? = null,
    val text: String? = null,
    val hours: Int? = null,
    val minutes: Int? = null
)
