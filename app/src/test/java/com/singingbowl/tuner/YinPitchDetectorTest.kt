package com.singingbowl.tuner

import com.singingbowl.tuner.dsp.YinPitchDetector
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.sin

class YinPitchDetectorTest {
    @Test
    fun `detects sine frequency within tolerance`() {
        val sampleRate = 48_000
        val frequency = 196f
        val frameSize = 4096
        val samples = FloatArray(frameSize) { idx ->
            sin(2 * PI * frequency * idx / sampleRate).toFloat()
        }
        val detector = YinPitchDetector(sampleRate)
        val result = detector.detectPitch(samples)
        assertTrue(result != null && kotlin.math.abs(result.frequencyHz - frequency) < 1f)
    }
}
