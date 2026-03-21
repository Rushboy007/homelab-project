package com.homelab.app.ui.patchmon

import android.content.Context
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.data.remote.dto.patchmon.PatchmonHost
import com.homelab.app.data.repository.PatchmonRepository
import com.homelab.app.data.repository.ServicesRepository
import com.homelab.app.domain.model.ServiceInstance
import com.homelab.app.util.ErrorHandler
import com.homelab.app.util.ServiceType
import com.homelab.app.util.UiState
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class PatchmonViewModel @Inject constructor(
    private val patchmonRepository: PatchmonRepository,
    private val servicesRepository: ServicesRepository,
    savedStateHandle: SavedStateHandle,
    @param:ApplicationContext private val context: Context
) : ViewModel() {

    data class DashboardSummary(
        val totalHosts: Int = 0,
        val activeHosts: Int = 0,
        val securityUpdates: Int = 0,
        val rebootRequired: Int = 0
    )

    val instanceId: String = checkNotNull(savedStateHandle["instanceId"])

    private val _hostsState = MutableStateFlow<UiState<List<PatchmonHost>>>(UiState.Loading)
    val hostsState: StateFlow<UiState<List<PatchmonHost>>> = _hostsState.asStateFlow()

    private val _selectedGroup = MutableStateFlow<String?>(null)
    val selectedGroup: StateFlow<String?> = _selectedGroup.asStateFlow()

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    val instances: StateFlow<List<ServiceInstance>> = servicesRepository.instancesByType
        .map { it[ServiceType.PATCHMON].orEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val dashboardSummary: StateFlow<DashboardSummary> = hostsState
        .map { state ->
            val hosts = (state as? UiState.Success)?.data.orEmpty()
            DashboardSummary(
                totalHosts = hosts.size,
                activeHosts = hosts.count { it.status.equals("active", ignoreCase = true) },
                securityUpdates = hosts.sumOf { it.securityUpdatesCount },
                rebootRequired = hosts.count { it.needsReboot }
            )
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DashboardSummary())

    val availableGroups: StateFlow<List<String>> = hostsState
        .map { state ->
            val hosts = (state as? UiState.Success)?.data.orEmpty()
            hosts.flatMap { host -> host.hostGroups.map { it.name } }
                .filter { it.isNotBlank() }
                .distinct()
                .sorted()
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        val cached = patchmonRepository.peekHosts(instanceId = instanceId, hostGroup = null)
        if (cached != null) {
            _hostsState.value = UiState.Success(sortHostsForDashboard(cached.hosts))
        }
        fetchHosts(forceLoading = cached == null)
    }

    fun fetchHosts(forceLoading: Boolean = false) {
        viewModelScope.launch {
            if (forceLoading || _hostsState.value !is UiState.Success) {
                _hostsState.value = UiState.Loading
            }
            _isRefreshing.value = true
            try {
                val response = patchmonRepository.getHosts(
                    instanceId = instanceId,
                    hostGroup = _selectedGroup.value
                )
                _hostsState.value = UiState.Success(sortHostsForDashboard(response.hosts))
            } catch (error: Exception) {
                _hostsState.value = UiState.Error(
                    message = ErrorHandler.getMessage(context, error),
                    retryAction = { fetchHosts(forceLoading = true) }
                )
            } finally {
                _isRefreshing.value = false
            }
        }
    }

    fun selectGroup(group: String?) {
        val cleaned = group?.trim()?.takeIf { it.isNotEmpty() }
        if (_selectedGroup.value == cleaned) return
        _selectedGroup.value = cleaned
        val cached = patchmonRepository.peekHosts(instanceId = instanceId, hostGroup = cleaned)
        if (cached != null) {
            _hostsState.value = UiState.Success(sortHostsForDashboard(cached.hosts))
        }
        fetchHosts(forceLoading = false)
    }

    fun setPreferredInstance(newInstanceId: String) {
        viewModelScope.launch {
            servicesRepository.setPreferredInstance(ServiceType.PATCHMON, newInstanceId)
        }
    }

    private fun sortHostsForDashboard(hosts: List<PatchmonHost>): List<PatchmonHost> {
        return hosts.sortedByDescending { host ->
            host.securityUpdatesCount * 1000 + host.updatesCount
        }
    }
}
