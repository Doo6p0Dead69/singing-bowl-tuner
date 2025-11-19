package com.singingbowl.tuner.dsp

import kotlin.math.abs

class SignalQualityEstimator(
    private val noiseFloor: Float = 0.01f,
    private val peakCeiling: Float = 0.98f
) {
    fun level(samples: FloatArray): Float {
        if (samples.isEmpty()) return 0f
        val rms = kotlin.math.sqrt(samples.sumOf { (it * it).toDouble() } / samples.size).toFloat()
        return rms
    }

    fun isTooQuiet(samples: FloatArray): Boolean = level(samples) < noiseFloor

    fun isClipping(samples: FloatArray): Boolean = samples.any { abs(it) > peakCeiling }
}
