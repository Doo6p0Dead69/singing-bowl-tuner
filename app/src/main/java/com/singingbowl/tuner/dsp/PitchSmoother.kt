package com.singingbowl.tuner.dsp

import kotlin.math.abs

class PitchSmoother(
    private val stabilityTimeConstant: Float = 0.25f,
) {
    private var lastPitch: Float? = null

    fun smooth(newPitch: Float, framePeriodSeconds: Float): Float {
        val previous = lastPitch ?: run {
            lastPitch = newPitch
            return newPitch
        }
        val alpha = framePeriodSeconds / (stabilityTimeConstant + framePeriodSeconds)
        val blended = previous * (1 - alpha) + newPitch * alpha
        lastPitch = blended
        return blended
    }

    fun reset() {
        lastPitch = null
    }
}
