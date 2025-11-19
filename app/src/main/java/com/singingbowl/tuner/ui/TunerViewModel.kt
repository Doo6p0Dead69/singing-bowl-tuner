package com.singingbowl.tuner.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.singingbowl.tuner.audio.AudioCapture
import com.singingbowl.tuner.data.BowlProfile
import com.singingbowl.tuner.data.BowlRepository
import com.singingbowl.tuner.data.SettingsRepository
import com.singingbowl.tuner.dsp.NoteConverter
import com.singingbowl.tuner.dsp.PitchSmoother
import com.singingbowl.tuner.dsp.SignalQualityEstimator
import com.singingbowl.tuner.dsp.YinPitchDetector
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class TunerViewModel(
    private val audioCapture: AudioCapture,
    private val bowlRepository: BowlRepository,
    private val settingsRepository: SettingsRepository,
    private val dispatcher: CoroutineDispatcher = Dispatchers.Default,
) : ViewModel() {

    private val detector = YinPitchDetector(sampleRate = SAMPLE_RATE)
    private val smoother = PitchSmoother()
    private val signalQualityEstimator = SignalQualityEstimator()
    private var noteConverter = NoteConverter()

    private val mutableState = MutableStateFlow(TunerState())
    val state: StateFlow<TunerState> = mutableState

    val bowls: StateFlow<List<BowlProfile>> = bowlRepository.bowls
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private var listenJob: Job? = null

    init {
        viewModelScope.launch {
            settingsRepository.a4Reference.collect { a4 ->
                noteConverter = noteConverter.updateA4(a4)
                mutableState.value = mutableState.value.copy(a4Reference = a4)
            }
        }
    }

    fun toggleListening() {
        if (mutableState.value.isListening) {
            stopListening()
        } else {
            startListening()
        }
    }

    private fun startListening() {
        if (listenJob != null) return
        mutableState.value = mutableState.value.copy(isListening = true, warning = null)
        listenJob = viewModelScope.launch(dispatcher) {
            audioCapture.start().collect { frame ->
                val warning = when {
                    signalQualityEstimator.isTooQuiet(frame) -> "Слишком низкий уровень сигнала"
                    signalQualityEstimator.isClipping(frame) -> "Сильный шум окружения"
                    else -> null
                }
                val detection = detector.detectPitch(frame)
                val frameSeconds = frame.size.toFloat() / SAMPLE_RATE
                val smoothed = detection?.frequencyHz?.let { smoother.smooth(it, frameSeconds) }
                val note = smoothed?.let { freq -> noteConverter.frequencyToNote(freq) }
                mutableState.value = mutableState.value.copy(
                    frequencyHz = smoothed,
                    note = note?.let { "${it.name}${it.octave}" },
                    cents = note?.cents,
                    clarity = detection?.clarity ?: 0f,
                    warning = warning
                )
            }
        }
    }

    private fun stopListening() {
        listenJob?.cancel()
        listenJob = null
        smoother.reset()
        mutableState.value = mutableState.value.copy(isListening = false)
    }

    fun saveBowl(name: String) {
        val freq = state.value.frequencyHz ?: return
        val note = state.value.note ?: return
        val cents = state.value.cents ?: 0f
        viewModelScope.launch {
            bowlRepository.save(BowlProfile(name, freq, note, cents))
        }
    }

    fun setA4Reference(value: Float) {
        viewModelScope.launch {
            settingsRepository.setA4(value)
        }
    }

    companion object {
        const val SAMPLE_RATE = 48000
    }
}
