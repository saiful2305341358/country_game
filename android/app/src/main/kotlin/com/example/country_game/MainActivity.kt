package com.example.country_game

import android.content.Context
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.SoundPool
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
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        @Volatile
        private var sessionIntroPlayed: Boolean = false
        private const val SESSION_INTRO_KEY = "__session_intro_played__"
    }

    private val channelName = "com.example.country_game/native_feedback"
    private val prefsName = "country_game_prefs"
    private val sampleRate = 22050
    private val pcmCache = ConcurrentHashMap<String, ByteArray>()
    private val soundIdMap = ConcurrentHashMap<String, Int>()
    private val loadedSoundIds = ConcurrentHashMap.newKeySet<Int>()
    private val activeStreams = CopyOnWriteArrayList<Int>()
    private val activeTracks = CopyOnWriteArrayList<AudioTrack>()
    private val audioScheduler = Executors.newScheduledThreadPool(3)

    private val gameAudioAttributes: AudioAttributes by lazy {
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
    }

    private val monoPcmFormat: AudioFormat by lazy {
        AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
    }

    private val soundPool: SoundPool? by lazy {
        try {
            SoundPool.Builder()
                .setMaxStreams(8)
                .setAudioAttributes(gameAudioAttributes)
                .build()
                .apply {
                    setOnLoadCompleteListener { _, sampleId, status ->
                        if (status == 0) {
                            loadedSoundIds.add(sampleId)
                        }
                    }
                }
        } catch (_: Throwable) {
            null
        }
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
        enforceLandscapeAndImmersiveWindow()
        super.onCreate(savedInstanceState)
        volumeControlStream = AudioManager.STREAM_MUSIC
        enforceLandscapeAndImmersiveWindow()
    }

    override fun onResume() {
        super.onResume()
        volumeControlStream = AudioManager.STREAM_MUSIC
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
                    "preloadAll" -> {
                        val sounds = call.argument<Map<String, ByteArray>>("sounds")
                        if (sounds != null) {
                            audioScheduler.execute {
                                for ((key, wavBytes) in sounds) {
                                    cacheWavAndLoadSoundPool(key, wavBytes)
                                }
                            }
                        }
                        result.success(null)
                    }
                    "playWav" -> {
                        val key = call.argument<String>("key") ?: "sfx"
                        val wavBytes = call.argument<ByteArray>("bytes")
                        if (wavBytes != null && wavBytes.size > 44) {
                            cacheWavAndLoadSoundPool(key, wavBytes)
                        }
                        playCachedSound(key)
                        result.success(null)
                    }
                    "stopAll" -> {
                        stopAllActiveAudio()
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
                            out[SESSION_INTRO_KEY] = if (sessionIntroPlayed) "1" else "0"
                            result.success(out)
                        } catch (_: Throwable) {
                            result.success(mapOf(SESSION_INTRO_KEY to if (sessionIntroPlayed) "1" else "0"))
                        }
                    }
                    "setPref" -> {
                        val key = call.argument<String>("key")
                        val value = call.argument<String>("value")
                        if (key != null && value != null) {
                            if (key == SESSION_INTRO_KEY) {
                                sessionIntroPlayed = (value == "1")
                            } else {
                                try {
                                    getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                                        .edit()
                                        .putString(key, value)
                                        .apply()
                                } catch (_: Throwable) {}
                            }
                        }
                        result.success(null)
                    }
                    "removePref" -> {
                        val key = call.argument<String>("key")
                        if (key != null) {
                            if (key == SESSION_INTRO_KEY) {
                                sessionIntroPlayed = false
                            } else {
                                try {
                                    getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                                        .edit()
                                        .remove(key)
                                        .apply()
                                } catch (_: Throwable) {}
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun cacheWavAndLoadSoundPool(key: String, wavBytes: ByteArray) {
        if (wavBytes.size <= 44) return
        val extracted = wavBytes.copyOfRange(44, wavBytes.size)
        pcmCache[key] = extracted

        val pool = soundPool ?: return
        if (soundIdMap.containsKey(key)) return

        try {
            val outFile = File(cacheDir, "ccg_sfx_${key}_v2.wav")
            if (!outFile.exists() || outFile.length() != wavBytes.size.toLong()) {
                FileOutputStream(outFile).use { fos ->
                    fos.write(wavBytes)
                    fos.flush()
                }
            }
            val id = pool.load(outFile.absolutePath, 1)
            if (id > 0) {
                soundIdMap[key] = id
            }
        } catch (_: Throwable) {
            // Fallback to AudioTrack via pcmCache
        }
    }

    private fun playCachedSound(key: String) {
        val pool = soundPool
        val soundId = soundIdMap[key]
        if (pool != null && soundId != null && loadedSoundIds.contains(soundId)) {
            val streamId = pool.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
            if (streamId != 0) {
                activeStreams.add(streamId)
                if (activeStreams.size > 16) {
                    activeStreams.removeAt(0)
                }
                return
            }
        }

        val pcmBytes = pcmCache[key]
        if (pcmBytes != null && pcmBytes.isNotEmpty()) {
            playPcmNonBlocking(pcmBytes)
        }
    }

    private fun playPcmNonBlocking(pcmBytes: ByteArray) {
        audioScheduler.execute {
            var track: AudioTrack? = null
            try {
                val minBuf = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                ).coerceAtLeast(2048)

                // Ensure buffer size is even (16-bit PCM frame aligned) and at least minBuf.
                // Critically, in MODE_STATIC we MUST pad the byte array to match bufferSize
                // so track.write() fills 100% of the static buffer and transitions AudioTrack
                // out of STATE_NO_STATIC_DATA into STATE_INITIALIZED before play() is called.
                var targetBufferSize = maxOf(pcmBytes.size, minBuf)
                if (targetBufferSize % 2 != 0) {
                    targetBufferSize += 1
                }

                val fullPcmBuffer = if (pcmBytes.size == targetBufferSize) {
                    pcmBytes
                } else {
                    ByteArray(targetBufferSize).also { padded ->
                        System.arraycopy(pcmBytes, 0, padded, 0, pcmBytes.size)
                    }
                }

                track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    AudioTrack.Builder()
                        .setAudioAttributes(gameAudioAttributes)
                        .setAudioFormat(monoPcmFormat)
                        .setBufferSizeInBytes(fullPcmBuffer.size)
                        .setTransferMode(AudioTrack.MODE_STATIC)
                        .build()
                } else {
                    @Suppress("DEPRECATION")
                    AudioTrack(
                        AudioManager.STREAM_MUSIC,
                        sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                        fullPcmBuffer.size,
                        AudioTrack.MODE_STATIC
                    )
                }

                track.write(fullPcmBuffer, 0, fullPcmBuffer.size)
                if (track.state == AudioTrack.STATE_INITIALIZED) {
                    activeTracks.add(track)
                    track.play()
                }

                val durationMs = ((fullPcmBuffer.size.toLong() * 1000L) / (sampleRate * 2L)) + 120L
                val trackToRelease = track
                audioScheduler.schedule({
                    activeTracks.remove(trackToRelease)
                    try {
                        trackToRelease.stop()
                    } catch (_: Throwable) {}
                    try {
                        trackToRelease.release()
                    } catch (_: Throwable) {}
                }, durationMs, TimeUnit.MILLISECONDS)
            } catch (_: Throwable) {
                try {
                    track?.let { activeTracks.remove(it) }
                    track?.release()
                } catch (_: Throwable) {}
            }
        }
    }

    private fun stopAllActiveAudio() {
        try {
            val pool = soundPool
            if (pool != null) {
                for (streamId in activeStreams) {
                    try {
                        pool.stop(streamId)
                    } catch (_: Throwable) {}
                }
                activeStreams.clear()
            }
            for (track in activeTracks) {
                try {
                    track.pause()
                    track.flush()
                    track.stop()
                } catch (_: Throwable) {}
            }
        } catch (_: Throwable) {}
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
        stopAllActiveAudio()
        try {
            soundPool?.release()
        } catch (_: Throwable) {}
        try {
            audioScheduler.shutdownNow()
        } catch (_: Throwable) {}
        super.onDestroy()
    }
}
