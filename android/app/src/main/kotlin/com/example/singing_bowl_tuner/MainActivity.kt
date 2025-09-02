package com.example.singing_bowl_tuner

import android.Manifest
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Process
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * Main activity hosting the Flutter UI and bridging native pitch detection.
 */
class MainActivity : FlutterActivity() {
    private val methodChannelName = "singing_bowl_tuner/method"
    private val eventChannelName = "singing_bowl_tuner/events"
    private var eventSink: EventChannel.EventSink? = null
    private var audioThread: AudioThread? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, methodChannelName).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "start" -> {
                    val a4 = (call.argument<Number>("a4") ?: 440.0).toDouble()
                    val sampleRate = (call.argument<Number>("sampleRate") ?: 48000).toInt()
                    val noiseGate = call.argument<Boolean>("noiseGate") ?: true
                    startListening(a4, sampleRate, noiseGate)
                    result.success(null)
                }
                "stop" -> {
                    stopListening()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, eventChannelName).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun startListening(a4: Double, sampleRate: Int, noiseGate: Boolean) {
        if (audioThread != null) return
        audioThread = AudioThread(a4, sampleRate, noiseGate) { info ->
            val map = HashMap<String, Any>()
            map["frequency"] = info.frequency
            map["cents"] = info.cents
            map["confidence"] = info.confidence
            map["overtones"] = info.overtones
            eventSink?.success(map)
        }
        audioThread?.start()
    }

    private fun stopListening() {
        audioThread?.stopRunning()
        audioThread = null
    }
}