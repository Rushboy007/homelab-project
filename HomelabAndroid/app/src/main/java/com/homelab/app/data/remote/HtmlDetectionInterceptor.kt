package com.homelab.app.data.remote

import com.homelab.app.util.Logger
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class HtmlDetectionInterceptor @Inject constructor() : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)

        val contentType = response.header("Content-Type")?.lowercase()
        val isHtmlContentType = contentType?.contains("text/html") == true ||
            contentType?.contains("application/xhtml+xml") == true

        val snippet = runCatching { response.peekBody(2048).string() }.getOrNull()
        val looksLikeHtml = snippet
            ?.trimStart()
            ?.startsWith("<!doctype html", ignoreCase = true) == true ||
            snippet
                ?.trimStart()
                ?.startsWith("<html", ignoreCase = true) == true

        val isJsonContentType = contentType?.contains("application/json") == true

        if (isHtmlContentType || (looksLikeHtml && !isJsonContentType)) {
            Logger.w("Network", "HTML response detected for ${request.method} ${request.url}")
            response.close()
            throw HtmlResponseException(
                url = request.url.toString(),
                statusCode = response.code,
                contentType = contentType,
                snippet = snippet
            )
        }

        return response
    }
}
