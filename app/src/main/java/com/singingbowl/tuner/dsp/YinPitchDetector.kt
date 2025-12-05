package com.singingbowl.tuner.dsp

import kotlin.math.min

class YinPitchDetector(
    private val sampleRate: Int,
    private val threshold: Float = 0.12f,
) {
    /**
     * Implementation of the YIN algorithm tuned for singing bowls where the onset is unstable.
     * The detector expects normalized mono audio frames.
     */
    fun detectPitch(buffer: FloatArray): PitchResult? {
        if (buffer.isEmpty()) return null
        val tauMax = buffer.size / 2
        if (tauMax < 2) return null

        val difference = FloatArray(tauMax)
        for (tau in 1 until tauMax) {
            var sum = 0f
            var i = 0
            val limit = buffer.size - tau
            while (i < limit) {
                val delta = buffer[i] - buffer[i + tau]
                sum += delta * delta
                i++
            }
            difference[tau] = sum
        }

        val cumulative = FloatArray(tauMax)
        cumulative[0] = 1f
        var runningSum = 0f
        for (tau in 1 until tauMax) {
            runningSum += difference[tau]
            cumulative[tau] = difference[tau] * tau / runningSum
        }

        var tauEstimate = -1
        for (tau in 2 until tauMax - 1) {
            if (cumulative[tau] < threshold && cumulative[tau] < cumulative[tau - 1]) {
                while (tau + 1 < tauMax && cumulative[tau + 1] < cumulative[tau]) {
                    tauEstimate = tau + 1
                    tau++
                }
                if (tauEstimate == -1) tauEstimate = tau
                break
            }
        }

        if (tauEstimate == -1) {
            val minValue = cumulative.sliceArray(1 until tauMax).minOrNull() ?: return null
            tauEstimate = cumulative.indexOfFirst { it == minValue }
        }

        val betterTau = parabolicInterpolation(cumulative, tauEstimate)
        val pitch = sampleRate / betterTau
        val clarity = 1f - min(1f, cumulative[tauEstimate])
        if (pitch <= 0f || pitch.isNaN()) return null
        return PitchResult(pitch, clarity)
    }

    private fun parabolicInterpolation(function: FloatArray, tauEstimate: Int): Float {
        if (tauEstimate <= 0 || tauEstimate >= function.lastIndex) return tauEstimate.toFloat()
        val s0 = function[tauEstimate - 1]
        val s1 = function[tauEstimate]
        val s2 = function[tauEstimate + 1]
        val adjustment = (s2 - s0) / (2 * (2 * s1 - s2 - s0))
        return tauEstimate + adjustment
    }
}
