import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var audioEngine: AVAudioEngine?
    private var detector: PitchDetector?
    private var sampleRate: Double = 48000.0
    private var a4: Double = 440.0
    private var noiseGate: Bool = true

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: "singing_bowl_tuner/method", binaryMessenger: controller.binaryMessenger)
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            if call.method == "start" {
                if let args = call.arguments as? [String: Any] {
                    self.a4 = args["a4"] as? Double ?? 440.0
                    self.sampleRate = args["sampleRate"] as? Double ?? 48000.0
                    self.noiseGate = args["noiseGate"] as? Bool ?? true
                }
                self.startListening()
                result(nil)
            } else if call.method == "stop" {
                self.stopListening()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        let eventChannel = FlutterEventChannel(name: "singing_bowl_tuner/events", binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self)
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func startListening() {
        stopListening()
        detector = PitchDetector(sampleRate: sampleRate, a4: a4)
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        let input = engine.inputNode
        let bus = 0
        let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
        input.installTap(onBus: bus, bufferSize: 4096, format: desiredFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            let channelData = buffer.floatChannelData![0]
            let frameLength = Int(buffer.frameLength)
            let arr = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            var rms: Float = 0.0
            for s in arr { rms += s * s }
            rms = sqrt(rms / Float(frameLength))
            if !self.noiseGate || rms > 0.01 {
                if let info = self.detector?.detectPitch(arr) {
                    var event: [String: Any] = [:]
                    event["frequency"] = info.frequency
                    event["cents"] = info.cents
                    event["confidence"] = info.confidence
                    event["overtones"] = info.overtones
                    self.eventSink?(event)
                }
            }
        }
        do {
            try engine.start()
        } catch {
            print("AudioEngine start error: \(error)")
        }
    }

    private func stopListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    // FlutterStreamHandler implementation
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}