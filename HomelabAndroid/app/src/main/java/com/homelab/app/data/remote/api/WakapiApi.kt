package com.homelab.app.data.remote.api

import com.homelab.app.data.remote.dto.wakapi.WakapiSummaryResponse
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Query

interface WakapiApi {
    @GET("api/summary")
    suspend fun getSummary(
        @Header("X-Homelab-Service") service: String = "Wakapi",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("interval") interval: String = "today",
        @Query("project") project: String? = null,
        @Query("language") language: String? = null,
        @Query("editor") editor: String? = null,
        @Query("operating_system") operatingSystem: String? = null,
        @Query("machine") machine: String? = null,
        @Query("label") label: String? = null
    ): WakapiSummaryResponse
}
