package com.homelab.app.data.remote.dto.crafty

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class CraftyResponse<T>(
    val status: String,
    val data: T
)

@Serializable
data class CraftyLoginRequest(
    val username: String,
    val password: String
)

@Serializable
data class CraftyLoginData(
    val token: String? = null,
    @SerialName("user_id") val userId: String? = null
)

@Serializable
data class CraftyServer(
    @SerialName("server_id") val serverId: String,
    @SerialName("server_uuid") val serverUuid: String? = null,
    @SerialName("server_name") val serverName: String,
    val type: String? = null,
    @SerialName("server_port") val serverPort: Int? = null,
    val created: String? = null
)

@Serializable
data class CraftyServerStats(
    val running: Boolean = false,
    val cpu: Double? = null,
    val mem: String? = null,
    @SerialName("mem_percent") val memPercent: Double? = null,
    val online: Int? = null,
    val max: Int? = null,
    @SerialName("world_name") val worldName: String? = null,
    val version: String? = null,
    val updating: Boolean = false,
    @SerialName("waiting_start") val waitingStart: Boolean = false,
    val crashed: Boolean = false,
    val downloading: Boolean = false
)

@Serializable
data class CraftyActionResponse(
    val status: String = "",
    val error: String? = null,
    @SerialName("error_data") val errorData: String? = null
)
