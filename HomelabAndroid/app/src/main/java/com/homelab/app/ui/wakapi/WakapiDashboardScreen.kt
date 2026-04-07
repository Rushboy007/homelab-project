package com.homelab.app.ui.wakapi

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.Dns
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SettingsApplications
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.homelab.app.R
import com.homelab.app.data.remote.dto.wakapi.WakapiGrandTotal
import com.homelab.app.data.remote.dto.wakapi.WakapiStatItem
import com.homelab.app.data.remote.dto.wakapi.WakapiSummaryResponse
import com.homelab.app.data.repository.WakapiSummaryFilter
import com.homelab.app.ui.components.ServiceInstancePicker
import com.homelab.app.util.ServiceType
import com.homelab.app.util.UiState
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun WakapiDashboardScreen(
    viewModel: WakapiViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToInstance: (String) -> Unit
) {
    val state by viewModel.summaryState.collectAsStateWithLifecycle()
    val isRefreshing by viewModel.isRefreshing.collectAsStateWithLifecycle()
    val instances by viewModel.instances.collectAsStateWithLifecycle()
    val activeInterval by viewModel.selectedInterval.collectAsStateWithLifecycle()
    val activeFilter by viewModel.selectedFilter.collectAsStateWithLifecycle()

    val currentInstance = instances.find { it.id == viewModel.instanceId }
    val label = currentInstance?.label?.takeIf { it.isNotBlank() } ?: ServiceType.WAKAPI.displayName

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back)
                        )
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            Icons.Default.SettingsApplications,
                            contentDescription = stringResource(R.string.settings_title)
                        )
                    }
                    IconButton(onClick = { viewModel.fetchSummary(forceLoading = false) }) {
                        Icon(Icons.Default.Refresh, contentDescription = stringResource(R.string.refresh))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = isRefreshing,
            onRefresh = { viewModel.fetchSummary(forceLoading = true) },
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (val s = state) {
                is UiState.Loading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                is UiState.Error -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = s.message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.padding(24.dp)
                        )
                    }
                }
                is UiState.Success -> {
                    WakapiContent(
                        response = s.data,
                        activeInterval = activeInterval,
                        activeFilter = activeFilter,
                        onIntervalSelected = viewModel::setInterval,
                        onClearFilter = viewModel::clearFilter,
                        onApplyFilter = viewModel::setFilter,
                        instances = instances,
                        activeInstanceId = viewModel.instanceId,
                        onInstanceSelected = {
                            viewModel.setPreferredInstance(it.id)
                            onNavigateToInstance(it.id)
                        }
                    )
                }
                is UiState.Idle, is UiState.Offline -> Unit
            }
        }
    }
}

