package `in`.mantraapp.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Prevent screenshots in sensitive screens (set from Flutter via platform channel)
    // FLAG_SECURE is toggled per-screen via ScreenshotPrevention channel
  }
}
