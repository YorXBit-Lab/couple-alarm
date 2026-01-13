package com.yorxbit.couplealarm

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class PluginService :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_NAME = "app.channel/plugin"
        const val WAKE_LOCK_TAG = "CoupleAlarm::AlarmWakeLock"
        const val TAG = "PluginService"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseWakeLockInternal()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "isUnlocked" -> {
                try {
                    val km = applicationContext
                        .getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    result.success(!km.isKeyguardLocked)
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking unlock status", e)
                    result.error("KEYGUARD_ERROR", e.message, null)
                }
            }

            "wakeScreen" -> {
                activity?.let { act ->
                    try {
                        
                        acquireWakeLock()

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            act.setShowWhenLocked(true)
                            act.setTurnScreenOn(true)
                            
                            act.window.addFlags(
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
                            )
                            
                        } else {
                            @Suppress("DEPRECATION")
                            act.window.addFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
                            )
                            
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val keyguardManager = applicationContext
                                .getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                            
                            if (keyguardManager.isKeyguardLocked) {
                                
                                keyguardManager.requestDismissKeyguard(
                                    act,
                                    object : KeyguardManager.KeyguardDismissCallback() {
                                        override fun onDismissSucceeded() {
                                            super.onDismissSucceeded()
                                        }

                                        override fun onDismissCancelled() {
                                            super.onDismissCancelled()
                                        }

                                        override fun onDismissError() {
                                            super.onDismissError()
                                        }
                                    }
                                )
                            } else {
                                Log.d(TAG, "Keyguard not locked")
                            }
                        }

                        act.window.decorView.systemUiVisibility = (
                            android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        )

                        result.success(true)
                        
                    } catch (e: Exception) {
                        result.error("WAKE_SCREEN_ERROR", e.message, null)
                    }
                } ?: run {
                    result.error("NO_ACTIVITY", "Activity not attached", null)
                }
            }

            "releaseScreen" -> {
                activity?.let { act ->
                    try {
                        releaseWakeLockInternal()

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            act.setShowWhenLocked(false)
                            act.setTurnScreenOn(false)
                        }
                        
                        act.window.clearFlags(
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
                        )

                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) {
                            @Suppress("DEPRECATION")
                            act.window.clearFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }

                        result.success(true)
                        
                    } catch (e: Exception) {
                        result.error("RELEASE_SCREEN_ERROR", e.message, null)
                    }
                } ?: run {
                    result.error("NO_ACTIVITY", "Activity not attached", null)
                }
            }

            "exitApp" -> {
                activity?.let {
                    try {
                        releaseWakeLockInternal()
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            it.finishAndRemoveTask()
                        } else {
                            it.finish()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EXIT_APP_ERROR", e.message, null)
                    }
                } ?: run {
                    result.error("NO_ACTIVITY", "Activity not attached", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = applicationContext
                .getSystemService(Context.POWER_SERVICE) as PowerManager
            
            releaseWakeLockInternal()
            
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                @Suppress("DEPRECATION")
                PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE
            } else {
                @Suppress("DEPRECATION")
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE
            }
            
            wakeLock = powerManager.newWakeLock(flags, WAKE_LOCK_TAG)
            wakeLock?.acquire(10 * 60 * 1000L)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring wake lock", e)
        }
    }

    private fun releaseWakeLockInternal() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, " Error releasing wake lock", e)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        releaseWakeLockInternal()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}