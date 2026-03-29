package com.homelab.app.domain.manager

import com.homelab.app.BuildConfig
import com.homelab.app.data.repository.ServiceInstancesRepository
import com.homelab.app.domain.model.BackupEnvelope
import com.homelab.app.domain.model.BackupServiceTypeMapper
import com.homelab.app.domain.model.toBackupEntry
import com.homelab.app.domain.model.toServiceInstance
import com.homelab.app.util.BackupCrypto
import com.homelab.app.util.ServiceType
import kotlinx.coroutines.flow.first
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BackupManager @Inject constructor(
    private val repository: ServiceInstancesRepository
) {
    private val json = Json { ignoreUnknownKeys = true }

    data class PreviewInfo(
        val totalFound: Int,
        val unknownCount: Int,
        val envelope: BackupEnvelope
    )

    suspend fun exportBackup(password: String, includedTypes: Set<ServiceType>? = null): ByteArray {
        val instances = repository.getAllInstances()
        val filteredInstances = if (includedTypes.isNullOrEmpty()) {
            instances
        } else {
            instances.filter { includedTypes.contains(it.type) }
        }
        val preferredIdsByType = repository.preferredInstanceIdByType.first()

        val entries = filteredInstances.map { instance ->
            val isPref = preferredIdsByType[instance.type] == instance.id
            instance.toBackupEntry(isPreferred = isPref ?: false)
        }

        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val exportedAt = dateFormat.format(Date())

        val envelope = BackupEnvelope(
            version = BackupEnvelope.CURRENT_VERSION,
            exportedAt = exportedAt,
            appVersion = BuildConfig.VERSION_NAME,
            services = entries
        )

        val jsonString = json.encodeToString(envelope)
        val data = jsonString.toByteArray(Charsets.UTF_8)

        return BackupCrypto.encrypt(data, password)
    }

    fun decryptAndPreview(data: ByteArray, password: String): PreviewInfo {
        val decryptedData = BackupCrypto.decrypt(data, password)
        val jsonString = String(decryptedData, Charsets.UTF_8)
        val envelope = json.decodeFromString<BackupEnvelope>(jsonString)

        val knownCount = envelope.services.count { BackupServiceTypeMapper.serviceType(it.type) != null }
        val unknownCount = envelope.services.size - knownCount

        return PreviewInfo(
            totalFound = envelope.services.size,
            unknownCount = unknownCount,
            envelope = envelope
        )
    }

    suspend fun applyBackup(
        envelope: BackupEnvelope,
        selectedTypes: Set<ServiceType>
    ): Int {
        if (selectedTypes.isEmpty()) return 0

        val entriesByType = envelope.services
            .mapNotNull { entry ->
                val instance = entry.toServiceInstance() ?: return@mapNotNull null
                if (!selectedTypes.contains(instance.type)) return@mapNotNull null
                instance to entry.isPreferred
            }
            .groupBy(keySelector = { it.first.type }, valueTransform = { it })

        val typesToReplace = entriesByType.keys
        if (typesToReplace.isEmpty()) return 0

        // Only replace the selected service types that are present in this backup.
        val existing = repository.getAllInstances()
        for (instance in existing) {
            if (typesToReplace.contains(instance.type)) {
                repository.deleteInstance(instance.id)
            }
        }

        var importedCount = 0
        for (type in typesToReplace) {
            val entriesForType = entriesByType[type].orEmpty()
            var preferredId: String? = null

            for ((instance, isPreferred) in entriesForType) {
                repository.saveInstance(instance)
                importedCount += 1
                if (isPreferred) {
                    preferredId = instance.id
                }
            }

            when {
                preferredId != null -> repository.setPreferredInstance(type, preferredId)
                entriesForType.isNotEmpty() -> repository.setPreferredInstance(type, entriesForType.first().first.id)
                else -> repository.setPreferredInstance(type, null)
            }
        }

        return importedCount
    }
}
