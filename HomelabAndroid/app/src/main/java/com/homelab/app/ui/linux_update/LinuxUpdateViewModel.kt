package com.homelab.app.ui.linux_update

import android.content.Context
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.data.remote.dto.linux_update.LinuxUpdateDashboardStats
import com.homelab.app.data.remote.dto.linux_update.LinuxUpdateSystem
import com.homelab.app.data.repository.LinuxUpdateSystemDetail
import com.homelab.app.data.repository.LinuxUpdateRepository
import com.homelab.app.data.repository.ServicesRepository
import com.homelab.app.domain.model.ServiceInstance
import com.homelab.app.util.ErrorHandler
import com.homelab.app.util.ServiceType
import com.homelab.app.util.UiState
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class LinuxUpdateViewModel @Inject constructor(
    private val repository: LinuxUpdateRepository,
    private val servicesRepository: ServicesRepository,
    savedStateHandle: SavedStateHandle,
    @param:ApplicationContext private val context: Context
) : ViewModel() {

    data class DashboardContent(
        val stats: LinuxUpdateDashboardStats,
        val systems: List<LinuxUpdateSystem>
    )

    enum class Filter {
        ALL,
        UPDATES,
        ISSUES,
        REBOOT
    }

    enum class SystemAction {
        CHECK,
        UPGRADE_ALL,
        FULL_UPGRADE,
        REBOOT
    }

    enum class DashboardAction {
        CHECK_ALL,
        REFRESH_CACHE
    }

    val instanceId: String = checkNotNull(savedStateHandle["instanceId"])

    private val _uiState = MutableStateFlow<UiState<DashboardContent>>(UiState.Loading)
    val uiState: StateFlow<UiState<DashboardContent>> = _uiState.asStateFlow()

    private val _selectedFilter = MutableStateFlow(Filter.ALL)
    val selectedFilter: StateFlow<Filter> = _selectedFilter.asStateFlow()

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    private val _selectedSystemId = MutableStateFlow<Int?>(null)
    val selectedSystemId: StateFlow<Int?> = _selectedSystemId.asStateFlow()

    private val _detailState = MutableStateFlow<UiState<LinuxUpdateSystemDetail>>(UiState.Idle)
    val detailState: StateFlow<UiState<LinuxUpdateSystemDetail>> = _detailState.asStateFlow()

    private val _isRunningAction = MutableStateFlow(false)
    val isRunningAction: StateFlow<Boolean> = _isRunningAction.asStateFlow()

    private val _messages = MutableSharedFlow<String>(extraBufferCapacity = 1)
    val messages = _messages.asSharedFlow()

    private val _isRunningDashboardAction = MutableStateFlow(false)
    val isRunningDashboardAction: StateFlow<Boolean> = _isRunningDashboardAction.asStateFlow()

    val instances: StateFlow<List<ServiceInstance>> = servicesRepository.instancesByType
        .map { it[ServiceType.LINUX_UPDATE].orEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val filteredSystems: StateFlow<List<LinuxUpdateSystem>> = combine(uiState, selectedFilter) { state, filter ->
        val systems = (state as? UiState.Success)?.data?.systems.orEmpty()
        when (filter) {
            Filter.ALL -> systems
            Filter.UPDATES -> systems.filter { it.updateCount > 0 }
            Filter.ISSUES -> systems.filter { it.hasCheckIssue || it.isReachableFlag == false }
            Filter.REBOOT -> systems.filter { it.needsRebootFlag }
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        fetchDashboard(forceLoading = true)
    }

    fun fetchDashboard(forceLoading: Boolean = false) {
        viewModelScope.launch {
            if (forceLoading || _uiState.value !is UiState.Success) {
                _uiState.value = UiState.Loading
            }
            _isRefreshing.value = true
            try {
                val content = coroutineScope {
                    val stats = async { repository.getDashboardStats(instanceId = instanceId) }
                    val systems = async { repository.getDashboardSystems(instanceId = instanceId) }
                    DashboardContent(
                        stats = stats.await(),
                        systems = systems.await()
                    )
                }
                _uiState.value = UiState.Success(content)

                val currentSelectedId = _selectedSystemId.value
                if (currentSelectedId != null && content.systems.none { it.id == currentSelectedId }) {
                    closeSystemDetail()
                }
            } catch (error: Exception) {
                _uiState.value = UiState.Error(
                    message = ErrorHandler.getMessage(context, error),
                    retryAction = { fetchDashboard(forceLoading = true) }
                )
            } finally {
                _isRefreshing.value = false
            }
        }
    }

    fun selectFilter(filter: Filter) {
        _selectedFilter.value = filter
    }

    fun openSystemDetail(systemId: Int) {
        if (_selectedSystemId.value != systemId) {
            _selectedSystemId.value = systemId
            _detailState.value = UiState.Loading
        }
        refreshSystemDetail(forceLoading = true)
    }

    fun closeSystemDetail() {
        _selectedSystemId.value = null
        _detailState.value = UiState.Idle
    }

    fun refreshSystemDetail(forceLoading: Boolean = false) {
        val systemId = _selectedSystemId.value ?: return
        viewModelScope.launch {
            if (forceLoading || _detailState.value !is UiState.Success) {
                _detailState.value = UiState.Loading
            }

            try {
                val detail = repository.getSystemDetail(instanceId = instanceId, systemId = systemId)
                _detailState.value = UiState.Success(detail)
            } catch (error: Exception) {
                _detailState.value = UiState.Error(
                    message = ErrorHandler.getMessage(context, error),
                    retryAction = { refreshSystemDetail(forceLoading = true) }
                )
            }
        }
    }

    fun runSystemAction(action: SystemAction) {
        val systemId = _selectedSystemId.value ?: return
        if (_isRunningAction.value) return

        viewModelScope.launch {
            _isRunningAction.value = true
            try {
                val result = when (action) {
                    SystemAction.CHECK -> repository.runCheck(instanceId = instanceId, systemId = systemId)
                    SystemAction.UPGRADE_ALL -> repository.runUpgradeAll(instanceId = instanceId, systemId = systemId)
                    SystemAction.FULL_UPGRADE -> repository.runFullUpgrade(instanceId = instanceId, systemId = systemId)
                    SystemAction.REBOOT -> repository.rebootSystem(instanceId = instanceId, systemId = systemId)
                }
                _messages.tryEmit(result.message)
                fetchDashboard(forceLoading = false)
                refreshSystemDetail(forceLoading = false)
            } catch (error: Exception) {
                _messages.tryEmit(ErrorHandler.getMessage(context, error))
            } finally {
                _isRunningAction.value = false
            }
        }
    }

    fun runPackageUpgrade(packageName: String) {
        val systemId = _selectedSystemId.value ?: return
        if (_isRunningAction.value) return

        viewModelScope.launch {
            _isRunningAction.value = true
            try {
                val result = repository.runUpgradePackage(
                    instanceId = instanceId,
                    systemId = systemId,
                    packageName = packageName
                )
                _messages.tryEmit(result.message)
                fetchDashboard(forceLoading = false)
                refreshSystemDetail(forceLoading = false)
            } catch (error: Exception) {
                _messages.tryEmit(ErrorHandler.getMessage(context, error))
            } finally {
                _isRunningAction.value = false
            }
        }
    }

    fun runDashboardAction(action: DashboardAction) {
        if (_isRunningDashboardAction.value) return

        viewModelScope.launch {
            _isRunningDashboardAction.value = true
            try {
                val result = when (action) {
                    DashboardAction.CHECK_ALL -> repository.runCheckAll(instanceId = instanceId)
                    DashboardAction.REFRESH_CACHE -> repository.runRefreshCache(instanceId = instanceId)
                }
                _messages.tryEmit(result.message)
                fetchDashboard(forceLoading = false)
                if (_selectedSystemId.value != null) {
                    refreshSystemDetail(forceLoading = false)
                }
            } catch (error: Exception) {
                _messages.tryEmit(ErrorHandler.getMessage(context, error))
            } finally {
                _isRunningDashboardAction.value = false
            }
        }
    }

    fun setPreferredInstance(newInstanceId: String) {
        viewModelScope.launch {
            servicesRepository.setPreferredInstance(ServiceType.LINUX_UPDATE, newInstanceId)
        }
    }
}
