package com.homelab.app.ui.backup

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homelab.app.R
import com.homelab.app.data.repository.LocalPreferencesRepository
import com.homelab.app.data.repository.ServiceInstancesRepository
import com.homelab.app.data.repository.ServicesRepository
import com.homelab.app.domain.manager.BackupManager
import com.homelab.app.domain.model.BackupServiceTypeMapper
import com.homelab.app.domain.model.ServiceInstance
import com.homelab.app.util.ServiceType
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import javax.inject.Inject

sealed class BackupUiState {
    object Main : BackupUiState()
    object Exporting : BackupUiState()

    // Import flow
    object ImportPasswordRequired : BackupUiState()
    object ImportDecrypting : BackupUiState()
    data class ImportPreview(val previewInfo: BackupManager.PreviewInfo) : BackupUiState()
    object ImportApplying : BackupUiState()
    object ImportSuccess : BackupUiState()

    // Error state
    data class Error(val message: String) : BackupUiState()
}

@HiltViewModel
class BackupViewModel @Inject constructor(
    private val backupManager: BackupManager,
    private val serviceInstancesRepository: ServiceInstancesRepository,
    private val servicesRepository: ServicesRepository,
    private val localPreferencesRepository: LocalPreferencesRepository,
    @param:ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow<BackupUiState>(BackupUiState.Main)
    val uiState: StateFlow<BackupUiState> = _uiState.asStateFlow()

    private var pendingImportData: ByteArray? = null

    // For one-off events
    private val _exportDataEvent = MutableStateFlow<ByteArray?>(null)
    val exportDataEvent: StateFlow<ByteArray?> = _exportDataEvent.asStateFlow()

    private val _instancesByType = MutableStateFlow<Map<ServiceType, List<ServiceInstance>>>(emptyMap())
    val instancesByType: StateFlow<Map<ServiceType, List<ServiceInstance>>> = _instancesByType.asStateFlow()

    private val _selectedExportTypes = MutableStateFlow<Set<ServiceType>>(emptySet())
    val selectedExportTypes: StateFlow<Set<ServiceType>> = _selectedExportTypes.asStateFlow()

    private val _rememberSelection = MutableStateFlow(true)
    val rememberSelection: StateFlow<Boolean> = _rememberSelection.asStateFlow()

    private val _selectedImportTypes = MutableStateFlow<Set<ServiceType>>(emptySet())
    val selectedImportTypes: StateFlow<Set<ServiceType>> = _selectedImportTypes.asStateFlow()

    private var exportSelectionInitialized = false

    init {
        viewModelScope.launch {
            combine(
                serviceInstancesRepository.instancesByType,
                localPreferencesRepository.backupSelectedServiceTypes,
                localPreferencesRepository.backupRememberSelectionEnabled
            ) { map, persistedSelection, rememberSelectionEnabled ->
                Triple(map, persistedSelection, rememberSelectionEnabled)
            }.collect { (map, persistedSelection, rememberSelectionEnabled) ->
                _instancesByType.value = map
                _rememberSelection.value = rememberSelectionEnabled
                val configured = configuredTypes(map)
                val current = _selectedExportTypes.value

                if (!exportSelectionInitialized && configured.isNotEmpty()) {
                    val restored = if (rememberSelectionEnabled) {
                        persistedSelection.intersect(configured)
                    } else {
                        emptySet()
                    }
                    val initial = if (restored.isNotEmpty()) restored else configured
                    _selectedExportTypes.value = initial
                    exportSelectionInitialized = true
                    persistSelectionIfEnabled(initial, rememberSelectionEnabled)
                } else {
                    val cleaned = current.intersect(configured)
                    if (cleaned != current) {
                        _selectedExportTypes.value = cleaned
                        persistSelectionIfEnabled(cleaned, rememberSelectionEnabled)
                    }
                }
            }
        }
    }

    fun onExportDataConsumed() {
        _exportDataEvent.value = null
    }

    fun dismissError() {
        _uiState.value = BackupUiState.Main
    }

    fun resetState() {
        pendingImportData = null
        _selectedImportTypes.value = emptySet()
        _uiState.value = BackupUiState.Main
    }

    fun toggleExportType(type: ServiceType) {
        if (type == ServiceType.UNKNOWN) return
        val configured = configuredTypes(_instancesByType.value)
        if (!configured.contains(type)) return
        val current = _selectedExportTypes.value.toMutableSet()
        if (current.contains(type)) {
            current.remove(type)
        } else {
            current.add(type)
        }
        _selectedExportTypes.value = current
        persistSelectionIfEnabled(current)
    }

    fun toggleAllExportTypes() {
        toggleExportGroup(configuredTypes(_instancesByType.value))
    }

    fun toggleHomeExportTypes() {
        val configuredHome = configuredTypes(_instancesByType.value).filterTo(mutableSetOf()) { it.isHomeService }
        toggleExportGroup(configuredHome)
    }

    fun toggleArrExportTypes() {
        val configuredArr = configuredTypes(_instancesByType.value).filterTo(mutableSetOf()) { it.isArrStack }
        toggleExportGroup(configuredArr)
    }

    fun setRememberSelection(enabled: Boolean) {
        viewModelScope.launch {
            localPreferencesRepository.setBackupRememberSelectionEnabled(enabled)
            if (enabled) {
                localPreferencesRepository.setBackupSelectedServiceTypes(_selectedExportTypes.value)
            } else {
                localPreferencesRepository.setBackupSelectedServiceTypes(emptySet())
            }
        }
    }

    fun startExport(password: String) {
        if (password.length < 6) {
            _uiState.value = BackupUiState.Error(context.getString(R.string.backupPasswordTooShort))
            return
        }
        val includedTypes = _selectedExportTypes.value
        if (includedTypes.isEmpty()) {
            _uiState.value = BackupUiState.Error(context.getString(R.string.backupSelectionRequired))
            return
        }
        _uiState.value = BackupUiState.Exporting
        viewModelScope.launch {
            try {
                val data = withContext(Dispatchers.IO) {
                    backupManager.exportBackup(password = password, includedTypes = includedTypes)
                }
                _exportDataEvent.value = data
                _uiState.value = BackupUiState.Main
            } catch (e: Exception) {
                _uiState.value = BackupUiState.Error(
                    context.getString(R.string.backupExportError, e.localizedMessage ?: "")
                )
            }
        }
    }

    fun onFileSelectedForImport(data: ByteArray) {
        pendingImportData = data
        _uiState.value = BackupUiState.ImportPasswordRequired
    }

    fun decryptAndPreview(password: String) {
        val data = pendingImportData ?: return
        if (password.isBlank()) {
            _uiState.value = BackupUiState.Error(context.getString(R.string.backupPasswordRequired))
            return
        }

        _uiState.value = BackupUiState.ImportDecrypting
        viewModelScope.launch {
            try {
                val info = withContext(Dispatchers.IO) { backupManager.decryptAndPreview(data, password) }
                _selectedImportTypes.value = availableImportTypes(info)
                _uiState.value = BackupUiState.ImportPreview(info)
            } catch (e: Exception) {
                _uiState.value = BackupUiState.Error(context.getString(R.string.backupDecryptError))
            }
        }
    }

    fun applyImport() {
        val currentState = _uiState.value
        if (currentState !is BackupUiState.ImportPreview) return
        val selectedTypes = _selectedImportTypes.value
        if (selectedTypes.isEmpty()) {
            _uiState.value = BackupUiState.Error(context.getString(R.string.backupSelectionRequired))
            return
        }

        _uiState.value = BackupUiState.ImportApplying
        viewModelScope.launch {
            try {
                backupManager.applyBackup(currentState.previewInfo.envelope, selectedTypes)
                servicesRepository.checkAllReachability(force = true)
                pendingImportData = null
                _uiState.value = BackupUiState.ImportSuccess
            } catch (e: Exception) {
                _uiState.value = BackupUiState.Error(
                    context.getString(R.string.backupApplyError, e.localizedMessage ?: "")
                )
            }
        }
    }

    fun toggleImportType(type: ServiceType) {
        val available = availableImportTypes()
        if (!available.contains(type)) return
        val current = _selectedImportTypes.value.toMutableSet()
        if (current.contains(type)) {
            current.remove(type)
        } else {
            current.add(type)
        }
        _selectedImportTypes.value = current
    }

    fun toggleAllImportTypes() {
        toggleImportGroup(availableImportTypes())
    }

    fun toggleHomeImportTypes() {
        val home = availableImportTypes().filterTo(mutableSetOf()) { it.isHomeService }
        toggleImportGroup(home)
    }

    fun toggleArrImportTypes() {
        val arr = availableImportTypes().filterTo(mutableSetOf()) { it.isArrStack }
        toggleImportGroup(arr)
    }

    private fun configuredTypes(map: Map<ServiceType, List<ServiceInstance>>): Set<ServiceType> {
        return map.entries
            .asSequence()
            .filter { (type, instances) -> type != ServiceType.UNKNOWN && instances.isNotEmpty() }
            .map { it.key }
            .toSet()
    }

    private fun toggleExportGroup(group: Set<ServiceType>) {
        if (group.isEmpty()) return
        val current = _selectedExportTypes.value
        val allSelected = group.all { current.contains(it) }
        val updated = if (allSelected) {
            current - group
        } else {
            current + group
        }
        _selectedExportTypes.value = updated
        persistSelectionIfEnabled(updated)
    }

    private fun persistSelectionIfEnabled(
        selection: Set<ServiceType>,
        rememberSelectionEnabled: Boolean = _rememberSelection.value
    ) {
        if (!rememberSelectionEnabled) return
        viewModelScope.launch {
            localPreferencesRepository.setBackupSelectedServiceTypes(selection)
        }
    }

    private fun toggleImportGroup(group: Set<ServiceType>) {
        if (group.isEmpty()) return
        val current = _selectedImportTypes.value
        val allSelected = group.all { current.contains(it) }
        _selectedImportTypes.value = if (allSelected) {
            current - group
        } else {
            current + group
        }
    }

    private fun availableImportTypes(
        preview: BackupManager.PreviewInfo? = (_uiState.value as? BackupUiState.ImportPreview)?.previewInfo
    ): Set<ServiceType> {
        val info = preview ?: return emptySet()
        return info.envelope.services
            .mapNotNull { BackupServiceTypeMapper.serviceType(it.type) }
            .toSet()
    }
}
