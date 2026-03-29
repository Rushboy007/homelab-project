package com.homelab.app.data.remote.dto.linux_update

import java.util.Locale
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive

@Serializable
data class LinuxUpdateDashboardStatsResponse(
    val stats: LinuxUpdateDashboardStats = LinuxUpdateDashboardStats()
)

@Serializable
data class LinuxUpdateDashboardSystemsResponse(
    val systems: List<LinuxUpdateSystem> = emptyList()
)

@Serializable
data class LinuxUpdateSystemDetailResponse(
    val system: LinuxUpdateSystem = LinuxUpdateSystem(),
    val updates: List<LinuxUpdatePackageUpdate> = emptyList(),
    val hiddenUpdates: List<LinuxUpdatePackageUpdate> = emptyList(),
    val history: List<LinuxUpdateHistoryEntry> = emptyList()
)

@Serializable
data class LinuxUpdateJobStartResponse(
    val status: String = "",
    @SerialName("job") val job: String? = null,
    @SerialName("job_id") val jobAlias: String? = null,
    val id: String? = null,
    val jobId: String? = null,
    val error: String? = null,
    val message: String? = null
)

@Serializable
data class LinuxUpdateUpgradePackagesRequest(
    @SerialName("packageNames") val packageNames: List<String> = emptyList(),
    val packages: List<String> = emptyList()
)

@Serializable
data class LinuxUpdateJobStatusResponse(
    val status: String = "",
    val result: JsonElement? = null,
    val error: String? = null
)

@Serializable
data class LinuxUpdateRebootResponse(
    @Serializable(with = FlexibleBoolSerializer::class) val success: Boolean = false,
    val message: String? = null,
    val error: String? = null
)

@Serializable
data class LinuxUpdateDashboardStats(
    @Serializable(with = FlexibleIntSerializer::class) val total: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val upToDate: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val needsUpdates: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val unreachable: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val checkIssues: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val totalUpdates: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val needsReboot: Int = 0
)

@Serializable
data class LinuxUpdateLastCheckSummary(
    val status: String = "",
    val error: String? = null,
    @SerialName("startedAt") val startedAt: String? = null,
    @SerialName("completedAt") val completedAt: String? = null
)

@Serializable
data class LinuxUpdateActiveOperation(
    val type: String = "",
    @SerialName("startedAt") val startedAt: String? = null,
    @SerialName("packageName") val packageName: String? = null
)

@Serializable
data class LinuxUpdateSystem(
    @Serializable(with = FlexibleIntSerializer::class) val id: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val sortOrder: Int = 0,
    val name: String = "",
    val hostname: String = "",
    val osName: String? = null,
    val osVersion: String? = null,
    val arch: String? = null,
    @Serializable(with = FlexibleIntSerializer::class) val updateCount: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val securityCount: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val keptBackCount: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val needsReboot: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val isReachable: Int = 0,
    val lastSeenAt: String? = null,
    val lastCheck: LinuxUpdateLastCheckSummary? = null,
    val cacheAge: String? = null,
    @Serializable(with = FlexibleBoolSerializer::class) val isStale: Boolean = false,
    val activeOperation: LinuxUpdateActiveOperation? = null,
    @Serializable(with = FlexibleBoolSerializer::class) val supportsFullUpgrade: Boolean = false
) {
    val needsRebootFlag: Boolean
        get() = needsReboot == 1

    val isReachableFlag: Boolean?
        get() = when (isReachable) {
            1 -> true
            -1 -> false
            else -> null
        }

    val hasCheckIssue: Boolean
        get() {
            val status = lastCheck?.status?.trim()?.lowercase(Locale.ROOT).orEmpty()
            return status == "failed" || status == "warning"
        }

    val osSummary: String
        get() {
            val details = listOf(osName, osVersion, arch)
                .mapNotNull { it?.trim()?.takeIf(String::isNotEmpty) }
            return when {
                details.isNotEmpty() -> details.joinToString(" • ")
                hostname.isNotBlank() -> hostname
                else -> name.ifBlank { "System" }
            }
        }
}

@Serializable
data class LinuxUpdatePackageUpdate(
    @Serializable(with = FlexibleIntSerializer::class) val id: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val systemId: Int = 0,
    val pkgManager: String = "",
    val packageName: String = "",
    val currentVersion: String? = null,
    val newVersion: String? = null,
    val architecture: String? = null,
    val repository: String? = null,
    @Serializable(with = FlexibleIntSerializer::class) val isSecurity: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val isKeptBack: Int = 0,
    val cachedAt: String? = null,
    @Serializable(with = FlexibleIntSerializer::class) val active: Int = 0,
    val createdAt: String? = null,
    val updatedAt: String? = null,
    val lastMatchedAt: String? = null,
    val inactiveSince: String? = null
) {
    val isSecurityFlag: Boolean
        get() = isSecurity == 1

    val isKeptBackFlag: Boolean
        get() = isKeptBack == 1
}

