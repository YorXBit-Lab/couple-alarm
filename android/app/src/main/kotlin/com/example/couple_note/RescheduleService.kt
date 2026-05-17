package com.yorxbit.couplealarm

import android.content.Context
import android.content.Intent
import androidx.core.app.JobIntentService
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
// Nếu headless plugin nào không tự auto-register, hãy mở dòng dưới:
// import io.flutter.plugins.GeneratedPluginRegistrant

class RescheduleService : JobIntentService() {

    override fun onHandleWork(intent: Intent) {
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(this)
            loader.ensureInitializationComplete(this, null)

            val engine = FlutterEngine(applicationContext)
            // GeneratedPluginRegistrant.registerWith(engine) // chỉ bật nếu thực sự cần

            val appBundlePath = loader.findAppBundlePath()
            val entrypoint = DartExecutor.DartEntrypoint(appBundlePath, "rescheduleAlarms")
            engine.dartExecutor.executeDartEntrypoint(entrypoint)

            // cho engine chút thời gian; có thể bỏ nếu không cần
            Thread.sleep(1500)
            engine.destroy()
        } catch (_: Exception) { }
    }

    companion object {
        private const val JOB_ID = 1001
        fun enqueueWork(context: Context) {
            enqueueWork(
                context,
                RescheduleService::class.java,
                JOB_ID,
                Intent(context, RescheduleService::class.java)
            )
        }
    }
}
