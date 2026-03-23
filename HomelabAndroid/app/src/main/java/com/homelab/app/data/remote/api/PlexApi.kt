package com.homelab.app.data.remote.api

import kotlinx.serialization.json.JsonObject
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Path
import retrofit2.http.Query

interface PlexApi {

    @GET("identity")
    suspend fun getIdentity(
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("/")
    suspend fun getServerInfo(
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("library/sections")
    suspend fun getLibraries(
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("library/sections/{key}/all")
    suspend fun getLibrarySize(
        @Path("key") key: String,
        @Query("type") type: Int? = null,
        @Query("X-Plex-Container-Start") start: Int = 0,
        @Query("X-Plex-Container-Size") size: Int = 0,
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("status/sessions")
    suspend fun getActiveSessions(
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("library/recentlyAdded")
    suspend fun getRecentlyAdded(
        @Query("X-Plex-Container-Start") start: Int = 0,
        @Query("X-Plex-Container-Size") size: Int = 20,
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject

    @GET("status/sessions/history/all")
    suspend fun getWatchHistory(
        @Query("sort") sort: String = "viewedAt:desc",
        @Query("X-Plex-Container-Start") start: Int = 0,
        @Query("X-Plex-Container-Size") size: Int = 30,
        @Header("X-Homelab-Service") service: String = "Plex",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Header("Accept") accept: String = "application/json"
    ): JsonObject
}
