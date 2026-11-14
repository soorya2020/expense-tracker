package com.soorya.tally

import android.content.Intent
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tally/app").setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url"))).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tally/sms").setMethodCallHandler { call, result ->
            if (call.method != "inbox") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val since = (call.argument<Number>("since") ?: 0).toLong()
            Thread {
                try {
                    val out = ArrayList<Map<String, Any>>()
                    contentResolver.query(
                        Telephony.Sms.Inbox.CONTENT_URI,
                        arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
                        "${Telephony.Sms.DATE} > ?",
                        arrayOf(since.toString()),
                        "${Telephony.Sms.DATE} DESC LIMIT 2000"
                    )?.use { c ->
                        while (c.moveToNext()) {
                            out.add(mapOf(
                                "sender" to (c.getString(0) ?: ""),
                                "body" to (c.getString(1) ?: ""),
                                "date" to c.getLong(2)
                            ))
                        }
                    }
                    runOnUiThread { result.success(out) }
                } catch (e: Exception) {
                    runOnUiThread { result.error("sms", e.message, null) }
                }
            }.start()
        }
    }
}
