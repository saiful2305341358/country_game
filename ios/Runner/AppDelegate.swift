import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static var sessionIntroPlayed: Bool = false
  private static let sessionIntroKey = "__session_intro_played__"
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

  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return .landscape
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
      case "preloadAll":
        if let args = call.arguments as? [String: Any],
           let sounds = args["sounds"] as? [String: FlutterStandardTypedData] {
          for (key, typedData) in sounds {
            self.wavCache[key] = typedData.data
          }
        }
        result(nil)
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
      case "stopAll":
        self.stopAllAudio()
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
        map[AppDelegate.sessionIntroKey] = AppDelegate.sessionIntroPlayed ? "1" : "0"
        result(map)
      case "setPref":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"] as? String {
          if key == AppDelegate.sessionIntroKey {
            AppDelegate.sessionIntroPlayed = (value == "1")
          } else {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: key)
            var keys = Set(defaults.stringArray(forKey: self.prefKeysKey) ?? [])
            keys.insert(key)
            defaults.set(Array(keys), forKey: self.prefKeysKey)
          }
        }
        result(nil)
      case "removePref":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          if key == AppDelegate.sessionIntroKey {
            AppDelegate.sessionIntroPlayed = false
          } else {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: key)
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
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
      // Ignore playback errors
    }
  }

  private func stopAllAudio() {
    for player in activePlayers {
      if player.isPlaying {
        player.stop()
      }
    }
    activePlayers.removeAll()
  }

  private func triggerHaptic(style: String) {
    switch style {
    case "light":
      lightImpactGenerator.prepare()
      lightImpactGenerator.impactOccurred()
    case "selection":
      selectionGenerator.prepare()
      selectionGenerator.selectionChanged()
    case "success":
      notificationGenerator.prepare()
      notificationGenerator.notificationOccurred(.success)
    case "warning":
      notificationGenerator.prepare()
      notificationGenerator.notificationOccurred(.warning)
    default:
      mediumImpactGenerator.prepare()
      mediumImpactGenerator.impactOccurred()
    }
  }
}
