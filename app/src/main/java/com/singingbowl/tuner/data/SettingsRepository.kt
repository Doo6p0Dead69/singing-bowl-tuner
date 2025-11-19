package com.singingbowl.tuner.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SettingsRepository(
    private val dataStore: DataStore<Preferences>
) {
    private val a4Key = floatPreferencesKey("a4_reference")

    val a4Reference: Flow<Float> = dataStore.data.map { prefs ->
        prefs[a4Key] ?: 440f
    }

    suspend fun setA4(value: Float) {
        dataStore.edit { prefs ->
            prefs[a4Key] = value
        }
    }
}
