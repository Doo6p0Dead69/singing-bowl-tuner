package com.singingbowl.tuner.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.singingbowl.tuner.audio.AudioCapture
import com.singingbowl.tuner.data.BowlRepository
import com.singingbowl.tuner.data.SettingsRepository

class TunerViewModelFactory(
    private val audioCapture: AudioCapture,
    private val bowlRepository: BowlRepository,
    private val settingsRepository: SettingsRepository
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return TunerViewModel(audioCapture, bowlRepository, settingsRepository) as T
    }
}
