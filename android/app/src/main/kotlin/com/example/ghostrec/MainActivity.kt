package com.example.ghostrec

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.Ghostrec/recorder"

    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var outputFile: String? = null

    private val REQUEST_RECORD_AUDIO_PERMISSION = 200
    private val permissions = arrayOf(
        Manifest.permission.RECORD_AUDIO,
        Manifest.permission.WRITE_EXTERNAL_STORAGE, 
        Manifest.permission.READ_PHONE_STATE
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (!hasPermissions()) {
            ActivityCompat.requestPermissions(this, permissions, REQUEST_RECORD_AUDIO_PERMISSION)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    if (!hasPermissions()) {
                        result.error("PERMISSION", "Required permissions not granted", null)
                        return@setMethodCallHandler
                    }
                    try {
                        startRecording()
                        result.success("Recording started")
                    } catch (e: Exception) {
                        result.error("START_FAILED", "Could not start recording: ${e.message}", null)
                    }
                }
                "stopRecording" -> {
                    try {
                        stopRecording()
                        result.success("Recording stopped.")
                    } catch (e: Exception) {
                        result.error("STOP_FAILED", "Could not stop recording: ${e.message}", null)
                    }
                }
                "playRecording" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("NO_FILE", "File path is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        playRecording(filePath)
                        result.success("Playback started")
                    } catch (e: Exception) {
                        result.error("PLAY_FAILED", "Could not play recording: ${e.message}", null)
                    }
                }
                "stopPlayback" -> {
                    try {
                        stopPlayback()
                        result.success("Playback stopped")
                    } catch (e: Exception) {
                        result.error("STOP_PLAY_FAILED", "Could not stop playback: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasPermissions(): Boolean {
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    private fun startRecording() {

        stopRecording()

        val baseDir = getExternalFilesDir(null)
        val recordingsDir = File(baseDir, "GhostRecRecordings")
        if (!recordingsDir.exists()) {
            recordingsDir.mkdirs()
        }
        outputFile = File(recordingsDir, "recording_${System.currentTimeMillis()}.3gp").absolutePath

        mediaRecorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setOutputFile(outputFile)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            try {
                prepare()
                start()
            } catch (e: IOException) {
                throw RuntimeException("prepare() failed: ${e.message}")
            }
        }
    }

    private fun stopRecording() {
        mediaRecorder?.let { recorder ->
            try {
                recorder.stop()
            } catch (e: RuntimeException) {

            }
            recorder.release()
        }
        mediaRecorder = null
    }

    private fun playRecording(filePath: String) {

        stopPlayback()
        mediaPlayer = MediaPlayer().apply {
            setDataSource(filePath)
            prepare()
            start()
        }
    }

    private fun stopPlayback() {
        mediaPlayer?.let { player ->
            if (player.isPlaying) {
                player.stop()
            }
            player.release()
        }
        mediaPlayer = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

    }
}