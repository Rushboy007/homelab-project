package com.homelab.app.ui.nginxpm.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.homelab.app.R
import com.homelab.app.data.remote.dto.nginxpm.NpmAccessList
import com.homelab.app.data.remote.dto.nginxpm.NpmCertificate

@Composable
fun DomainNamesInput(
    domains: List<String>,
    onDomainsChanged: (List<String>) -> Unit,
    modifier: Modifier = Modifier
) {
    var currentDomain by remember { mutableStateOf("") }

    Column(modifier = modifier) {
        Text(
            stringResource(R.string.npm_domain_names),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = currentDomain,
                onValueChange = { currentDomain = it.trim() },
                placeholder = { Text(stringResource(R.string.npm_domain_names_hint)) },
                singleLine = true,
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp)
            )
            FilledIconButton(
                onClick = {
                    if (currentDomain.isNotBlank() && currentDomain !in domains) {
                        onDomainsChanged(domains + currentDomain)
                        currentDomain = ""
                    }
                },
                enabled = currentDomain.isNotBlank()
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
            }
        }
        if (domains.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                for (domain in domains) {
                    InputChip(
                        selected = false,
                        onClick = { onDomainsChanged(domains - domain) },
                        label = { Text(domain) },
                        trailingIcon = {
                            Icon(Icons.Default.Close, contentDescription = null, modifier = Modifier.size(16.dp))
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun FormSwitch(
    label: String,
    checked: Boolean,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Switch(checked = checked, onCheckedChange = onCheckedChange, enabled = enabled)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SchemeDropdown(
    selected: String,
    onSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val options = listOf("http", "https")

    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }, modifier = modifier) {
        OutlinedTextField(
            value = selected,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.npm_forward_scheme)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable, enabled = true).fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            for (scheme in options) {
                DropdownMenuItem(
                    text = { Text(scheme) },
                    onClick = { onSelected(scheme); expanded = false }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CertificateDropdown(
    certificates: List<NpmCertificate>,
    selectedId: Int,
    onSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val display = if (selectedId == 0) stringResource(R.string.npm_certificate_none)
    else certificates.find { it.id == selectedId }?.niceName ?: stringResource(R.string.npm_certificate_none)

    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }, modifier = modifier) {
        OutlinedTextField(
            value = display,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.npm_certificate)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable, enabled = true).fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.npm_certificate_none)) },
                onClick = { onSelected(0); expanded = false }
            )
            for (cert in certificates) {
                DropdownMenuItem(
                    text = { Text(cert.niceName.ifBlank { cert.primaryDomain }) },
                    onClick = { onSelected(cert.id); expanded = false }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccessListDropdown(
    accessLists: List<NpmAccessList>,
    selectedId: Int,
    onSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val display = if (selectedId == 0) stringResource(R.string.npm_access_list_none)
    else accessLists.find { it.id == selectedId }?.name ?: stringResource(R.string.npm_access_list_none)

    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }, modifier = modifier) {
        OutlinedTextField(
            value = display,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.npm_access_list)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable, enabled = true).fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.npm_access_list_none)) },
                onClick = { onSelected(0); expanded = false }
            )
            for (al in accessLists) {
                DropdownMenuItem(
                    text = { Text(al.name) },
                    onClick = { onSelected(al.id); expanded = false }
                )
            }
        }
    }
}

@Composable
fun PortTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = value,
        onValueChange = { new -> onValueChange(new.filter { it.isDigit() }) },
        label = { Text(label) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    )
}
