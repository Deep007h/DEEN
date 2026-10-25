package com.animeapp.anime_stream

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Request highest available display refresh rate (120Hz / 90Hz / 144Hz)
        enableHighRefreshRate()

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

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }

                if (display != null) {
                    val supportedModes = display.supportedModes
                    var highestRateMode = display.mode
                    var maxRate = display.mode.refreshRate

                    for (mode in supportedModes) {
                        if (mode.refreshRate > maxRate) {
                            maxRate = mode.refreshRate
                            highestRateMode = mode
                        }
                    }

                    if (highestRateMode != null && maxRate > 60f) {
                        val params = window.attributes
                        params.preferredDisplayModeId = highestRateMode.modeId
                        window.attributes = params
                        android.util.Log.i("MainActivity", "Configured display mode to ${maxRate}Hz (modeId: ${highestRateMode.modeId})")
                    }
                }
            } catch (t: Throwable) {
                android.util.Log.w("MainActivity", "High refresh rate setup note: $t")
            }
        }
    }
}
