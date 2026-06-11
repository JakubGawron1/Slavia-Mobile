package com.jakubgawron.cksslavia

import android.app.Activity
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
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
        val downloadUriStr = pendingFallbackDownloadUri

        if (fallbackPending != null) {
            pendingFallbackResult = null
            pendingFallbackDownloadUri = null

            val stillInstalled = isPackageInstalled(packageName)
            var installLaunched = false
            var installError: String? = null

            if (!downloadUriStr.isNullOrBlank()) {
                val uri = Uri.parse(downloadUriStr)
                Handler(Looper.getMainLooper()).postDelayed({
                    val launch = launchInstallForUri(uri)
                    android.util.Log.i(
                        TAG,
                        "Post-uninstall install: launched=${launch.first} err=${launch.second}",
                    )
                }, 700)
                installLaunched = true
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
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                !packageManager.canRequestPackageInstalls()
                            ) {
                                result.error(
                                    "INSTALL_BLOCKED",
                                    "Włącz instalację z nieznanych źródeł dla CKS Slavia w ustawieniach Androida.",
                                    null,
                                )
                                return@setMethodCallHandler
                            }
                            val stable = copyToUpdatesDir(file)
                            val uri = fileUriForInstall(stable)
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

                    "installViaDownloads" -> {
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
                            val downloadUri = copyApkToDownloads(file)
                            if (downloadUri == null) {
                                result.error("COPY_FAILED", "Nie udało się skopiować APK do Pobranych.", null)
                                return@setMethodCallHandler
                            }
                            val launched = launchInstallForUri(downloadUri)
                            result.success(
                                mapOf(
                                    "installLaunched" to launched.first,
                                    "installError" to launched.second,
                                    "downloadCopied" to true,
                                    "downloadFileName" to FALLBACK_DOWNLOAD_NAME,
                                    "downloadUri" to downloadUri.toString(),
                                ),
                            )
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message ?: e.toString(), null)
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
                        try {
                            val downloadUri = copyApkToDownloads(file)
                            if (downloadUri == null) {
                                result.error("COPY_FAILED", "Nie udało się skopiować APK do Pobranych.", null)
                                return@setMethodCallHandler
                            }
                            val launch = launchInstallForUri(downloadUri)
                            result.success(
                                mapOf(
                                    "uninstall" to "skipped",
                                    "stillInstalled" to isPackageInstalled(packageName),
                                    "installLaunched" to launch.first,
                                    "installError" to launch.second,
                                    "downloadCopied" to true,
                                    "downloadFileName" to FALLBACK_DOWNLOAD_NAME,
                                    "downloadUri" to downloadUri.toString(),
                                ),
                            )
                        } catch (e: Exception) {
                            result.error("FALLBACK_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "listUpdateArtifacts" -> {
                        try {
                            result.success(collectUpdateArtifacts())
                        } catch (e: Exception) {
                            result.error("LIST_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "clearUpdateArtifacts" -> {
                        try {
                            result.success(clearUpdateArtifacts())
                        } catch (e: Exception) {
                            result.error("CLEAR_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    "runUpdateFallbackUninstall" -> {
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
                            pendingFallbackDownloadUri = downloadUri?.toString()
                            pendingFallbackResult = result
                            uninstallLauncher.launch(uninstallIntent())
                        } catch (e: Exception) {
                            pendingFallbackDownloadUri = null
                            pendingFallbackResult = null
                            result.error("FALLBACK_FAILED", e.message ?: e.toString(), null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun copyToUpdatesDir(source: File): File {
        val dir = File(getExternalFilesDir(null), "updates")
        if (!dir.exists()) dir.mkdirs()
        val dest = File(dir, "pending_update.apk")
        FileInputStream(source).use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        }
        return dest
    }

    private fun tryPackageInstallerInstall(file: File): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        return try {
            val packageInstaller = packageManager.packageInstaller
            val params =
                PackageInstaller.SessionParams(
                    PackageInstaller.SessionParams.MODE_FULL_INSTALL,
                ).apply {
                    setSize(file.length())
                }
            val sessionId = packageInstaller.createSession(params)
            val session = packageInstaller.openSession(sessionId)
            FileInputStream(file).use { input ->
                session.openWrite("slavia_update", 0, file.length()).use { out ->
                    input.copyTo(out)
                    session.fsync(out)
                }
            }
            val flags =
                PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_MUTABLE
                    } else {
                        0
                    }
            val intent = Intent(InstallResultReceiver.ACTION).setPackage(packageName)
            val pending =
                PendingIntent.getBroadcast(
                    applicationContext,
                    sessionId,
                    intent,
                    flags,
                )
            session.commit(pending.intentSender)
            session.close()
            true
        } catch (e: Exception) {
            android.util.Log.w(TAG, "PackageInstaller failed: ${e.message}")
            false
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
            launchInstallForUri(uri)
        } catch (e: Exception) {
            false to (e.message ?: e.toString())
        }

    private fun launchInstallForUri(uri: Uri): Pair<Boolean, String?> =
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls() ->
                    false to
                        "Włącz instalację z nieznanych źródeł dla CKS Slavia w ustawieniach Androida."
                isFinishing || isDestroyed ->
                    false to "Aktywność niedostępna — otwórz plik slavia_update.apk z Pobranych."
                else -> {
                    startActivity(buildInstallIntent(uri))
                    true to null
                }
            }
        } catch (e: ActivityNotFoundException) {
            val session =
                tryPackageInstallerFromContentUri(uri) ||
                    tryPackageInstallerFromUpdatesFile()
            if (session) {
                true to null
            } else {
                false to "Brak aplikacji instalującej APK."
            }
        } catch (e: Exception) {
            false to (e.message ?: e.toString())
        }

    /** PackageInstaller tylko jako ostateczność (bez gwarantowanego UI na wszystkich urządzeniach). */
    private fun tryPackageInstallerFromUpdatesFile(): Boolean {
        val dir = File(getExternalFilesDir(null), "updates")
        val pending = File(dir, "pending_update.apk")
        return if (pending.isFile) tryPackageInstallerInstall(pending) else false
    }

    private fun tryPackageInstallerFromContentUri(uri: Uri): Boolean {
        return try {
            val dest = copyToUpdatesDirFromUri(uri) ?: return false
            tryPackageInstallerInstall(dest)
        } catch (_: Exception) {
            false
        }
    }

    private fun copyToUpdatesDirFromUri(uri: Uri): File? {
        val dir = File(getExternalFilesDir(null), "updates")
        if (!dir.exists()) dir.mkdirs()
        val dest = File(dir, "pending_update.apk")
        contentResolver.openInputStream(uri)?.use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        return dest
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

    private fun collectUpdateArtifacts(): Map<String, Any?> {
        val items = mutableListOf<Map<String, Any?>>()
        var totalBytes = 0L

        val updatesDir = File(getExternalFilesDir(null), "updates")
        if (updatesDir.exists()) {
            updatesDir.listFiles()?.forEach { file ->
                if (file.isFile && file.name.endsWith(".apk", ignoreCase = true)) {
                    val len = file.length()
                    items.add(
                        mapOf(
                            "label" to "Aplikacja: ${file.name}",
                            "bytes" to len,
                        ),
                    )
                    totalBytes += len
                }
            }
        }

        val downloadBytes = downloadApkSizeBytes()
        if (downloadBytes > 0) {
            items.add(
                mapOf(
                    "label" to "Pobrane: $FALLBACK_DOWNLOAD_NAME",
                    "bytes" to downloadBytes,
                ),
            )
            totalBytes += downloadBytes
        }

        return mapOf(
            "items" to items,
            "totalBytes" to totalBytes,
            "fileCount" to items.size,
        )
    }

    private fun clearUpdateArtifacts(): Map<String, Any?> {
        var deletedCount = 0
        var bytesFreed = 0L

        val updatesDir = File(getExternalFilesDir(null), "updates")
        if (updatesDir.exists()) {
            updatesDir.listFiles()?.forEach { file ->
                if (file.isFile && file.name.endsWith(".apk", ignoreCase = true)) {
                    val len = file.length()
                    if (file.delete()) {
                        deletedCount++
                        bytesFreed += len
                    }
                }
            }
        }

        val downloadSize = downloadApkSizeBytes()
        val removedDownloads = deleteDownloadApk()
        if (removedDownloads > 0) {
            deletedCount += removedDownloads
            bytesFreed += downloadSize
        }

        return mapOf(
            "deletedCount" to deletedCount,
            "bytesFreed" to bytesFreed,
        )
    }

    private fun downloadApkSizeBytes(): Long {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(MediaStore.Downloads.SIZE)
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
            contentResolver
                .query(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    arrayOf(FALLBACK_DOWNLOAD_NAME),
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val idx = cursor.getColumnIndex(MediaStore.Downloads.SIZE)
                        if (idx >= 0) return cursor.getLong(idx)
                    }
                }
            return 0
        }
        @Suppress("DEPRECATION")
        val file =
            File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                FALLBACK_DOWNLOAD_NAME,
            )
        return if (file.isFile) file.length() else 0
    }

    private fun deleteDownloadApk(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
            return contentResolver.delete(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                selection,
                arrayOf(FALLBACK_DOWNLOAD_NAME),
            )
        }
        @Suppress("DEPRECATION")
        val file =
            File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                FALLBACK_DOWNLOAD_NAME,
            )
        return if (file.exists() && file.delete()) 1 else 0
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
        private const val TAG = "SlaviaInstall"
        private const val APK_MIME = "application/vnd.android.package-archive"
        private const val FALLBACK_DOWNLOAD_NAME = "slavia_update.apk"
    }
}
