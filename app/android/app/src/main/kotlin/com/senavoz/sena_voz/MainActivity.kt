package com.senavoz.sena_voz

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var handLandmarker: HandLandmarkerChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handLandmarker = HandLandmarkerChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        handLandmarker?.dispose()
        handLandmarker = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