@Composable
private fun WakapiContent(
    response: WakapiSummaryResponse,
    activeInterval: String,
    activeFilter: WakapiSummaryFilter?,
    onIntervalSelected: (String) -> Unit,
    onClearFilter: () -> Unit,
    onApplyFilter: (WakapiSummaryFilter) -> Unit,
    instances: List<com.homelab.app.domain.model.ServiceInstance>,
    activeInstanceId: String,
    onInstanceSelected: (com.homelab.app.domain.model.ServiceInstance) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            ServiceInstancePicker(
                instances = instances,
                selectedInstanceId = activeInstanceId,
                onInstanceSelected = onInstanceSelected,
                label = stringResource(R.string.service_wakapi)
            )
        }

        item {
            WakapiIntervalSelector(
                activeInterval = activeInterval,
                onIntervalSelected = onIntervalSelected
            )
        }

        if (activeFilter != null) {
            item {
                ActiveFilterCard(filter = activeFilter, onClearFilter = onClearFilter)
            }
        }

        response.grandTotal?.let {
            item { WakapiGrandTotalCard(it) }
        }

        val languages = response.languages.orEmpty()
        if (languages.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_languages),
                    icon = Icons.Default.Code,
                    items = languages,
                    filterDimension = WakapiSummaryFilter.Dimension.LANGUAGE,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val projects = response.projects.orEmpty()
        if (projects.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_projects),
                    icon = Icons.Default.SettingsApplications,
                    items = projects,
                    filterDimension = WakapiSummaryFilter.Dimension.PROJECT,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val editors = response.editors.orEmpty()
        if (editors.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_editors),
                    icon = Icons.Default.Computer,
                    items = editors,
                    filterDimension = WakapiSummaryFilter.Dimension.EDITOR,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val machines = response.machines.orEmpty()
        if (machines.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_machines),
                    icon = Icons.Default.Dns,
                    items = machines,
                    filterDimension = WakapiSummaryFilter.Dimension.MACHINE,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val operatingSystems = response.operatingSystems.orEmpty()
        if (operatingSystems.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_operating_systems),
                    icon = Icons.Default.Computer,
                    items = operatingSystems,
                    filterDimension = WakapiSummaryFilter.Dimension.OPERATING_SYSTEM,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val labels = response.labels.orEmpty()
        if (labels.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_labels),
                    icon = Icons.Default.Code,
                    items = labels,
                    filterDimension = WakapiSummaryFilter.Dimension.LABEL,
                    activeFilter = activeFilter,
                    onApplyFilter = onApplyFilter
                )
            }
        }

        val categories = response.categories.orEmpty()
        if (categories.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_categories),
                    icon = Icons.Default.Timer,
                    items = categories
                )
            }
        }

        val branches = response.branches.orEmpty()
        if (branches.isNotEmpty()) {
            item {
                WakapiStatsCard(
                    title = stringResource(R.string.wakapi_section_branches),
                    icon = Icons.Default.Code,
                    items = branches
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WakapiIntervalSelector(
    activeInterval: String,
    onIntervalSelected: (String) -> Unit
) {
    val options = listOf(
        "today" to stringResource(R.string.wakapi_interval_today),
        "yesterday" to stringResource(R.string.wakapi_interval_yesterday),
        "last_7_days" to stringResource(R.string.wakapi_interval_last_7_days),
        "last_30_days" to stringResource(R.string.wakapi_interval_last_30_days),
        "last_6_months" to stringResource(R.string.wakapi_interval_last_6_months),
        "last_year" to stringResource(R.string.wakapi_interval_last_year),
        "all_time" to stringResource(R.string.wakapi_interval_all_time)
    )

    FlowRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        options.forEach { (value, label) ->
            FilterChip(
                selected = activeInterval == value,
                onClick = { onIntervalSelected(value) },
                label = {
                    Text(
                        text = label,
                        fontWeight = if (activeInterval == value) FontWeight.Bold else FontWeight.Normal
                    )
                }
            )
        }
    }
}

@Composable
private fun ActiveFilterCard(
    filter: WakapiSummaryFilter,
    onClearFilter: () -> Unit
) {
    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = stringResource(R.string.wakapi_active_filter),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = filter.value,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
            TextButton(onClick = onClearFilter) {
                Text(stringResource(R.string.wakapi_clear_filter))
            }
        }
    }
}

@Composable
private fun WakapiGrandTotalCard(grandTotal: WakapiGrandTotal) {
    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Timer,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            Text(
                text = stringResource(R.string.wakapi_total_time_coded),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = grandTotal.text ?: "${grandTotal.hours ?: 0}h ${grandTotal.minutes ?: 0}m",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun WakapiStatsCard(
    title: String,
    icon: ImageVector,
    items: List<WakapiStatItem>,
    filterDimension: WakapiSummaryFilter.Dimension? = null,
    activeFilter: WakapiSummaryFilter? = null,
    onApplyFilter: ((WakapiSummaryFilter) -> Unit)? = null
) {
    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            items.take(10).forEachIndexed { index, item ->
                val itemName = item.name ?: stringResource(R.string.wakapi_unknown)
                val appliedDimension = filterDimension
                val isFilterable = appliedDimension != null && onApplyFilter != null && item.name != null
                val isActiveFilter =
                    activeFilter?.dimension == filterDimension && activeFilter?.value == item.name

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .then(
                            if (isFilterable) {
                                Modifier.clickable {
                                    onApplyFilter?.invoke(
                                        WakapiSummaryFilter(
                                            dimension = appliedDimension ?: return@clickable,
                                            value = itemName
                                        )
                                    )
                                }
                            } else {
                                Modifier
                            }
                        )
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = itemName,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            text = item.text ?: "${item.hours ?: 0}h ${item.minutes ?: 0}m",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = "${item.percent?.roundToInt() ?: 0}%",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (isFilterable) {
                        IconButton(
                            onClick = {
                                onApplyFilter?.invoke(
                                    WakapiSummaryFilter(
                                        dimension = appliedDimension ?: return@IconButton,
                                        value = itemName
                                    )
                                )
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.FilterList,
                                contentDescription = stringResource(R.string.wakapi_apply_filter),
                                tint = if (isActiveFilter) {
                                    MaterialTheme.colorScheme.primary
                                } else {
                                    MaterialTheme.colorScheme.onSurfaceVariant
                                }
                            )
                        }
                    }
                }

                if (index < items.take(10).size - 1) {
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 4.dp),
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f)
                    )
                }
            }
        }
    }
}
