package com.senavoz.sena_voz

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Puente Flutter ⇄ MediaPipe HandLandmarker.
 *
 * Contrato (ver docs/ARCHITECTURE.md):
 *  - init   {maxHands, minConfidence}
 *  - detect {width, height, rotation, mirror, planes, rowStrides, pixelStrides}
 *           → {timestamp, hands:[{handedness, score, landmarks:[x,y,z × 21]}]}
 *  - close
 *
 * Las coordenadas se devuelven sobre la imagen ya rotada a vertical y, en la
 * cámara frontal, espejada (igual que el preview y que el entrenamiento).
 */
class HandLandmarkerChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "sena_voz/hand_landmarker")
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var landmarker: HandLandmarker? = null
    private var lastTimestamp = 0L

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> executor.execute { runCatchingTo(result) { init(call); null } }
            "detect" -> executor.execute { runCatchingTo(result) { detect(call) } }
            "close" -> executor.execute { runCatchingTo(result) { close(); null } }
            else -> result.notImplemented()
        }
    }

    private fun runCatchingTo(result: MethodChannel.Result, block: () -> Any?) {
        try {
            val value = block()
            mainHandler.post { result.success(value) }
        } catch (e: Exception) {
            mainHandler.post { result.error("HAND_LANDMARKER", e.message, null) }
        }
    }

    private fun init(call: MethodCall) {
        if (landmarker != null) return
        val maxHands = call.argument<Int>("maxHands") ?: 2
        val minConf = (call.argument<Double>("minConfidence") ?: 0.5).toFloat()

        fun build(delegate: Delegate): HandLandmarker {
            val base = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .setDelegate(delegate)
                .build()
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(base)
                .setRunningMode(RunningMode.VIDEO)
                .setNumHands(maxHands)
                .setMinHandDetectionConfidence(minConf)
                .setMinHandPresenceConfidence(minConf)
                .setMinTrackingConfidence(0.5f)
                .build()
            return HandLandmarker.createFromOptions(context, options)
        }

        // GPU es más rápido; si el equipo no lo soporta, se usa CPU.
        landmarker = try {
            build(Delegate.GPU)
        } catch (e: Exception) {
            build(Delegate.CPU)
        }
    }

    private fun detect(call: MethodCall): Map<String, Any> {
        val lm = landmarker ?: throw IllegalStateException("HandLandmarker no inicializado")

        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val rotation = call.argument<Int>("rotation") ?: 0
        val mirror = call.argument<Boolean>("mirror") ?: false
        val planes = call.argument<List<ByteArray>>("planes")!!
        val rowStrides = call.argument<List<Int>>("rowStrides")!!
        val pixelStrides = call.argument<List<Int>>("pixelStrides")!!

        val bitmap = yuvToBitmap(width, height, planes, rowStrides, pixelStrides)
        val upright = orient(bitmap, rotation, mirror)

        // VIDEO mode exige timestamps estrictamente crecientes.
        var ts = SystemClock.uptimeMillis()
        if (ts <= lastTimestamp) ts = lastTimestamp + 1
        lastTimestamp = ts

        val result = lm.detectForVideo(BitmapImageBuilder(upright).build(), ts)

        val hands = mutableListOf<Map<String, Any>>()
        for (i in result.landmarks().indices) {
            val points = result.landmarks()[i]
            val category = result.handedness().getOrNull(i)?.firstOrNull()
            val flat = ArrayList<Double>(points.size * 3)
            for (p in points) {
                flat.add(p.x().toDouble())
                flat.add(p.y().toDouble())
                flat.add(p.z().toDouble())
            }
            hands.add(
                mapOf(
                    "handedness" to (category?.categoryName() ?: "Right"),
                    "score" to (category?.score()?.toDouble() ?: 1.0),
                    "landmarks" to flat,
                )
            )
        }
        return mapOf("timestamp" to System.currentTimeMillis(), "hands" to hands)
    }

    /**
     * YUV_420_888 → ARGB. Se reduce a la mitad si la imagen es grande:
     * MediaPipe trabaja a 224/256 px internamente, así que no se pierde precisión.
     */
    private fun yuvToBitmap(
        width: Int,
        height: Int,
        planes: List<ByteArray>,
        rowStrides: List<Int>,
        pixelStrides: List<Int>,
    ): Bitmap {
        val step = if (width > 640) 2 else 1
        val outW = width / step
        val outH = height / step
        val pixels = IntArray(outW * outH)

        val y = planes[0]
        val u = planes[1]
        val v = planes[2]
        val yRow = rowStrides[0]
        val uvRow = rowStrides[1]
        val uvPixel = pixelStrides[1]

        var idx = 0
        for (oy in 0 until outH) {
            val py = oy * step
            val yBase = py * yRow
            val uvBase = (py shr 1) * uvRow
            for (ox in 0 until outW) {
                val px = ox * step
                val yy = (y[yBase + px].toInt() and 0xFF)
                val uvOff = uvBase + (px shr 1) * uvPixel
                val uu = (u.getOrElse(uvOff) { 128.toByte() }.toInt() and 0xFF) - 128
                val vv = (v.getOrElse(uvOff) { 128.toByte() }.toInt() and 0xFF) - 128

                var r = yy + (1.370705f * vv).toInt()
                var g = yy - (0.337633f * uu + 0.698001f * vv).toInt()
                var b = yy + (1.732446f * uu).toInt()
                r = r.coerceIn(0, 255)
                g = g.coerceIn(0, 255)
                b = b.coerceIn(0, 255)
                pixels[idx++] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
            }
        }
        return Bitmap.createBitmap(pixels, outW, outH, Bitmap.Config.ARGB_8888)
    }

    private fun orient(src: Bitmap, rotation: Int, mirror: Boolean): Bitmap {
        if (rotation == 0 && !mirror) return src
        val m = Matrix()
        m.postRotate(rotation.toFloat())
        if (mirror) m.postScale(-1f, 1f)
        return Bitmap.createBitmap(src, 0, 0, src.width, src.height, m, true)
    }

    private fun close() {
        landmarker?.close()
        landmarker = null
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.execute { close() }
        executor.shutdown()
    }
}
