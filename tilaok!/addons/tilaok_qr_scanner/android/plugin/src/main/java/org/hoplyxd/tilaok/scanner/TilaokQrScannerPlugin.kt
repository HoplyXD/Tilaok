package org.hoplyxd.tilaok.scanner

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.LifecycleOwner
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class TilaokQrScannerPlugin(godot: Godot) : GodotPlugin(godot) {
    companion object {
        private const val CAMERA_PERMISSION_REQUEST = 47031
    }

    private var scanRequested = false
    private var overlay: FrameLayout? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var qrDecoder: QrFrameDecoder? = null
    private var analyzerExecutor: ExecutorService? = null
    private var backCallback: OnBackPressedCallback? = null
    private val resultDelivered = AtomicBoolean(false)

    override fun getPluginName(): String = "TilaokQrScanner"

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("qr_scanned", String::class.java),
        SignalInfo("scan_cancelled"),
        SignalInfo("scan_failed", String::class.java),
    )

    @UsedByGodot
    fun startScan() {
        runOnHostThread {
            if (overlay != null || scanRequested) return@runOnHostThread
            val hostActivity = activity ?: return@runOnHostThread
            scanRequested = true
            resultDelivered.set(false)
            if (ContextCompat.checkSelfPermission(hostActivity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                beginCamera()
            } else {
                hostActivity.requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
            }
        }
    }

    @UsedByGodot
    fun cancelScan() {
        runOnHostThread { finishScan(cancelled = true) }
    }

    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?,
    ) {
        super.onMainRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CAMERA_PERMISSION_REQUEST) return
        runOnHostThread {
            if (!scanRequested) return@runOnHostThread
            if (grantResults?.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                beginCamera()
            } else {
                val hostActivity = activity ?: return@runOnHostThread
                val permanentlyDenied = !hostActivity.shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)
                scanRequested = false
                emitSignal("scan_failed", if (permanentlyDenied) "camera_permission_permanently_denied" else "camera_permission_denied")
            }
        }
    }

    override fun onMainPause() {
        super.onMainPause()
        if (scanRequested || overlay != null) runOnHostThread { finishScan(cancelled = true) }
    }

    override fun onMainDestroy() {
        runOnHostThread { finishScan(cancelled = false) }
        qrDecoder = null
        super.onMainDestroy()
    }

    private fun beginCamera() {
        if (!scanRequested || overlay != null) return
        val hostActivity = activity
        if (hostActivity == null) {
            fail("camera_unavailable")
            return
        }
        val fragmentActivity = hostActivity as? FragmentActivity
        if (fragmentActivity == null) {
            fail("camera_ui_unavailable")
            return
        }
        val root = hostActivity.findViewById<ViewGroup>(android.R.id.content)
        if (root == null) {
            fail("camera_ui_unavailable")
            return
        }
        try {
            val frame = FrameLayout(hostActivity)
            frame.setBackgroundColor(Color.BLACK)
            val preview = PreviewView(hostActivity)
            preview.scaleType = PreviewView.ScaleType.FILL_CENTER
            frame.addView(preview, FrameLayout.LayoutParams(-1, -1))

            val close = TextView(hostActivity).apply {
                text = "Cancel scan"
                textSize = 20f
                setTextColor(Color.WHITE)
                setBackgroundColor(0xCC10282B.toInt())
                setPadding(28, 20, 28, 20)
                setOnClickListener { finishScan(cancelled = true) }
            }
            val closeParams = FrameLayout.LayoutParams(-2, -2, Gravity.TOP or Gravity.START)
            closeParams.setMargins(24, 24, 24, 24)
            frame.addView(close, closeParams)

            val hint = TextView(hostActivity).apply {
                text = "Point at the host's Tilaok! QR code"
                textSize = 20f
                setTextColor(Color.WHITE)
                setBackgroundColor(0xCC10282B.toInt())
                setPadding(24, 18, 24, 18)
                gravity = Gravity.CENTER
            }
            val hintParams = FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM)
            hintParams.setMargins(24, 24, 24, 36)
            frame.addView(hint, hintParams)
            root.addView(frame, ViewGroup.LayoutParams(-1, -1))
            overlay = frame
            backCallback = object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() { finishScan(cancelled = true) }
            }.also { fragmentActivity.onBackPressedDispatcher.addCallback(fragmentActivity, it) }

            qrDecoder = QrFrameDecoder()
            analyzerExecutor = Executors.newSingleThreadExecutor()
            val providerFuture = ProcessCameraProvider.getInstance(hostActivity)
            providerFuture.addListener({
                if (!scanRequested || overlay == null) return@addListener
                try {
                    val provider = providerFuture.get()
                    cameraProvider = provider
                    val cameraPreview = Preview.Builder().build().also { it.surfaceProvider = preview.surfaceProvider }
                    val analysis = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()
                    analysis.setAnalyzer(analyzerExecutor!!) { proxy ->
                        if (resultDelivered.get()) {
                            proxy.close()
                        } else {
                            try {
                                val plane = proxy.planes.first()
                                val buffer = plane.buffer.duplicate()
                                val width = proxy.width
                                val height = proxy.height
                                val rowStride = plane.rowStride
                                val pixelStride = plane.pixelStride
                                val base = buffer.position()
                                val luminance = ByteArray(width * height)
                                for (row in 0 until height) {
                                    val rowOffset = base + row * rowStride
                                    val outputOffset = row * width
                                    for (column in 0 until width) {
                                        luminance[outputOffset + column] =
                                            buffer.get(rowOffset + column * pixelStride)
                                    }
                                }
                                val value = qrDecoder?.decode(luminance, width, height)
                                if (!value.isNullOrEmpty() && resultDelivered.compareAndSet(false, true)) {
                                    runOnHostThread {
                                        if (scanRequested) {
                                            finishScan(cancelled = false)
                                            emitSignal("qr_scanned", value)
                                        }
                                    }
                                }
                            } catch (_: Exception) {
                                // A malformed camera frame must not stop scanning later frames.
                            } finally {
                                proxy.close()
                            }
                        }
                    }
                    provider.unbindAll()
                    provider.bindToLifecycle(fragmentActivity as LifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, cameraPreview, analysis)
                } catch (_: Exception) {
                    fail("camera_unavailable")
                }
            }, ContextCompat.getMainExecutor(hostActivity))
        } catch (_: Exception) {
            fail("camera_unavailable")
        }
    }

    private fun fail(reason: String) {
        finishScan(cancelled = false)
        emitSignal("scan_failed", reason)
    }

    private fun finishScan(cancelled: Boolean) {
        val hadScan = scanRequested || overlay != null
        scanRequested = false
        cameraProvider?.unbindAll()
        cameraProvider = null
        analyzerExecutor?.shutdownNow()
        analyzerExecutor = null
        overlay?.let { view -> (view.parent as? ViewGroup)?.removeView(view) }
        overlay = null
        backCallback?.remove()
        backCallback = null
        if (cancelled && hadScan && resultDelivered.compareAndSet(false, true)) emitSignal("scan_cancelled")
    }
}
