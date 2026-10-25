package com.animeapp.anime_stream

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
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

