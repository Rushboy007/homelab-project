package com.homelab.app.data.remote

import java.io.IOException

class HtmlResponseException(
    val url: String,
    val statusCode: Int,
    val contentType: String?,
    val snippet: String?
) : IOException("HTML response detected from $url (status $statusCode)")
