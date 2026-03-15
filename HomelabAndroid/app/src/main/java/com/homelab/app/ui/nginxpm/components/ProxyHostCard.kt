package com.homelab.app.ui.nginxpm.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.homelab.app.R
import com.homelab.app.data.remote.dto.nginxpm.NpmProxyHost
import com.homelab.app.ui.theme.StatusGreen
import com.homelab.app.ui.theme.StatusRed

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ProxyHostCard(
    proxyHost: NpmProxyHost,
    onClick: () -> Unit = {},
    onEdit: () -> Unit = {},
    onDelete: () -> Unit = {},
    onToggle: ((Boolean) -> Unit)? = null
) {
    var showMenu by remember { mutableStateOf(false) }

    val statusResId = when {
        !proxyHost.isEnabled -> R.string.npm_disabled
        proxyHost.isOnline -> R.string.home_status_online
        else -> R.string.home_status_offline
    }
    val statusColor = when {
        !proxyHost.isEnabled -> MaterialTheme.colorScheme.onSurfaceVariant
        proxyHost.isOnline -> StatusGreen
        else -> StatusRed
    }

    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = onClick,
                onLongClick = { showMenu = true }
            )
    ) {
        Box {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(statusColor)
                        )
                        Text(
                            text = proxyHost.primaryDomain,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = statusColor.copy(alpha = 0.1f)
                    ) {
                        Text(
                            text = stringResource(statusResId),
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = statusColor
                        )
                    }

                }

                if (proxyHost.domainNames.size > 1) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = proxyHost.domainNames.drop(1).joinToString(", "),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = proxyHost.forwardTarget,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    if (proxyHost.hasSSL) {
                        FeatureChip(icon = Icons.Default.Lock, text = "SSL")
                    }
                    if (proxyHost.http2Support == 1) {
                        FeatureChip(icon = Icons.Default.Speed, text = "HTTP/2")
                    }
                    if (proxyHost.cachingEnabled == 1) {
                        FeatureChip(icon = Icons.Default.Cached, text = stringResource(R.string.npm_cache))
                    }
                    if (proxyHost.blockExploits == 1) {
                        FeatureChip(icon = Icons.Default.Shield, text = stringResource(R.string.npm_block_exploits))
                    }
                }
            }

            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.edit)) },
                    onClick = { showMenu = false; onEdit() },
                    leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null) }
                )
                if (onToggle != null) {
                    DropdownMenuItem(
                        text = {
                            Text(
                                if (proxyHost.isEnabled) stringResource(R.string.npm_disabled)
                                else stringResource(R.string.npm_enabled)
                            )
                        },
                        onClick = { showMenu = false; onToggle(!proxyHost.isEnabled) },
                        leadingIcon = {
                            Icon(
                                if (proxyHost.isEnabled) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = null
                            )
                        }
                    )
                }
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.npm_delete)) },
                    onClick = { showMenu = false; onDelete() },
                    leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null) }
                )
            }
        }
    }
}

@Composable
fun FeatureChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String
) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                icon,
                contentDescription = text,
                modifier = Modifier.size(12.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
