package com.homelab.app.ui.jellystat

import android.content.Context
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.data.remote.dto.jellystat.JellystatWatchSummary
import com.homelab.app.data.repository.JellystatRepository
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
class JellystatViewModel @Inject constructor(
    private val repository: JellystatRepository,
    private val servicesRepository: ServicesRepository,
    savedStateHandle: SavedStateHandle,
    @param:ApplicationContext private val context: Context
) : ViewModel() {

    val instanceId: String = checkNotNull(savedStateHandle["instanceId"])

    private val _selectedDays = MutableStateFlow(30)
    val selectedDays: StateFlow<Int> = _selectedDays.asStateFlow()

    private val _uiState = MutableStateFlow<UiState<JellystatWatchSummary>>(UiState.Loading)
    val uiState: StateFlow<UiState<JellystatWatchSummary>> = _uiState.asStateFlow()

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    val instances: StateFlow<List<ServiceInstance>> = servicesRepository.instancesByType
        .map { it[ServiceType.JELLYSTAT].orEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        fetchSummary(forceLoading = true)
    }

    fun selectDays(days: Int) {
        val normalized = days.coerceIn(1, 3650)
        if (_selectedDays.value == normalized) return
        _selectedDays.value = normalized
        fetchSummary(forceLoading = false)
    }

    fun fetchSummary(forceLoading: Boolean = false) {
        viewModelScope.launch {
            if (forceLoading || _uiState.value !is UiState.Success) {
                _uiState.value = UiState.Loading
            }
            _isRefreshing.value = true
            try {
                val summary = repository.getWatchSummary(
                    instanceId = instanceId,
                    days = _selectedDays.value
                )
                _uiState.value = UiState.Success(summary)
            } catch (error: Exception) {
                _uiState.value = UiState.Error(
                    message = ErrorHandler.getMessage(context, error),
                    retryAction = { fetchSummary(forceLoading = true) }
                )
            } finally {
                _isRefreshing.value = false
            }
        }
    }

    fun setPreferredInstance(newInstanceId: String) {
        viewModelScope.launch {
            servicesRepository.setPreferredInstance(ServiceType.JELLYSTAT, newInstanceId)
        }
    }
}
