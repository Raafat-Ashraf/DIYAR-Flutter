package com.diyar.app

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val googleChannelName = "diyar/google_auth"
    private val documentPickerChannelName = "diyar/document_picker"
    private val pickDocumentRequestCode = 8421
    private val pickMultipleDocumentsRequestCode = 8422

    private var googleChannel: MethodChannel? = null
    private var documentPickerChannel: MethodChannel? = null
    private var pendingGoogleCallback: String? = null
    private var pendingDocumentResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureNotificationChannel()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val prefs = getSharedPreferences("diyar_prefs", MODE_PRIVATE)
        val channelId = "diyar_notifications"
        val currentVersion = 3

        val manager = getSystemService(NotificationManager::class.java)

        if (prefs.getInt("notification_channel_version", 0) < currentVersion) {
            manager.deleteNotificationChannel(channelId)
            prefs.edit().putInt("notification_channel_version", currentVersion).apply()
        }

        if (manager.getNotificationChannel(channelId) != null) return

        val channel = NotificationChannel(channelId, "إشعارات دیار", NotificationManager.IMPORTANCE_HIGH)
        val soundUri = Uri.parse("android.resource://$packageName/raw/notification")
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()
        channel.setSound(soundUri, audioAttributes)
        channel.enableVibration(true)
        manager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        googleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            googleChannelName
        )
        documentPickerChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            documentPickerChannelName
        )

        pendingGoogleCallback = googleCallbackFromIntent(intent)

        googleChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startGoogleLogin" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    try {
                        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        browserIntent.addCategory(Intent.CATEGORY_BROWSABLE)
                        startActivity(browserIntent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "consumeInitialGoogleCallback" -> {
                    val callback = pendingGoogleCallback
                    pendingGoogleCallback = null
                    result.success(callback)
                }
                else -> result.notImplemented()
            }
        }

        documentPickerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDocument" -> pickDocument(result)
                "pickMultipleDocuments" -> pickMultipleDocuments(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        val callback = googleCallbackFromIntent(intent)
        setIntent(intent)

        if (callback != null) {
            // Strip the data URI before forwarding to Flutter to prevent
            // Flutter's navigation system from routing diyar://auth/google-callback
            // as a page navigation (which would cause GoRouter to show a fallback/loading screen)
            super.onNewIntent(Intent(intent).also { it.data = null })

            pendingGoogleCallback = callback
            val ch = googleChannel
            if (ch != null) {
                ch.invokeMethod("onGoogleCallback", callback)
                pendingGoogleCallback = null
            }
        } else {
            super.onNewIntent(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickDocumentRequestCode && requestCode != pickMultipleDocumentsRequestCode) return
        val result = pendingDocumentResult ?: return
        pendingDocumentResult = null

        if (requestCode == pickMultipleDocumentsRequestCode) {
            if (resultCode != Activity.RESULT_OK) {
                result.success(emptyList<Map<String, Any>>())
                return
            }

            try {
                val uris = mutableListOf<Uri>()
                val clipData = data?.clipData
                if (clipData != null) {
                    for (i in 0 until clipData.itemCount) {
                        clipData.getItemAt(i)?.uri?.let { uris.add(it) }
                    }
                } else {
                    data?.data?.let { uris.add(it) }
                }
                result.success(uris.map { copyPickedDocument(it) })
            } catch (error: Exception) {
                result.error("PICK_FAILED", error.message, null)
            }
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            result.success(copyPickedDocument(uri))
        } catch (error: Exception) {
            result.error("PICK_FAILED", error.message, null)
        }
    }

    private fun pickDocument(result: MethodChannel.Result) {
        if (pendingDocumentResult != null) {
            result.error("PICK_IN_PROGRESS", "Document picker is already open.", null)
            return
        }

        pendingDocumentResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("image/*", "application/pdf")
            )
        }

        try {
            startActivityForResult(intent, pickDocumentRequestCode)
        } catch (error: Exception) {
            pendingDocumentResult = null
            result.error("PICK_FAILED", error.message, null)
        }
    }

    private fun pickMultipleDocuments(result: MethodChannel.Result) {
        if (pendingDocumentResult != null) {
            result.error("PICK_IN_PROGRESS", "Document picker is already open.", null)
            return
        }

        pendingDocumentResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("image/*", "application/pdf")
            )
        }

        try {
            startActivityForResult(intent, pickMultipleDocumentsRequestCode)
        } catch (error: Exception) {
            pendingDocumentResult = null
            result.error("PICK_FAILED", error.message, null)
        }
    }

    private fun copyPickedDocument(uri: Uri): Map<String, Any> {
        val displayName = queryDisplayName(uri).ifBlank { "document" }
        val contentType = resolveContentType(uri, displayName)
        val targetDir = File(cacheDir, "picked_documents")
        if (!targetDir.exists()) targetDir.mkdirs()

        val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val targetFile = File(targetDir, "${System.currentTimeMillis()}-$safeName")

        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Cannot open selected file." }
            targetFile.outputStream().use { output -> input.copyTo(output) }
        }

        return mapOf(
            "path" to targetFile.absolutePath,
            "name" to displayName,
            "contentType" to contentType,
            "size" to targetFile.length()
        )
    }

    private fun queryDisplayName(uri: Uri): String {
        contentResolver.query(uri, null, null, null, null).use { cursor ->
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) return cursor.getString(index) ?: ""
            }
        }
        return uri.lastPathSegment ?: ""
    }

    private fun resolveContentType(uri: Uri, fileName: String): String {
        val fromResolver = contentResolver.getType(uri)
        if (!fromResolver.isNullOrBlank()) return fromResolver

        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".pdf") -> "application/pdf"
            lower.endsWith(".jpg") || lower.endsWith(".jpeg") -> "image/jpeg"
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".webp") -> "image/webp"
            lower.endsWith(".gif") -> "image/gif"
            lower.endsWith(".bmp") -> "image/bmp"
            lower.endsWith(".heic") || lower.endsWith(".heif") -> "image/heic"
            lower.endsWith(".tiff") || lower.endsWith(".tif") -> "image/tiff"
            else -> "application/octet-stream"
        }
    }

    private fun googleCallbackFromIntent(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme == "diyar" && data.host == "auth" && data.path == "/google-callback") {
            return data.toString()
        }
        return null
    }
}
