package com.example.country_game

import android.content.Context
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.country_game/native_feedback"
    private val prefsName = "country_game_prefs"
    private val sampleRate = 22050
    private val pcmCache = ConcurrentHashMap<String, ByteArray>()
    private val audioScheduler = Executors.newScheduledThreadPool(2)

    private val gameAudioAttributes: AudioAttributes by lazy {
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    private val monoPcmFormat: AudioFormat by lazy {
        AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
    }

    @Suppress("DEPRECATION")
    private val hardwareVibrator: Vibrator? by lazy {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                manager?.defaultVibrator
            } else {
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (_: Throwable) {
            null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply sensorLandscape lock and shortEdges cutout mode before super.onCreate
        // so the native launch splash window initializes immediately in fullscreen landscape.
        enforceLandscapeAndImmersiveWindow()
        super.onCreate(savedInstanceState)
        enforceLandscapeAndImmersiveWindow()
    }

    override fun onResume() {
        super.onResume()
        enforceLandscapeAndImmersiveWindow()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        enforceLandscapeAndImmersiveWindow()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            enforceLandscapeAndImmersiveWindow()
        }
    }

    @Suppress("DEPRECATION")
    private fun enforceLandscapeAndImmersiveWindow() {
        try {
            if (requestedOrientation != ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE) {
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
            }

            val currentWindow = window ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val params = currentWindow.attributes
                if (params.layoutInDisplayCutoutMode !=
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                ) {
                    params.layoutInDisplayCutoutMode =
                        WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                    currentWindow.attributes = params
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                currentWindow.setDecorFitsSystemWindows(false)
                currentWindow.insetsController?.let { controller ->
                    controller.hide(
                        WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars()
                    )
                    controller.systemBarsBehavior =
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                currentWindow.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
                currentWindow.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                )
            }
        } catch (_: Throwable) {
            // Ignore on restricted OEM window managers
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        volumeControlStream = AudioManager.STREAM_MUSIC

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playWav" -> {
                        val key = call.argument<String>("key") ?: "sfx"
                        val wavBytes = call.argument<ByteArray>("bytes")
                        val pcmBytes = if (wavBytes != null && wavBytes.size > 44) {
                            val extracted = wavBytes.copyOfRange(44, wavBytes.size)
                            pcmCache[key] = extracted
                            extracted
                        } else {
                            pcmCache[key]
                        }
                        if (pcmBytes != null && pcmBytes.isNotEmpty()) {
                            playPcmNonBlocking(pcmBytes)
                        }
                        result.success(null)
                    }
                    "vibrate" -> {
                        val patternList = call.argument<List<Int>>("pattern") ?: listOf(18)
                        val amplitude = (call.argument<Int>("amplitude") ?: 180).coerceIn(1, 255)
                        triggerVibration(patternList, amplitude)
                        result.success(null)
                    }
                    "getAllPrefs" -> {
                        try {
                            val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                            val out = HashMap<String, String>()
                            for ((k, v) in prefs.all) {
                                if (v is String) {
                                    out[k] = v
                                }
                            }
                            result.success(out)
                        } catch (_: Throwable) {
                            result.success(emptyMap<String, String>())
                        }
                    }
                    "setPref" -> {
                        val key = call.argument<String>("key")
                        val value = call.argument<String>("value")
                        if (key != null && value != null) {
                            try {
                                getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                                    .edit()
                                    .putString(key, value)
                                    .apply()
                            } catch (_: Throwable) {}
                        }
                        result.success(null)
                    }
                    "removePref" -> {
                        val key = call.argument<String>("key")
                        if (key != null) {
                            try {
                                getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                                    .edit()
                                    .remove(key)
                                    .apply()
                            } catch (_: Throwable) {}
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playPcmNonBlocking(pcmBytes: ByteArray) {
        audioScheduler.execute {
            var track: AudioTrack? = null
            try {
                val bufferSize = maxOf(
                    pcmBytes.size,
                    AudioTrack.getMinBufferSize(
                        sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO,
                        AudioFormat.ENCODING_PCM_16BIT
                    )
                )
                track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    AudioTrack.Builder()
                        .setAudioAttributes(gameAudioAttributes)
                        .setAudioFormat(monoPcmFormat)
                        .setBufferSizeInBytes(bufferSize)
                        .setTransferMode(AudioTrack.MODE_STATIC)
                        .build()
                } else {
                    @Suppress("DEPRECATION")
                    AudioTrack(
                        AudioManager.STREAM_MUSIC,
                        sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                        bufferSize,
                        AudioTrack.MODE_STATIC
                    )
                }

                track.write(pcmBytes, 0, pcmBytes.size)
                track.play()

                val durationMs = ((pcmBytes.size.toLong() * 1000L) / (sampleRate * 2L)) + 80L
                val trackToRelease = track
                audioScheduler.schedule({
                    try {
                        trackToRelease.stop()
                    } catch (_: Throwable) {}
                    try {
                        trackToRelease.release()
                    } catch (_: Throwable) {}
                }, durationMs, TimeUnit.MILLISECONDS)
            } catch (_: Throwable) {
                try {
                    track?.release()
                } catch (_: Throwable) {}
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun triggerVibration(patternList: List<Int>, amplitude: Int) {
        val vib = hardwareVibrator ?: return
        try {
            if (!vib.hasVibrator()) return
            if (patternList.size <= 1) {
                val duration = (patternList.firstOrNull() ?: 18).toLong().coerceAtLeast(10L)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vib.vibrate(VibrationEffect.createOneShot(duration, amplitude))
                } else {
                    vib.vibrate(duration)
                }
            } else {
                val timings = LongArray(patternList.size + 1)
                timings[0] = 0L
                for (i in patternList.indices) {
                    timings[i + 1] = patternList[i].toLong().coerceAtLeast(10L)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vib.vibrate(VibrationEffect.createWaveform(timings, -1))
                } else {
                    vib.vibrate(timings, -1)
                }
            }
        } catch (_: Throwable) {}
    }

    override fun onDestroy() {
        try {
            audioScheduler.shutdownNow()
        } catch (_: Throwable) {}
        super.onDestroy()
    }
}
