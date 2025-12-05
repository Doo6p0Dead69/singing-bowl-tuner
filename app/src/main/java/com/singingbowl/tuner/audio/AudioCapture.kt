package com.singingbowl.tuner.audio

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch

class AudioCapture(
    private val sampleRate: Int,
    private val frameSize: Int,
    private val dispatcher: CoroutineDispatcher,
) {
    fun start(): Flow<FloatArray> = callbackFlow {
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val bufferSize = maxOf(minBuffer, frameSize * 2)

        val recorder = AudioRecord(
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) MediaRecorder.AudioSource.UNPROCESSED else MediaRecorder.AudioSource.DEFAULT,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            close(IllegalStateException("AudioRecord not initialized"))
            return@callbackFlow
        }

        val scope = CoroutineScope(dispatcher)
        val shortBuffer = ShortArray(frameSize)

        recorder.startRecording()
        scope.launch {
            while (true) {
                val read = recorder.read(shortBuffer, 0, frameSize)
                if (read <= 0) continue
                val floats = FloatArray(read) { idx -> shortBuffer[idx] / Short.MAX_VALUE.toFloat() }
                trySend(floats)
            }
        }

        awaitClose {
            recorder.stop()
            recorder.release()
        }
    }
}
