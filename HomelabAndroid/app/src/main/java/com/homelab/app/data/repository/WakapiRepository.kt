package com.homelab.app.data.repository

import com.homelab.app.data.remote.api.WakapiApi
import com.homelab.app.data.remote.dto.wakapi.WakapiSummaryResponse
import java.io.IOException
import java.util.Base64
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import retrofit2.HttpException

class WakapiApiException(
    val kind: Kind,
    override val cause: Throwable? = null
) : Exception(kind.name, cause) {
    enum class Kind {
        INVALID_CREDENTIALS,
        SERVER_ERROR,
        CONNECTION_ERROR
    }
}

data class WakapiSummaryFilter(
    val dimension: Dimension,
    val value: String
) {
    enum class Dimension {
        PROJECT,
        LANGUAGE,
        EDITOR,
        OPERATING_SYSTEM,
        MACHINE,
        LABEL
    }
}

@Singleton
class WakapiRepository @Inject constructor(
    private val api: WakapiApi,
    private val okHttpClient: OkHttpClient
) {
    suspend fun authenticate(url: String, apiKey: String, fallbackUrl: String? = null) {
        withContext(Dispatchers.IO) {
            val baseCandidates = listOf(url.trim().trimEnd('/'), fallbackUrl?.trim()?.trimEnd('/'))
                .filter { !it.isNullOrBlank() }
                .distinct()
                .filterNotNull()

            var lastError: WakapiApiException? = null
            for (baseUrl in baseCandidates) {
                try {
                    authenticateAgainst(baseUrl = baseUrl, apiKey = apiKey)
                    return@withContext
                } catch (error: WakapiApiException) {
                    lastError = error
                    if (error.kind == WakapiApiException.Kind.INVALID_CREDENTIALS) {
                        throw error
                    }
                }
            }

            throw lastError ?: WakapiApiException(WakapiApiException.Kind.CONNECTION_ERROR)
        }
    }

    suspend fun getSummary(
        instanceId: String,
        interval: String = "today",
        filter: WakapiSummaryFilter? = null
    ): WakapiSummaryResponse {
        return try {
            api.getSummary(
                instanceId = instanceId,
                interval = interval,
                project = filter?.value.takeIf { filter?.dimension == WakapiSummaryFilter.Dimension.PROJECT },
                language = filter?.value.takeIf { filter?.dimension == WakapiSummaryFilter.Dimension.LANGUAGE },
                editor = filter?.value.takeIf { filter?.dimension == WakapiSummaryFilter.Dimension.EDITOR },
                operatingSystem = filter?.value.takeIf {
                    filter?.dimension == WakapiSummaryFilter.Dimension.OPERATING_SYSTEM
                },
                machine = filter?.value.takeIf { filter?.dimension == WakapiSummaryFilter.Dimension.MACHINE },
                label = filter?.value.takeIf { filter?.dimension == WakapiSummaryFilter.Dimension.LABEL }
            )
        } catch (e: Exception) {
            throw handleException(e)
        }
    }

    private fun handleException(error: Throwable): WakapiApiException {
        return when (error) {
            is HttpException -> {
                if (error.code() == 401 || error.code() == 403) {
                    WakapiApiException(WakapiApiException.Kind.INVALID_CREDENTIALS, error)
                } else {
                    WakapiApiException(WakapiApiException.Kind.SERVER_ERROR, error)
                }
            }
            is IOException -> WakapiApiException(WakapiApiException.Kind.CONNECTION_ERROR, error)
            is WakapiApiException -> error
            else -> WakapiApiException(WakapiApiException.Kind.SERVER_ERROR, error)
        }
    }

    private fun authenticateAgainst(baseUrl: String, apiKey: String) {
        val credentials = Base64.getEncoder()
            .encodeToString(apiKey.trim().toByteArray(Charsets.UTF_8))

        val request = Request.Builder()
            .url("$baseUrl/api/summary?interval=today")
            .addHeader("Authorization", "Basic $credentials")
            .addHeader("Content-Type", "application/json")
            .build()

        try {
            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    if (response.code == 401 || response.code == 403) {
                        throw WakapiApiException(WakapiApiException.Kind.INVALID_CREDENTIALS)
                    } else {
                        throw WakapiApiException(WakapiApiException.Kind.SERVER_ERROR)
                    }
                }
            }
        } catch (error: IOException) {
            throw WakapiApiException(WakapiApiException.Kind.CONNECTION_ERROR, error)
        }
    }
}
