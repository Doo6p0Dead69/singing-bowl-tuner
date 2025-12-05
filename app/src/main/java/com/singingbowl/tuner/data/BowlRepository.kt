package com.singingbowl.tuner.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class BowlRepository(
    private val dataStore: DataStore<Preferences>
) {
    private val bowlKey = stringPreferencesKey("saved_bowls")
    private val json = Json { ignoreUnknownKeys = true }

    val bowls: Flow<List<BowlProfile>> = dataStore.data.map { prefs ->
        prefs[bowlKey]?.let { stored ->
            runCatching { json.decodeFromString<List<BowlProfile>>(stored) }.getOrDefault(emptyList())
        } ?: emptyList()
    }

    suspend fun save(profile: BowlProfile) {
        dataStore.edit { prefs ->
            val current = prefs[bowlKey]?.let { existing ->
                runCatching { json.decodeFromString<List<BowlProfile>>(existing) }.getOrDefault(emptyList())
            } ?: emptyList()
            val updated = current + profile
            prefs[bowlKey] = json.encodeToString(updated)
        }
    }
}
