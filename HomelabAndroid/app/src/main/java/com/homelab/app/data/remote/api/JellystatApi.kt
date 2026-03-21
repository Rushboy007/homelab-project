package com.homelab.app.data.remote.api

import kotlinx.serialization.json.JsonObject
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Query

interface JellystatApi {

    @GET("stats/getViewsByLibraryType")
    suspend fun getViewsByLibraryType(
        @Header("X-Homelab-Service") service: String = "Jellystat",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("days") days: Int = 30
    ): JsonObject

    @GET("stats/getViewsOverTime")
    suspend fun getViewsOverTime(
        @Header("X-Homelab-Service") service: String = "Jellystat",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("days") days: Int = 30
    ): JsonObject
}
