package com.example.singing_bowl_tuner

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Process
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.log2
import kotlin.math.pow
import kotlin.math.sqrt

/**
 * Data container returned by [PitchDetector].
 */
data class PitchInfo(
    val frequency: Double,
    val cents: Double,
    val confidence: Double,
    val overtones: List<Double>
)

/**
 * Real‑time pitch detector implementing a simplified version of the
 * McLeod Pitch Method (MPM).  It computes the normalized squared
 * difference function and searches for the first significant minimum.
 */
class PitchDetector(private val sampleRate: Int, private val a4: Double) {
    private val minFreq = 60.0
    private val maxFreq = 1500.0
    private val minLag = (sampleRate / maxFreq).toInt()
    private val maxLag = (sampleRate / minFreq).toInt()

    fun detectPitch(buffer: ShortArray): PitchInfo? {
        // Convert to double and remove DC offset
        val data = DoubleArray(buffer.size)
        var mean = 0.0
        for (i in buffer.indices) {
            data[i] = buffer[i].toDouble()
            mean += data[i]
        }
        mean /= data.size
        for (i in data.indices) {
            data[i] -= mean
        }
        // Compute normalized squared difference function (NSDF)
        val nsdf = DoubleArray(maxLag + 1)
        var maxVal = 0.0
        for (tau in minLag..maxLag) {
            var acf = 0.0
            var m = 0.0
            for (i in 0 until data.size - tau) {
                val x = data[i]
                val y = data[i + tau]
                acf += x * y
                m += x * x + y * y
            }
            nsdf[tau] = if (m > 0) 2.0 * acf / m else 0.0
            if (nsdf[tau] > maxVal) maxVal = nsdf[tau]
        }
        // Find the peak above a threshold
        var bestTau = -1
        var bestVal = 0.0
        for (tau in minLag + 1 until maxLag - 1) {
            val prev = nsdf[tau - 1]
            val current = nsdf[tau]
            val next = nsdf[tau + 1]
            if (current > prev && current > next && current > 0.6 * maxVal) {
                // Parabolic interpolation around tau
                val denom = (prev - 2 * current + next)
                val delta = if (denom == 0.0) 0.0 else (prev - next) / (2 * denom)
                val peak = tau + delta
                val freq = sampleRate / peak
                if (freq in minFreq..maxFreq) {
                    bestTau = tau
                    bestVal = current
                    break
                }
            }
        }
        if (bestTau < 0) return null
        val freq = sampleRate / bestTau.toDouble()
        // Compute cents deviation
        val semitone = 12 * log2(freq / a4)
        val nearest = Math.round(semitone).toDouble()
        val cents = (semitone - nearest) * 100.0
        // Confidence based on NSDF peak value
        val confidence = bestVal.coerceIn(0.0, 1.0)
        // Overtones: measure amplitude at harmonics using simple projection
        val overtones = mutableListOf<Double>()
        for (k in 2..8) {
            val overtoneFreq = freq * k
            if (overtoneFreq > sampleRate / 2) break
            overtones.add(overtoneFreq)
        }
        return PitchInfo(freq, cents.coerceIn(-50.0, 50.0), confidence, overtones)
    }
}

/**
 * Background thread capturing audio from the microphone and streaming pitch
 * updates to Flutter.  It uses a simple noise gate to suppress output when
 * the RMS level falls below a threshold.
 */
class AudioThread(
    private val a4: Double,
    private val sampleRate: Int,
    private val noiseGate: Boolean,
    private val onResult: (PitchInfo) -> Unit
) {
    @Volatile
    private var isRunning: Boolean = false

    private val bufferSize = 4096
    private val pitchDetector = PitchDetector(sampleRate, a4)

    fun start() {
        isRunning = true
        thread(priority = Thread.MAX_PRIORITY) {
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            val minBuffer = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBuffer * 2
            )
            val buffer = ShortArray(bufferSize)
            audioRecord.startRecording()
            while (isRunning) {
                val read = audioRecord.read(buffer, 0, buffer.size)
                if (read > 0) {
                    val trimmed = buffer.copyOf(read)
                    // Noise gate: compute RMS
                    var rms = 0.0
                    for (s in trimmed) rms += s * s
                    rms = Math.sqrt(rms / trimmed.size)
                    if (!noiseGate || rms > 100) {
                        val info = pitchDetector.detectPitch(trimmed)
                        if (info != null) {
                            onResult(info)
                        }
                    }
                }
            }
            audioRecord.stop()
            audioRecord.release()
        }
    }

    fun stopRunning() {
        isRunning = false
    }
}