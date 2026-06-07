package com.example.diyar

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "diyar/google_auth"
    private var methodChannel: MethodChannel? = null
    private var pendingGoogleCallback: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )

        pendingGoogleCallback = googleCallbackFromIntent(intent)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startGoogleLogin" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    try {
                        val browserIntent = Intent(
                            Intent.ACTION_VIEW,
                            Uri.parse(url)
                        )
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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val callback = googleCallbackFromIntent(intent) ?: return
        pendingGoogleCallback = callback
        methodChannel?.invokeMethod("onGoogleCallback", callback)
    }

    private fun googleCallbackFromIntent(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme == "diyar" &&
            data.host == "auth" &&
            data.path == "/google-callback"
        ) {
            return data.toString()
        }
        return null
    }
}
