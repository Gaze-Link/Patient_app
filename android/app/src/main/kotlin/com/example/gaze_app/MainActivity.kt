package com.example.gaze_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.View

class MainActivity : FlutterActivity() {
    private val immersiveFlags = (
        View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )

    override fun onCreate(savedInstanceState: Bundle?) {
        window.decorView.systemUiVisibility = immersiveFlags
        super.onCreate(savedInstanceState)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) window.decorView.systemUiVisibility = immersiveFlags
    }
}
