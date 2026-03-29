package com.homelab.app.data.repository

import com.homelab.app.data.remote.api.PangolinApi
import com.homelab.app.data.remote.dto.pangolin.PangolinClient
import com.homelab.app.data.remote.dto.pangolin.PangolinDomain
import com.homelab.app.data.remote.dto.pangolin.PangolinOrg
import com.homelab.app.data.remote.dto.pangolin.PangolinResource
import com.homelab.app.data.remote.dto.pangolin.PangolinSite
import com.homelab.app.data.remote.dto.pangolin.PangolinSiteResource
import com.homelab.app.data.remote.dto.pangolin.PangolinTarget
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject
import javax.inject.Singleton

data class PangolinSnapshot(
    val orgs: List<PangolinOrg>,
    val sites: List<PangolinSite>,
    val siteResources: List<PangolinSiteResource>,
    val resources: List<PangolinResource>,
    val targetsByResourceId: Map<Int, List<PangolinTarget>>,
    val clients: List<PangolinClient>,
    val domains: List<PangolinDomain>
)

@Singleton
class PangolinRepository @Inject constructor(
    private val api: PangolinApi,
    private val okHttpClient: OkHttpClient
) {

    suspend fun authenticate(url: String, apiKey: String) {
        withContext(Dispatchers.IO) {
            val token = cleanToken(apiKey)
            val request = Request.Builder()
                .url("${cleanUrl(url)}/v1/orgs")
                .addHeader("Authorization", "Bearer $token")
                .build()

            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IllegalStateException("Pangolin authentication failed")
                }
            }
        }
    }

    suspend fun listOrgs(instanceId: String): List<PangolinOrg> =
        api.listOrgs(instanceId = instanceId).data.orgs.sortedBy { it.name.lowercase() }

    suspend fun getSnapshot(
        instanceId: String,
        orgId: String,
        orgs: List<PangolinOrg>? = null
    ): PangolinSnapshot = coroutineScope {
        val orgsDeferred = orgs?.let { null } ?: async { listOrgs(instanceId) }
        val sitesDeferred = async { listAllSites(instanceId, orgId) }
        val siteResourcesDeferred = async { listAllSiteResources(instanceId, orgId) }
        val resourcesDeferred = async { listAllResources(instanceId, orgId) }
        val clientsDeferred = async { listAllClients(instanceId, orgId) }
        val domainsDeferred = async { listAllDomains(instanceId, orgId) }

        val resources = resourcesDeferred.await()
        val targetsByResourceId = listTargetsByResource(instanceId, resources)

        PangolinSnapshot(
            orgs = orgs ?: orgsDeferred?.await().orEmpty(),
            sites = sitesDeferred.await(),
            siteResources = siteResourcesDeferred.await(),
            resources = resources,
            targetsByResourceId = targetsByResourceId,
            clients = clientsDeferred.await(),
            domains = domainsDeferred.await()
        )
    }

    suspend fun getAggregateSummary(instanceId: String): Triple<Int, Int, Int> {
        val orgs = listOrgs(instanceId)
        var totalSites = 0
        var totalResources = 0
        var totalClients = 0

        for (org in orgs) {
            totalSites += listAllSites(instanceId, org.orgId).size
            totalResources += listAllResources(instanceId, org.orgId).size + listAllSiteResources(instanceId, org.orgId).size
            totalClients += listAllClients(instanceId, org.orgId).size
        }

        return Triple(totalSites, totalResources, totalClients)
    }

    private suspend fun listAllSites(instanceId: String, orgId: String): List<PangolinSite> {
        val collected = mutableListOf<PangolinSite>()
        var page = 1
        val pageSize = 100
        while (true) {
            val response = api.listSites(orgId = orgId, instanceId = instanceId, pageSize = pageSize, page = page)
            val batch = response.data.sites
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            if (total > 0 && collected.size >= total) break
            page += 1
        }
        return collected.sortedWith(
            compareByDescending<PangolinSite> { it.online }
                .thenBy { it.name.lowercase() }
        )
    }

    private suspend fun listAllSiteResources(instanceId: String, orgId: String): List<PangolinSiteResource> {
        val collected = mutableListOf<PangolinSiteResource>()
        var page = 1
        val pageSize = 100
        while (true) {
            val response = api.listSiteResources(orgId = orgId, instanceId = instanceId, pageSize = pageSize, page = page)
            val batch = response.data.siteResources
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            if (total > 0 && collected.size >= total) break
            page += 1
        }
        return collected.sortedWith(
            compareByDescending<PangolinSiteResource> { it.enabled }
                .thenBy { it.siteName.lowercase() }
                .thenBy { it.name.lowercase() }
        )
    }

    private suspend fun listAllResources(instanceId: String, orgId: String): List<PangolinResource> {
        val collected = mutableListOf<PangolinResource>()
        var page = 1
        val pageSize = 100
        while (true) {
            val response = api.listResources(orgId = orgId, instanceId = instanceId, pageSize = pageSize, page = page)
            val batch = response.data.resources
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            if (total > 0 && collected.size >= total) break
            page += 1
        }
        return collected.sortedWith(
            compareByDescending<PangolinResource> { it.enabled }
                .thenBy { it.name.lowercase() }
        )
    }

    private suspend fun listAllClients(instanceId: String, orgId: String): List<PangolinClient> {
        val collected = mutableListOf<PangolinClient>()
        var page = 1
        val pageSize = 100
        while (true) {
            val response = api.listClients(orgId = orgId, instanceId = instanceId, pageSize = pageSize, page = page)
            val batch = response.data.clients
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            if (total > 0 && collected.size >= total) break
            page += 1
        }
        return collected.sortedWith(
            compareByDescending<PangolinClient> { it.online }
                .thenBy { it.blocked }
                .thenBy { it.name.lowercase() }
        )
    }

    private suspend fun listAllDomains(instanceId: String, orgId: String): List<PangolinDomain> {
        val collected = mutableListOf<PangolinDomain>()
        var offset = 0
        val limit = 1000
        while (true) {
            val response = api.listDomains(orgId = orgId, instanceId = instanceId, limit = limit, offset = offset)
            val batch = response.data.domains
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            offset += limit
            if (total > 0 && collected.size >= total) break
        }
        return collected.sortedWith(
            compareByDescending<PangolinDomain> { it.verified }
                .thenBy { it.baseDomain.lowercase() }
        )
    }

    private suspend fun listAllTargets(instanceId: String, resourceId: Int): List<PangolinTarget> {
        val collected = mutableListOf<PangolinTarget>()
        var offset = 0
        val limit = 1000
        while (true) {
            val response = api.listTargets(resourceId = resourceId, instanceId = instanceId, limit = limit, offset = offset)
            val batch = response.data.targets
            if (batch.isEmpty()) break
            collected += batch
            val total = response.pagination?.total ?: 0
            offset += limit
            if (total > 0 && collected.size >= total) break
        }
        return collected.sortedWith(
            compareByDescending<PangolinTarget> { it.enabled }
                .thenBy { it.priority ?: Int.MAX_VALUE }
                .thenBy { it.ip.lowercase() }
                .thenBy { it.port }
        )
    }

    private suspend fun listTargetsByResource(
        instanceId: String,
        resources: List<PangolinResource>
    ): Map<Int, List<PangolinTarget>> = coroutineScope {
        val pairs = mutableListOf<Pair<Int, List<PangolinTarget>>>()
        for (batch in resources.chunked(4)) {
            pairs += batch.map { resource ->
                async {
                    resource.resourceId to listAllTargets(instanceId, resource.resourceId)
                }
            }.awaitAll()
        }
        pairs.toMap()
    }

    private fun cleanUrl(url: String): String = url.trim().removeSuffix("/")

    private fun cleanToken(apiKey: String): String {
        val raw = apiKey.trim()
        return if (raw.startsWith("bearer ", ignoreCase = true)) {
            raw.substring(7).trim()
        } else {
            raw
        }
    }
}
