package com.example.speed_mobile

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import java.io.File

class CadenceBeepChannel(private val context: Context) {
    private var soundPool: SoundPool? = null
    private var soundId: Int = -1
    private var loaded = false

    fun prepare(bytes: ByteArray) {
        release()
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val pool = SoundPool.Builder()
            .setMaxStreams(2)
            .setAudioAttributes(attrs)
            .build()
        val tmp = File.createTempFile("cadence_beep", ".wav", context.cacheDir)
        tmp.writeBytes(bytes)
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            tmp.delete()
            if (status == 0) {
                soundId = sampleId
                loaded = true
            }
        }
        soundPool = pool
        pool.load(tmp.absolutePath, 1)
    }

    fun play() {
        if (loaded && soundId > 0) {
            soundPool?.play(soundId, 1f, 1f, 1, 0, 1f)
        }
    }

    fun release() {
        soundPool?.release()
        soundPool = null
        soundId = -1
        loaded = false
    }
}
