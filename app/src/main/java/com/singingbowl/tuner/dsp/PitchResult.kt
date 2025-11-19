package com.singingbowl.tuner.dsp

data class PitchResult(
    val frequencyHz: Float,
    val clarity: Float,
    val isHarmonic: Boolean = false
)
