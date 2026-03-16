package com.homelab.app.ui.beszel

import android.content.Context
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.data.remote.dto.beszel.BeszelContainer
import com.homelab.app.data.remote.dto.beszel.BeszelContainerRecord
import com.homelab.app.data.remote.dto.beszel.BeszelContainerStatsRecord
import com.homelab.app.data.remote.dto.beszel.BeszelRecordStats
import com.homelab.app.data.remote.dto.beszel.BeszelSmartDevice
import com.homelab.app.data.remote.dto.beszel.BeszelSystem
import com.homelab.app.data.remote.dto.beszel.BeszelSystemDetails
import com.homelab.app.data.remote.dto.beszel.BeszelSystemRecord
import com.homelab.app.data.repository.BeszelRepository
import com.homelab.app.data.repository.LocalPreferencesRepository
import com.homelab.app.data.repository.ServicesRepository
import com.homelab.app.domain.model.ServiceInstance
import com.homelab.app.util.ErrorHandler
import com.homelab.app.util.Logger
import com.homelab.app.util.ServiceType
import com.homelab.app.util.UiState
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

@HiltViewModel
class BeszelViewModel @Inject constructor(
    private val repository: BeszelRepository,
    private val servicesRepository: ServicesRepository,
    private val preferencesRepository: LocalPreferencesRepository,
    private val savedStateHandle: SavedStateHandle,
    @param:ApplicationContext private val context: Context
) : ViewModel() {
    private var systemDetailRequestToken: Long = 0

    val instanceId: String = checkNotNull(savedStateHandle["instanceId"])

    private val _systemsState = MutableStateFlow<UiState<List<BeszelSystem>>>(UiState.Loading)
    val systemsState: StateFlow<UiState<List<BeszelSystem>>> = _systemsState

    private val _systemDetailState = MutableStateFlow<UiState<BeszelSystem>>(UiState.Loading)
    val systemDetailState: StateFlow<UiState<BeszelSystem>> = _systemDetailState

    private val _systemDetails = MutableStateFlow<BeszelSystemDetails?>(null)
    val systemDetails: StateFlow<BeszelSystemDetails?> = _systemDetails

    private val _records = MutableStateFlow<List<BeszelSystemRecord>>(emptyList())
    val records: StateFlow<List<BeszelSystemRecord>> = _records

    private val _smartDevices = MutableStateFlow<List<BeszelSmartDevice>>(emptyList())
    val smartDevices: StateFlow<List<BeszelSmartDevice>> = _smartDevices

    val instances: StateFlow<List<ServiceInstance>> = servicesRepository.instancesByType
        .map { it[ServiceType.BESZEL].orEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    internal val systemDetailUiModel: StateFlow<BeszelSystemDetailUiModel?> = combine(
        _systemDetailState,
        _systemDetails,
        _records,
        _smartDevices
    ) { state, details, records, devices ->
        val system = (state as? UiState.Success)?.data ?: return@combine null
        buildSystemDetailUiModel(
            system = system,
            details = details,
            records = records,
            smartDevices = devices
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    init {
        _systemsState.onEach { Logger.stateTransition("BeszelViewModel", "systemsState", it) }
            .launchIn(viewModelScope)
        _systemDetailState.onEach { Logger.stateTransition("BeszelViewModel", "systemDetailState", it) }
            .launchIn(viewModelScope)
    }

    fun fetchSystems() {
        viewModelScope.launch {
            _systemsState.value = UiState.Loading
            try {
                _systemsState.value = UiState.Success(repository.getSystems(instanceId))
            } catch (error: Exception) {
                val message = ErrorHandler.getMessage(context, error)
                _systemsState.value = UiState.Error(message, retryAction = { fetchSystems() })
            }
        }
    }

    fun fetchSystemDetail(systemId: String) {
        viewModelScope.launch {
            val requestToken = ++systemDetailRequestToken
            _systemDetailState.value = UiState.Loading
            _systemDetails.value = null
            _records.value = emptyList()
            _smartDevices.value = emptyList()

            try {
                val system = repository.getSystem(instanceId, systemId)
                if (requestToken != systemDetailRequestToken) return@launch
                _systemDetailState.value = UiState.Success(system)

                launch {
                    try {
                        val details = repository.getSystemDetails(instanceId, systemId)
                        if (requestToken == systemDetailRequestToken) {
                            _systemDetails.value = details
                        }
                    } catch (_: Exception) {
                        if (requestToken == systemDetailRequestToken) {
                            _systemDetails.value = null
                        }
                    }
                }

                launch {
                    try {
                        val rawRecords = repository.getSystemRecords(instanceId, systemId, limit = 60)
                        if (requestToken == systemDetailRequestToken) {
                            _records.value = rawRecords.sortedBy { it.created }
                        }
                    } catch (_: Exception) {
                        if (requestToken == systemDetailRequestToken) {
                            _records.value = emptyList()
                        }
                    }
                }

                launch {
                    try {
                        val devices = repository.getSmartDevices(instanceId, systemId)
                        if (requestToken == systemDetailRequestToken) {
                            _smartDevices.value = devices
                        }
                    } catch (_: Exception) {
                        if (requestToken == systemDetailRequestToken) {
                            _smartDevices.value = emptyList()
                        }
                    }
                }
            } catch (error: Exception) {
                if (requestToken != systemDetailRequestToken) return@launch
                val message = ErrorHandler.getMessage(context, error)
                _systemDetailState.value = UiState.Error(message, retryAction = { fetchSystemDetail(systemId) })
            }
        }
    }

    // MARK: - Container list screen

    private val _containerRecordsState = MutableStateFlow<UiState<List<BeszelContainerRecord>>>(UiState.Idle)
    val containerRecordsState: StateFlow<UiState<List<BeszelContainerRecord>>> = _containerRecordsState

    private val _containerStats = MutableStateFlow<List<BeszelContainerStatsRecord>>(emptyList())
    val containerStats: StateFlow<List<BeszelContainerStatsRecord>> = _containerStats

    private val _containerStatsLoading = MutableStateFlow(false)
    val containerStatsLoading: StateFlow<Boolean> = _containerStatsLoading

    data class ContainerChartsVisibility(
        val cpu: Boolean = true,
        val memory: Boolean = true,
        val network: Boolean = true
    )

    val containerChartsVisibility: StateFlow<ContainerChartsVisibility> = combine(
        preferencesRepository.beszelShowCpu,
        preferencesRepository.beszelShowMemory,
        preferencesRepository.beszelShowNetwork
    ) { cpu, memory, network ->
        ContainerChartsVisibility(cpu = cpu, memory = memory, network = network)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ContainerChartsVisibility())

    fun updateContainerChartsVisibility(update: (ContainerChartsVisibility) -> ContainerChartsVisibility) {
        val next = update(containerChartsVisibility.value)
        viewModelScope.launch {
            preferencesRepository.setBeszelShowCpu(next.cpu)
            preferencesRepository.setBeszelShowMemory(next.memory)
            preferencesRepository.setBeszelShowNetwork(next.network)
        }
    }

    private val _containerLogs = MutableStateFlow<UiState<String>>(UiState.Idle)
    val containerLogs: StateFlow<UiState<String>> = _containerLogs

    private val _containerInfo = MutableStateFlow<UiState<String>>(UiState.Idle)
    val containerInfo: StateFlow<UiState<String>> = _containerInfo

    fun fetchContainers(systemId: String) {
        viewModelScope.launch {
            _containerRecordsState.value = UiState.Loading
            _containerStatsLoading.value = true
            try {
                coroutineScope {
                    val recordsDeferred = async { repository.getContainers(instanceId, systemId) }
                    val statsDeferred = async {
                        try {
                            repository.getContainerStats(instanceId, systemId, limit = 240)
                        } catch (_: Exception) {
                            emptyList()
                        }
                    }

                    val records = recordsDeferred.await()
                    _containerRecordsState.value = UiState.Success(
                        records.sortedBy { it.name.lowercase() }
                    )

                    val stats = statsDeferred.await()
                    _containerStats.value = stats

                    if (stats.isEmpty()) {
                        try {
                            val fallback = repository.getSystemRecords(instanceId, systemId, limit = 60)
                            _records.value = fallback.sortedBy { it.created }
                        } catch (_: Exception) {
                            _records.value = emptyList()
                        }
                    }
                }
            } catch (error: Exception) {
                val message = ErrorHandler.getMessage(context, error)
                _containerRecordsState.value = UiState.Error(message, retryAction = { fetchContainers(systemId) })
            } finally {
                _containerStatsLoading.value = false
            }
        }
    }

    fun fetchContainerLogs(systemId: String, containerId: String, containerName: String? = null) {
        viewModelScope.launch {
            _containerLogs.value = UiState.Loading
            try {
                val instance = servicesRepository.getInstance(instanceId)
                val token = instance?.token?.takeIf { it.isNotBlank() } ?: throw Exception("No token")
                val logs = try {
                    repository.getContainerLogs(instanceId, token, systemId, containerId)
                } catch (error: Exception) {
                    val http = error as? retrofit2.HttpException
                    if (http?.code() == 400 && !containerName.isNullOrBlank()) {
                        repository.getContainerLogs(instanceId, token, systemId, containerName)
                    } else {
                        throw error
                    }
                }
                _containerLogs.value = UiState.Success(logs)
            } catch (error: Exception) {
                val message = ErrorHandler.getMessage(context, error)
                _containerLogs.value = UiState.Error(message)
            }
        }
    }

    fun fetchContainerInfo(systemId: String, containerId: String, containerName: String? = null) {
        viewModelScope.launch {
            _containerInfo.value = UiState.Loading
            try {
                val instance = servicesRepository.getInstance(instanceId)
                val token = instance?.token?.takeIf { it.isNotBlank() } ?: throw Exception("No token")
                val info = try {
                    repository.getContainerInfo(instanceId, token, systemId, containerId)
                } catch (error: Exception) {
                    val http = error as? retrofit2.HttpException
                    if (http?.code() == 400 && !containerName.isNullOrBlank()) {
                        repository.getContainerInfo(instanceId, token, systemId, containerName)
                    } else {
                        throw error
                    }
                }
                _containerInfo.value = UiState.Success(info)
            } catch (error: Exception) {
                val message = ErrorHandler.getMessage(context, error)
                _containerInfo.value = UiState.Error(message)
            }
        }
    }

    fun resetContainerDetail() {
        _containerLogs.value = UiState.Idle
        _containerInfo.value = UiState.Idle
    }

    fun setPreferredInstance(newInstanceId: String) {
        viewModelScope.launch {
            servicesRepository.setPreferredInstance(ServiceType.BESZEL, newInstanceId)
        }
    }

    private fun buildSystemDetailUiModel(
        system: BeszelSystem,
        details: BeszelSystemDetails?,
        records: List<BeszelSystemRecord>,
        smartDevices: List<BeszelSmartDevice>
    ): BeszelSystemDetailUiModel {
        val info = system.info
        val statsHistory = records.map(BeszelSystemRecord::stats)
        val recentStats = statsHistory.takeLast(30)
        val latestStats = statsHistory.lastOrNull()
        val diskUsedGb = (latestStats?.duValue ?: info?.duValue)?.takeIf { it > 0.0 }
        val diskTotalGb = (latestStats?.dValue ?: info?.dValue)?.takeIf { it > 0.0 }
        val memoryUsedGb = latestStats?.memoryUsedGb
        val memoryTotalGb = latestStats?.memoryTotalGb ?: info?.mValue?.takeIf { it > 0.0 }
        val externalFileSystems = latestStats?.efs
            ?.mapNotNull { (label, entry) ->
                val total = entry.d ?: return@mapNotNull null
                val used = entry.du ?: return@mapNotNull null
                if (total <= 0.0 || used < 0.0) return@mapNotNull null
                DiskFsUsage(label = label, usedGb = used, totalGb = total)
            }
            .orEmpty()
        val dockerSummary = latestStats?.dockerSummary
        val dockerUploadRateHistory = recentStats.containerSeries { it.bandwidthUpBytesPerSec }
        val dockerDownloadRateHistory = recentStats.containerSeries { it.bandwidthDownBytesPerSec }

        return BeszelSystemDetailUiModel(
            system = system,
            systemDetails = details,
            statsHistory = statsHistory,
            latestStats = latestStats,
            smartDevices = smartDevices,
            cpuHistoryPercent = recentStats.map { it.cpuValue },
            memoryHistoryPercent = recentStats.map { it.mpValue },
            memoryUsedHistoryGb = recentStats.mapNotNull { it.memoryUsedGb },
            diskUsedGb = diskUsedGb,
            diskTotalGb = diskTotalGb,
            memoryUsedGb = memoryUsedGb,
            memoryTotalGb = memoryTotalGb,
            externalFileSystems = externalFileSystems,
            dockerSummary = dockerSummary,
            dockerCpuHistoryPercent = recentStats.containerSeries { it.cpuValue },
            dockerMemoryUsedHistoryMb = recentStats.containerSeries { it.mValue },
            dockerUploadRateHistoryBytesPerSec = dockerUploadRateHistory,
            dockerDownloadRateHistoryBytesPerSec = dockerDownloadRateHistory,
            hasDockerNetwork = dockerSummary?.let { summary ->
                summary.uploadRateBytesPerSec != null &&
                    summary.downloadRateBytesPerSec != null &&
                    dockerUploadRateHistory.isNotEmpty() &&
                    dockerDownloadRateHistory.size == dockerUploadRateHistory.size
            } == true,
            containers = latestStats?.dc.orEmpty(),
            perCoreCpuPercent = latestStats?.cpuCoreUsageValues.orEmpty()
        )
    }
}

private val BeszelRecordStats.dockerSummary: DockerMetricSummary?
    get() = dc?.takeIf { it.isNotEmpty() }?.toDockerMetricSummary()

private fun List<BeszelRecordStats>.containerSeries(
    selector: (BeszelContainer) -> Double?
): List<Double> = mapNotNull { stats ->
    stats.dc?.sumNullable(selector)
}

private fun List<BeszelContainer>.toDockerMetricSummary(): DockerMetricSummary = DockerMetricSummary(
    cpuPercent = sumOf(BeszelContainer::cpuValue),
    memoryUsedMb = sumOf(BeszelContainer::mValue),
    uploadRateBytesPerSec = sumNullable(BeszelContainer::bandwidthUpBytesPerSec),
    downloadRateBytesPerSec = sumNullable(BeszelContainer::bandwidthDownBytesPerSec)
)

private fun List<BeszelContainer>.sumNullable(
    selector: (BeszelContainer) -> Double?
): Double? = mapNotNull(selector).takeIf { it.isNotEmpty() }?.sum()
