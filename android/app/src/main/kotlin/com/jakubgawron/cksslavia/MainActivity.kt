package com.jakubgawron.cksslavia

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "slavia_mobile/install_apk")
            .setMethodCallHandler { call, result ->
                if (call.method != "install") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("BAD_ARGUMENT", "path required", null)
                    return@setMethodCallHandler
                }
                val file = File(path)
                if (!file.exists()) {
                    result.error("NOT_FOUND", "file missing", null)
                    return@setMethodCallHandler
                }
                try {
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.slavia.fileprovider",
                        file,
                    )
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("OPEN_FAILED", e.message ?: e.toString(), null)
                }
            }
    }
}
