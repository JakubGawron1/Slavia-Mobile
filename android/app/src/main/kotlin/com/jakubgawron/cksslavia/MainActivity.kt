package com.jakubgawron.cksslavia

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterFragmentActivity() {
    private lateinit var installLauncher: ActivityResultLauncher<Intent>
    private lateinit var uninstallLauncher: ActivityResultLauncher<Intent>

    private var pendingInstallResult: MethodChannel.Result? = null
    private var pendingUninstallResult: MethodChannel.Result? = null

    private var pendingFallbackResult: MethodChannel.Result? = null
    private var pendingFallbackApkPath: String? = null
    private var pendingFallbackDownloadUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        installLauncher =
            registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { ar ->
                val pending = pendingInstallResult
                pendingInstallResult = null
                pending?.success(installOutcome(ar.resultCode))
            }
        uninstallLauncher =
            registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { ar ->
                handleUninstallActivityResult(ar.resultCode)
            }
        super.onCreate(savedInstanceState)
    }

    private fun handleUninstallActivityResult(resultCode: Int) {
        val fallbackPending = pendingFallbackResult
        val fallbackPath = pendingFallbackApkPath
        val downloadUriStr = pendingFallbackDownloadUri

        if (fallbackPending != null && fallbackPath != null) {
            pendingFallbackResult = null
            pendingFallbackApkPath = null
            pendingFallbackDownloadUri = null

            val stillInstalled = isPackageInstalled(packageName)
            var installLaunched = false
            var installError: String? = null

            if (stillInstalled) {
                val launch = launchInstallForFile(File(fallbackPath))
                installLaunched = launch.first
                installError = launch.second
            } else if (!downloadUriStr.isNullOrBlank()) {
                val launch = launchInstallForUri(Uri.parse(downloadUriStr))
                installLaunched = launch.first
                installError = launch.second
            }

            fallbackPending.success(
                mapOf(
                    "uninstall" to uninstallOutcome(resultCode),
                    "stillInstalled" to stillInstalled,
                    "installLaunched" to installLaunched,
                    "installError" to installError,
                    "downloadCopied" to !downloadUriStr.isNullOrBlank(),
                    "downloadFileName" to FALLBACK_DOWNLOAD_NAME,
                ),
            )
            return
        }

        val pending = pendingUninstallResult
        pendingUninstallResult = null
        pending?.success(
            mapOf(
                "status" to uninstallOutcome(resultCode),
                "stillInstalled" to isPackageInstalled(packageName),
            ),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestPackageInstalls" -> {
                        val allowed =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                packageManager.canRequestPackageInstalls()
                            } else {
                                true
                            }
                        result.success(allowed)
                    }

                    "openManageUnknownAppSources" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val intent =
                                    Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
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
                            val uri = fileUriForInstall(file)
                            if (pendingInstallResult != null) {
                                result.error("BUSY", "Instalacja już trwa.", null)
                                return@setMethodCallHandler
                            }
                            pendingInstallResult = result
                            installLauncher.launch(buildInstallIntent(uri))
                        } catch (_: ActivityNotFoundException) {
                            pendingInstallResult = null
                            result.error(
                                "ACTIVITY_NOT_FOUND",
                                "Instalator pakietów niedostępny.",
                                null,
                            )
                        } catch (e: Exception) {
                            pendingInstallResult = null
                            result.error("OPEN_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "uninstallSelf" -> {
                        try {
                            if (pendingUninstallResult != null) {
                                result.error("BUSY", "Odinstalowanie już trwa.", null)
                                return@setMethodCallHandler
                            }
                            pendingUninstallResult = result
                            uninstallLauncher.launch(uninstallIntent())
                        } catch (e: Exception) {
                            pendingUninstallResult = null
                            result.error("UNINSTALL_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "runUpdateFallback" -> {
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
                        if (pendingFallbackResult != null) {
                            result.error("BUSY", "Procedura aktualizacji już trwa.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val downloadUri = copyApkToDownloads(file)
                            pendingFallbackApkPath = path
                            pendingFallbackDownloadUri = downloadUri?.toString()
                            pendingFallbackResult = result
                            uninstallLauncher.launch(uninstallIntent())
                        } catch (e: Exception) {
                            pendingFallbackApkPath = null
                            pendingFallbackDownloadUri = null
                            pendingFallbackResult = null
                            result.error("FALLBACK_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun uninstallIntent(): Intent =
        Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName"))

    private fun fileUriForInstall(file: File): Uri =
        FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.slavia.fileprovider",
            file,
        )

    private fun buildInstallIntent(uri: Uri): Intent {
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
                    setDataAndType(uri, APK_MIME)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
        grantUriToResolvers(intent, uri)
        return intent
    }

    private fun grantUriToResolvers(intent: Intent, uri: Uri) {
        val resolves =
            packageManager.queryIntentActivities(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY,
            )
        if (resolves.isEmpty()) {
            throw ActivityNotFoundException("Brak aplikacji instalującej APK.")
        }
        for (info in resolves) {
            grantUriPermission(
                info.activityInfo.packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        }
    }

    private fun launchInstallForFile(file: File): Pair<Boolean, String?> =
        try {
            val uri = fileUriForInstall(file)
            startActivity(buildInstallIntent(uri))
            true to null
        } catch (e: Exception) {
            false to (e.message ?: e.toString())
        }

    private fun launchInstallForUri(uri: Uri): Pair<Boolean, String?> =
        try {
            startActivity(buildInstallIntent(uri))
            true to null
        } catch (e: Exception) {
            false to (e.message ?: e.toString())
        }

    private fun installOutcome(code: Int): Map<String, Any?> =
        when (code) {
            Activity.RESULT_OK -> mapOf("status" to "success", "code" to code)
            Activity.RESULT_CANCELED -> mapOf("status" to "cancelled", "code" to code)
            else -> mapOf("status" to "failed", "code" to code)
        }

    private fun uninstallOutcome(code: Int): String =
        when (code) {
            Activity.RESULT_OK -> "confirmed"
            Activity.RESULT_CANCELED -> "cancelled"
            else -> "unknown"
        }

    private fun isPackageInstalled(pkg: String): Boolean =
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    pkg,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(pkg, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

    private fun copyApkToDownloads(source: File): Uri? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values =
                    ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, FALLBACK_DOWNLOAD_NAME)
                        put(MediaStore.Downloads.MIME_TYPE, APK_MIME)
                        put(
                            MediaStore.MediaColumns.RELATIVE_PATH,
                            "${Environment.DIRECTORY_DOWNLOADS}/",
                        )
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                val resolver = contentResolver
                val uri =
                    resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                        ?: return null
                resolver.openOutputStream(uri)?.use { out ->
                    FileInputStream(source).use { input -> input.copyTo(out) }
                }
                val published =
                    ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
                resolver.update(uri, published, null, null)
                uri
            } else {
                @Suppress("DEPRECATION")
                val dir =
                    Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DOWNLOADS,
                    )
                if (!dir.exists() && !dir.mkdirs()) return null
                val dest = File(dir, FALLBACK_DOWNLOAD_NAME)
                FileInputStream(source).use { input ->
                    dest.outputStream().use { output -> input.copyTo(output) }
                }
                fileUriForInstall(dest)
            }
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        private const val CHANNEL = "slavia_mobile/install_apk"
        private const val APK_MIME = "application/vnd.android.package-archive"
        private const val FALLBACK_DOWNLOAD_NAME = "slavia_update.apk"
    }
}
