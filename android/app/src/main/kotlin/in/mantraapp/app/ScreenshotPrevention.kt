package `in`.mantraapp.app

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ScreenshotPrevention {
  private const val CHANNEL = "in.mantraapp.app/screenshot"

  fun register(activity: MainActivity, flutterEngine: FlutterEngine) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "enable" -> {
          activity.window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
          )
          result.success(null)
        }
        "disable" -> {
          activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }
}
