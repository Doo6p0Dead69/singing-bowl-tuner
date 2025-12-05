package com.singingbowl.tuner.dsp

import kotlin.math.ln
import kotlin.math.roundToInt

class NoteConverter(
    private val a4Frequency: Float = 440f
) {
    fun updateA4(freq: Float): NoteConverter = NoteConverter(freq)

    fun frequencyToNote(frequency: Float): NoteInfo? {
        if (frequency <= 0f) return null
        val semitoneRatio = 12 * log2(frequency / a4Frequency) + 57 // 57 -> A4 midi number
        val midi = semitoneRatio.roundToInt()
        val cents = (semitoneRatio - midi) * 100
        val noteName = noteNameFromMidi(midi)
        val octave = (midi / 12) - 1
        return NoteInfo(noteName, octave, cents.toFloat(), frequency)
    }

    private fun log2(value: Float): Float = (ln(value.toDouble()) / ln(2.0)).toFloat()

    private fun noteNameFromMidi(midi: Int): String {
        val names = listOf("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
        val index = ((midi % 12) + 12) % 12
        return names[index]
    }
}

data class NoteInfo(
    val name: String,
    val octave: Int,
    val cents: Float,
    val frequency: Float
)
