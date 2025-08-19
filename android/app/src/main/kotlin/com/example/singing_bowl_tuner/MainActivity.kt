package com.example.singing_bowl_tuner

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity: FlutterActivity() {
  private var recorder: AudioRecord? = null
  private var worker: Thread? = null
  private var running = false
  private var eventSink: EventChannel.EventSink? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    EventChannel(flutterEngine.dartExecutor.binaryMessenger, "audio_stream/events").setStreamHandler(object: EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
      override fun onCancel(arguments: Any?) { eventSink = null }
    })
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "audio_stream/methods").setMethodCallHandler { call, result ->
      when (call.method) {
        "start" -> {
          val sr = (call.argument<Int>("sampleRate") ?: 48000)
          val bs = (call.argument<Int>("bufferSize") ?: 1024)
          startRecording(sr, bs)
          result.success(null)
        }
        "stop" -> { stopRecording(); result.success(null) }
        else -> result.notImplemented()
      }
    }
  }

  private fun startRecording(sampleRate: Int, bufferSize: Int) {
    stopRecording()
    var sr = sampleRate
    var minSize = AudioRecord.getMinBufferSize(sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
    if (minSize <= 0) {
      sr = 44100
      minSize = AudioRecord.getMinBufferSize(sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
    }
    val rec = AudioRecord(MediaRecorder.AudioSource.DEFAULT, sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, minSize*2)
    recorder = rec
    rec.startRecording()
    running = true
    worker = thread(start=true) {
      val frame = ByteArray(bufferSize * 2) // 16-bit mono
      while (running) {
        val read = rec.read(frame, 0, frame.size)
        if (read > 0 && eventSink != null) {
          val floats = FloatArray(read / 2)
          val bb = ByteBuffer.wrap(frame, 0, read).order(ByteOrder.LITTLE_ENDIAN)
          for (i in 0 until floats.size) {
            val s = bb.short.toInt()
            floats[i] = s / 32768.0f
          }
          eventSink!!.success(floats)
        }
      }
    }
  }

  private fun stopRecording() {
    running = false
    worker?.join(100)
    worker = null
    recorder?.stop()
    recorder?.release()
    recorder = null
  }
}
