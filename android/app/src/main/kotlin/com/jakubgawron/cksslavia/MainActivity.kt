package com.jakubgawron.cksslavia

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
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
                when (call.method) {
                    "canRequestPackageInstalls" -> {
                        val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            packageManager.canRequestPackageInstalls()
                        } else {
                            true
                        }
                        result.success(allowed)
                    }

                    "openManageUnknownAppSources" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "install" -> {
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
                            val intent =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                                        data = uri
                                        putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                                        putExtra(Intent.EXTRA_RETURN_RESULT, true)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        clipData = ClipData.newRawUri("Slavia APK", uri)
                                    }
                                } else {
                                    Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(uri, "application/vnd.android.package-archive")
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                }
                            val resolves = packageManager.queryIntentActivities(
                                intent,
                                PackageManager.MATCH_DEFAULT_ONLY,
                            )
                            if (resolves.isEmpty()) {
                                result.error(
                                    "NO_HANDLER",
                                    "Na tym urządzeniu nie znaleziono aplikacji instalującej APK.",
                                    null,
                                )
                                return@setMethodCallHandler
                            }
                            for (info in resolves) {
                                val pkg = info.activityInfo.packageName
                                grantUriPermission(
                                    pkg,
                                    uri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            result.error("ACTIVITY_NOT_FOUND", "Instalator pakietów niedostępny.", null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
