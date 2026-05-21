package com.example.speed_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.speed_mobile/cadence_beep"
    private var beep: CadenceBeepChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        beep = CadenceBeepChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> {
                        beep!!.prepare(call.arguments as ByteArray)
                        result.success(null)
                    }
                    "play" -> {
                        beep!!.play()
                        result.success(null)
                    }
                    "dispose" -> {
                        beep!!.release()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
