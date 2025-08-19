import AVFoundation
import Flutter
import UIKit

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  var engine = AVAudioEngine()
  var eventSink: FlutterEventSink?
  var sampleRate: Double = 48000
  var bufferSize: AVAudioFrameCount = 1024

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let event = FlutterEventChannel(name: "audio_stream/events", binaryMessenger: controller.binaryMessenger)
    event.setStreamHandler(self)
    let method = FlutterMethodChannel(name: "audio_stream/methods", binaryMessenger: controller.binaryMessenger)
    method.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      if call.method == "start" {
        let args = call.arguments as? [String: Any]
        self.sampleRate = Double(args?["sampleRate"] as? Int ?? 48000)
        self.bufferSize = AVAudioFrameCount(args?["bufferSize"] as? Int ?? 1024)
        self.start()
        result(nil)
      } else if call.method == "stop" {
        self.stop()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func start() {
    stop()
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
    try? session.setPreferredSampleRate(sampleRate)
    try? session.setActive(true, options: [])
    let actualRate = session.sampleRate
    sampleRate = actualRate

    let input = engine.inputNode
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] (buffer, time) in
      guard let self = self, let sink = self.eventSink else { return }
      let frames = Int(buffer.frameLength)
      let ptr = buffer.floatChannelData![0]
      let data = Data(bytes: ptr, count: frames * MemoryLayout<Float>.size)
      sink(FlutterStandardTypedData(float32: data))
    }
    engine.prepare()
    try? engine.start()
  }

  func stop() {
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events; return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil; return nil
  }
}
