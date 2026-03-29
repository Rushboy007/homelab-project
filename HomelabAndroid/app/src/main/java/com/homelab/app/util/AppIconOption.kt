package com.homelab.app.util

import android.content.ComponentName
import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import com.homelab.app.R

enum class AppIconOption(
    val persistedValue: String,
    val aliasName: String,
    @DrawableRes val previewDrawableRes: Int,
    @StringRes val labelRes: Int
) {
    DEFAULT(
        persistedValue = "default",
        aliasName = ".launcher.DefaultIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_default,
        labelRes = R.string.settings_app_icon_default
    ),
    DARK(
        persistedValue = "dark",
        aliasName = ".launcher.DarkIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_dark,
        labelRes = R.string.settings_app_icon_dark
    ),
    CLEAR_LIGHT(
        persistedValue = "clear_light",
        aliasName = ".launcher.ClearLightIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_clear_light,
        labelRes = R.string.settings_app_icon_clear_light
    ),
    CLEAR_DARK(
        persistedValue = "clear_dark",
        aliasName = ".launcher.ClearDarkIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_clear_dark,
        labelRes = R.string.settings_app_icon_clear_dark
    ),
    TINTED_LIGHT(
        persistedValue = "tinted_light",
        aliasName = ".launcher.TintedLightIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_tinted_light,
        labelRes = R.string.settings_app_icon_tinted_light
    ),
    TINTED_DARK(
        persistedValue = "tinted_dark",
        aliasName = ".launcher.TintedDarkIconAlias",
        previewDrawableRes = R.drawable.ic_launcher_foreground_tinted_dark,
        labelRes = R.string.settings_app_icon_tinted_dark
    );

    fun componentName(packageName: String): ComponentName {
        return ComponentName(packageName, packageName + aliasName)
    }

    companion object {
        fun fromPersistedValue(value: String?): AppIconOption {
            if (value.isNullOrBlank()) return DEFAULT
            return entries.firstOrNull { it.persistedValue == value } ?: DEFAULT
        }
    }
}
