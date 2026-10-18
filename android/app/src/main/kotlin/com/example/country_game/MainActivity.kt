package com.example.country_game

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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
        if (audioScheduler.isShutdown) return
        audioScheduler.execute {
            var track: AudioTrack? = null
            try {
                track = AudioTrack(
                    gameAudioAttributes,
                    monoPcmFormat,
                    pcmBytes.size,
                    AudioTrack.MODE_STATIC,
                    AudioManager.AUDIO_SESSION_ID_GENERATE
                )
                track.write(pcmBytes, 0, pcmBytes.size)
                track.play()

                val durationMs = (pcmBytes.size * 1000L) / (sampleRate * 2) + 60L
                val createdTrack = track
                audioScheduler.schedule({
                    try {
                        createdTrack.stop()
                    } catch (_: Throwable) {}
                    try {
                        createdTrack.release()
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
        try {
            val vibrator = hardwareVibrator
            if (vibrator == null || !vibrator.hasVibrator()) return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (patternList.size <= 1) {
                    val ms = (patternList.firstOrNull() ?: 18).toLong().coerceAtLeast(8L)
                    vibrator.vibrate(VibrationEffect.createOneShot(ms, amplitude))
                } else {
                    val timings = LongArray(patternList.size + 1)
                    val amplitudes = IntArray(patternList.size + 1)
                    timings[0] = 0L
                    amplitudes[0] = 0
                    for (i in patternList.indices) {
                        timings[i + 1] = patternList[i].toLong().coerceAtLeast(8L)
                        amplitudes[i + 1] = if (i % 2 == 0) amplitude else 0
                    }
                    vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
                }
            } else {
                val ms = (patternList.firstOrNull() ?: 20).toLong()
                vibrator.vibrate(ms)
            }
        } catch (_: Throwable) {
        }
    }

    override fun onDestroy() {
        try {
            audioScheduler.shutdownNow()
        } catch (_: Throwable) {}
        super.onDestroy()
    }
}
