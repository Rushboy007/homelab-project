package com.homelab.app.ui.pangolin

import android.content.Context
import com.homelab.app.R
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.data.remote.dto.pangolin.PangolinClient
import com.homelab.app.data.remote.dto.pangolin.PangolinDomain
import com.homelab.app.data.remote.dto.pangolin.PangolinOrg
import com.homelab.app.data.remote.dto.pangolin.PangolinResource
import com.homelab.app.data.remote.dto.pangolin.PangolinSite
import com.homelab.app.data.remote.dto.pangolin.PangolinSiteResource
import com.homelab.app.data.remote.dto.pangolin.PangolinTarget
import com.homelab.app.data.repository.PangolinRepository
import com.homelab.app.data.repository.ServicesRepository
import com.homelab.app.domain.model.ServiceInstance
import com.homelab.app.util.ErrorHandler
import com.homelab.app.util.ServiceType
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.Job
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

data class PangolinDashboardData(
    val orgs: List<PangolinOrg>,
    val selectedOrgId: String,
    val sites: List<PangolinSite>,
    val siteResources: List<PangolinSiteResource>,
    val resources: List<PangolinResource>,
    val targetsByResourceId: Map<Int, List<PangolinTarget>>,
    val clients: List<PangolinClient>,
    val domains: List<PangolinDomain>
)

sealed interface PangolinUiState {
    data object Loading : PangolinUiState
    data class Success(val data: PangolinDashboardData) : PangolinUiState
    data class Error(val message: String) : PangolinUiState
}

@HiltViewModel
class PangolinViewModel @Inject constructor(
    private val repository: PangolinRepository,
    private val servicesRepository: ServicesRepository,
    savedStateHandle: SavedStateHandle,
    @param:ApplicationContext private val context: Context
) : ViewModel() {

    val instanceId: String = checkNotNull(savedStateHandle["instanceId"])

    private val _uiState = MutableStateFlow<PangolinUiState>(PangolinUiState.Loading)
    val uiState: StateFlow<PangolinUiState> = _uiState

    val instances: StateFlow<List<ServiceInstance>> = servicesRepository.instancesByType
        .map { it[ServiceType.PANGOLIN].orEmpty() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private var selectedOrgId: String? = null
    private var refreshJob: Job? = null

    init {
        refresh()
    }

    fun refresh(forceOrgId: String? = selectedOrgId) {
        refreshJob?.cancel()
        refreshJob = viewModelScope.launch {
            _uiState.value = PangolinUiState.Loading
            try {
                val orgs = repository.listOrgs(instanceId)
                val resolvedOrgId = forceOrgId?.takeIf { candidate -> orgs.any { it.orgId == candidate } }
                    ?: orgs.firstOrNull()?.orgId
                    ?: throw IllegalStateException(context.getString(R.string.pangolin_error_no_orgs))
                selectedOrgId = resolvedOrgId

                val snapshot = repository.getSnapshot(instanceId, resolvedOrgId, orgs)
                _uiState.value = PangolinUiState.Success(
                    PangolinDashboardData(
                        orgs = snapshot.orgs,
                        selectedOrgId = resolvedOrgId,
                        sites = snapshot.sites,
                        siteResources = snapshot.siteResources,
                        resources = snapshot.resources,
                        targetsByResourceId = snapshot.targetsByResourceId,
                        clients = snapshot.clients,
                        domains = snapshot.domains
                    )
                )
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                _uiState.value = PangolinUiState.Error(ErrorHandler.getMessage(context, error))
            }
        }
    }

    fun selectOrg(orgId: String) {
        if (orgId == selectedOrgId) return
        refresh(forceOrgId = orgId)
    }

    fun setPreferredInstance(newInstanceId: String) {
        viewModelScope.launch {
            servicesRepository.setPreferredInstance(ServiceType.PANGOLIN, newInstanceId)
        }
    }
}
