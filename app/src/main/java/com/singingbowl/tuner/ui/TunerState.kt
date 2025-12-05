package com.singingbowl.tuner.ui

data class TunerState(
    val isListening: Boolean = false,
    val frequencyHz: Float? = null,
    val note: String? = null,
    val cents: Float? = null,
    val clarity: Float = 0f,
    val a4Reference: Float = 440f,
    val warning: String? = null,
)
