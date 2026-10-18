import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var activePlayers: [AVAudioPlayer] = []
  private var wavCache: [String: Data] = [:]
  private let prefKeysKey = "country_game_pref_keys_v1"

  private lazy var lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
  private lazy var mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
  private lazy var selectionGenerator = UISelectionFeedbackGenerator()
  private lazy var notificationGenerator = UINotificationFeedbackGenerator()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.example.country_game/native_feedback",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "playWav":
        if let args = call.arguments as? [String: Any] {
          let key = (args["key"] as? String) ?? "sfx"
          if let typedData = args["bytes"] as? FlutterStandardTypedData {
            self.wavCache[key] = typedData.data
            self.playWavData(typedData.data)
          } else if let cachedData = self.wavCache[key] {
            self.playWavData(cachedData)
          }
        }
        result(nil)
      case "vibrate":
        let args = call.arguments as? [String: Any]
        let style = (args?["style"] as? String) ?? "medium"
        self.triggerHaptic(style: style)
        result(nil)
      case "getAllPrefs":
        let defaults = UserDefaults.standard
        let keys = defaults.stringArray(forKey: self.prefKeysKey) ?? []
        var map: [String: String] = [:]
        for k in keys {
          if let val = defaults.string(forKey: k) {
            map[k] = val
          }
        }
        result(map)
      case "setPref":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"] as? String {
          let defaults = UserDefaults.standard
          defaults.set(value, forKey: key)
          var keys = Set(defaults.stringArray(forKey: self.prefKeysKey) ?? [])
          keys.insert(key)
          defaults.set(Array(keys), forKey: self.prefKeysKey)
        }
        result(nil)
      case "removePref":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let defaults = UserDefaults.standard
          defaults.removeObject(forKey: key)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Ignore audio session errors on simulator
    }
  }

  private func playWavData(_ data: Data) {
    do {
      activePlayers.removeAll { !$0.isPlaying }
      let player = try AVAudioPlayer(data: data)
      player.volume = 1.0
      player.prepareToPlay()
      player.play()
      activePlayers.append(player)
    } catch {
    }
  }

  private func triggerHaptic(style: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      switch style {
      case "light":
        self.lightImpactGenerator.prepare()
        self.lightImpactGenerator.impactOccurred()
      case "selection":
        self.selectionGenerator.prepare()
        self.selectionGenerator.selectionChanged()
      case "success":
        self.notificationGenerator.prepare()
        self.notificationGenerator.notificationOccurred(.success)
      case "warning":
        self.notificationGenerator.prepare()
        self.notificationGenerator.notificationOccurred(.warning)
      case "error":
        self.notificationGenerator.prepare()
        self.notificationGenerator.notificationOccurred(.error)
      default:
        self.mediumImpactGenerator.prepare()
        self.mediumImpactGenerator.impactOccurred()
      }
    }
  }
}
