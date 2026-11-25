package com.senavoz.sena_voz

import android.content.Context
import android.graphics.Bitmap
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

    // Buffers reutilizados entre frames (evita crear memoria 20+ veces por segundo).
    private var pixels = IntArray(0)
    private var bitmap: Bitmap? = null

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

        val upright = yuvToUprightBitmap(width, height, planes, rowStrides, pixelStrides, rotation, mirror)

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
     * YUV_420_888 → ARGB, ya girada a vertical y espejada, en UNA sola pasada.
     *
     * Antes se convertía y luego se giraba con otro Bitmap (dos copias por
     * frame). Ahora cada pixel se escribe directo en su posición final.
     * Se reduce para que el lado mayor quede en ~360 px: MediaPipe trabaja a
     * 192/224 px internamente, así que no se pierde precisión.
     */
    private fun yuvToUprightBitmap(
        width: Int,
        height: Int,
        planes: List<ByteArray>,
        rowStrides: List<Int>,
        pixelStrides: List<Int>,
        rotationDeg: Int,
        mirror: Boolean,
    ): Bitmap {
        val step = maxOf(1, maxOf(width, height) / 360)
        val srcW = width / step
        val srcH = height / step
        val rotation = ((rotationDeg % 360) + 360) % 360
        val swap = rotation == 90 || rotation == 270
        val dstW = if (swap) srcH else srcW
        val dstH = if (swap) srcW else srcH

        if (pixels.size != dstW * dstH) pixels = IntArray(dstW * dstH)
        val out = pixels

        val y = planes[0]
        val u = planes[1]
        val v = planes[2]
        val yRow = rowStrides[0]
        val uvRow = rowStrides[1]
        val uvPixel = pixelStrides[1]
        val uvMax = minOf(u.size, v.size) - 1

        for (sy in 0 until srcH) {
            val py = sy * step
            val yBase = py * yRow
            val uvBase = (py shr 1) * uvRow
            for (sx in 0 until srcW) {
                val px = sx * step
                val yy = y[yBase + px].toInt() and 0xFF
                val uvOff = minOf(uvBase + (px shr 1) * uvPixel, uvMax)
                val uu = (u[uvOff].toInt() and 0xFF) - 128
                val vv = (v[uvOff].toInt() and 0xFF) - 128

                var r = yy + ((1404 * vv) shr 10)
                var g = yy - ((346 * uu + 715 * vv) shr 10)
                var b = yy + ((1774 * uu) shr 10)
                r = if (r < 0) 0 else if (r > 255) 255 else r
                g = if (g < 0) 0 else if (g > 255) 255 else g
                b = if (b < 0) 0 else if (b > 255) 255 else b

                // Posición final tras girar (horario) y espejar.
                var dx: Int
                val dy: Int
                when (rotation) {
                    90 -> { dx = srcH - 1 - sy; dy = sx }
                    180 -> { dx = srcW - 1 - sx; dy = srcH - 1 - sy }
                    270 -> { dx = sy; dy = srcW - 1 - sx }
                    else -> { dx = sx; dy = sy }
                }
                if (mirror) dx = dstW - 1 - dx
                out[dy * dstW + dx] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
            }
        }

        var bmp = bitmap
        if (bmp == null || bmp.width != dstW || bmp.height != dstH) {
            bmp?.recycle()
            bmp = Bitmap.createBitmap(dstW, dstH, Bitmap.Config.ARGB_8888)
            bitmap = bmp
        }
        bmp!!.setPixels(out, 0, dstW, 0, 0, dstW, dstH)
        return bmp
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