@Serializable
data class LinuxUpdateHistoryEntry(
    @Serializable(with = FlexibleIntSerializer::class) val id: Int = 0,
    @Serializable(with = FlexibleIntSerializer::class) val systemId: Int = 0,
    val action: String = "",
    val pkgManager: String = "",
    @Serializable(with = FlexibleNullableIntSerializer::class) val packageCount: Int? = null,
    val packages: String? = null,
    val packagesList: List<String> = emptyList(),
    val command: String? = null,
    val steps: List<LinuxUpdateHistoryStep>? = null,
    val status: String = "",
    val output: String? = null,
    val error: String? = null,
    val startedAt: String? = null,
    val completedAt: String? = null
)

@Serializable
data class LinuxUpdateHistoryStep(
    val label: String? = null,
    val pkgManager: String = "",
    val command: String = "",
    val output: String? = null,
    val error: String? = null,
    val status: String = "",
    val startedAt: String? = null,
    val completedAt: String? = null
)

private object FlexibleIntSerializer : KSerializer<Int> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("FlexibleInt", PrimitiveKind.INT)

    override fun deserialize(decoder: Decoder): Int {
        val jsonDecoder = decoder as? JsonDecoder
        if (jsonDecoder != null) {
            val primitive = jsonDecoder.decodeJsonElement() as? JsonPrimitive
            return primitive.asFlexibleInt()
        }

        return runCatching { decoder.decodeInt() }
            .recoverCatching { decoder.decodeString().toIntOrNull() ?: 0 }
            .getOrDefault(0)
    }

    override fun serialize(encoder: Encoder, value: Int) {
        encoder.encodeInt(value)
    }
}

private object FlexibleBoolSerializer : KSerializer<Boolean> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("FlexibleBool", PrimitiveKind.BOOLEAN)

    override fun deserialize(decoder: Decoder): Boolean {
        val jsonDecoder = decoder as? JsonDecoder
        if (jsonDecoder != null) {
            val primitive = jsonDecoder.decodeJsonElement() as? JsonPrimitive
            return primitive.asFlexibleBool()
        }

        return runCatching { decoder.decodeBoolean() }
            .recoverCatching {
                val raw = decoder.decodeString().trim().lowercase(Locale.ROOT)
                raw == "true" || raw == "1" || raw == "yes"
            }
            .getOrDefault(false)
    }

    override fun serialize(encoder: Encoder, value: Boolean) {
        encoder.encodeBoolean(value)
    }
}

private object FlexibleNullableIntSerializer : KSerializer<Int?> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("FlexibleNullableInt", PrimitiveKind.INT)

    override fun deserialize(decoder: Decoder): Int? {
        val jsonDecoder = decoder as? JsonDecoder
        if (jsonDecoder != null) {
            val primitive = jsonDecoder.decodeJsonElement() as? JsonPrimitive
            return primitive?.asFlexibleNullableInt()
        }

        return runCatching { decoder.decodeInt() }
            .recoverCatching {
                decoder.decodeString().toIntOrNull()
            }
            .getOrNull()
    }

    override fun serialize(encoder: Encoder, value: Int?) {
        encoder.encodeInt(value ?: 0)
    }
}

private fun JsonPrimitive?.asFlexibleInt(): Int {
    val primitive = this ?: return 0
    val raw = primitive.content.trim()
    if (raw.equals("true", ignoreCase = true)) return 1
    if (raw.equals("false", ignoreCase = true)) return 0
    raw.toIntOrNull()?.let { return it }
    raw.toDoubleOrNull()?.let { return it.toInt() }

    return 0
}

private fun JsonPrimitive?.asFlexibleBool(): Boolean {
    val primitive = this ?: return false
    val raw = primitive.content.trim().lowercase(Locale.ROOT)
    if (raw == "true" || raw == "1" || raw == "yes") return true
    if (raw == "false" || raw == "0" || raw == "no") return false
    raw.toDoubleOrNull()?.let { return it != 0.0 }

    return false
}

private fun JsonPrimitive.asFlexibleNullableInt(): Int? {
    if (isString && content.equals("null", ignoreCase = true)) return null
    val raw = content.trim()
    if (raw.equals("null", ignoreCase = true)) return null
    if (raw.isEmpty()) return null
    if (raw.equals("true", ignoreCase = true)) return 1
    if (raw.equals("false", ignoreCase = true)) return 0
    raw.toIntOrNull()?.let { return it }
    raw.toDoubleOrNull()?.let { return it.toInt() }
    return null
}
