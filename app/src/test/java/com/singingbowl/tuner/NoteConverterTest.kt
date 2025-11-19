package com.singingbowl.tuner

import com.singingbowl.tuner.dsp.NoteConverter
import org.junit.Assert.assertEquals
import org.junit.Test

class NoteConverterTest {
    @Test
    fun `maps frequency to nearest note with cents`() {
        val converter = NoteConverter(440f)
        val info = converter.frequencyToNote(442f)!!
        assertEquals("A", info.name)
        assertEquals(4, info.octave)
        assertEquals(true, info.cents > 0)
    }
}
