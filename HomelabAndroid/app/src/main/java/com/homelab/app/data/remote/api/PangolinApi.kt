package com.homelab.app.data.remote.api

import com.homelab.app.data.remote.dto.pangolin.PangolinDomainsResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinOrgsResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinResourcesResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinSiteResourcesResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinSitesResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinClientsResponse
import com.homelab.app.data.remote.dto.pangolin.PangolinTargetsResponse
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Path
import retrofit2.http.Query

interface PangolinApi {

    @GET("v1/orgs")
    suspend fun listOrgs(
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("limit") limit: Int = 1000,
        @Query("offset") offset: Int = 0
    ): PangolinOrgsResponse

    @GET("v1/org/{orgId}/sites")
    suspend fun listSites(
        @Path("orgId") orgId: String,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("pageSize") pageSize: Int = 100,
        @Query("page") page: Int = 1
    ): PangolinSitesResponse

    @GET("v1/org/{orgId}/site-resources")
    suspend fun listSiteResources(
        @Path("orgId") orgId: String,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("pageSize") pageSize: Int = 100,
        @Query("page") page: Int = 1
    ): PangolinSiteResourcesResponse

    @GET("v1/org/{orgId}/resources")
    suspend fun listResources(
        @Path("orgId") orgId: String,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("pageSize") pageSize: Int = 100,
        @Query("page") page: Int = 1
    ): PangolinResourcesResponse

    @GET("v1/org/{orgId}/clients")
    suspend fun listClients(
        @Path("orgId") orgId: String,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("pageSize") pageSize: Int = 100,
        @Query("page") page: Int = 1,
        @Query("status") status: String = "active,blocked,archived"
    ): PangolinClientsResponse

    @GET("v1/org/{orgId}/domains")
    suspend fun listDomains(
        @Path("orgId") orgId: String,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("limit") limit: Int = 1000,
        @Query("offset") offset: Int = 0
    ): PangolinDomainsResponse

    @GET("v1/resource/{resourceId}/targets")
    suspend fun listTargets(
        @Path("resourceId") resourceId: Int,
        @Header("X-Homelab-Service") service: String = "Pangolin",
        @Header("X-Homelab-Instance-Id") instanceId: String,
        @Query("limit") limit: Int = 1000,
        @Query("offset") offset: Int = 0
    ): PangolinTargetsResponse
}
