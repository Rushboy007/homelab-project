package com.homelab.app.data.remote

import com.homelab.app.util.Logger
import okhttp3.Interceptor
import okhttp3.Response
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DebugLoggingInterceptor @Inject constructor() : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val startNs = System.nanoTime()

        Logger.i("Network", "-> ${request.method} ${request.url}")

        val response = try {
            chain.proceed(request)
        } catch (e: Exception) {
            Logger.e("Network", "x ${request.method} ${request.url}", e)
            throw e
        }

        val tookMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNs)
        val contentType = response.header("Content-Type") ?: "unknown"
        Logger.i("Network", "<- ${response.code} ${request.method} ${request.url} (${tookMs}ms, $contentType)")

        return response
    }
}
