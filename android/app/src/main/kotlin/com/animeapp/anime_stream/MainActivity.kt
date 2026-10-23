package com.animeapp.anime_stream

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val clazz = Class.forName("com.startapp.sdk.adsbase.StartAppSDK")
            val method = clazz.getMethod(
                "init",
                android.content.Context::class.java,
                java.lang.String::class.java,
                java.lang.Boolean.TYPE
            )
            method.invoke(null, this, "114104571", false)
            android.util.Log.i("MainActivity", "StartAppSDK initialized successfully with App ID 114104571")
        } catch (t: Throwable) {
            android.util.Log.w("MainActivity", "StartAppSDK reflection init note: $t")
        }
    }
}
