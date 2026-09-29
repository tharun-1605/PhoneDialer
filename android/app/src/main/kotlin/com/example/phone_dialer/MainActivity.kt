package com.example.phone_dialer

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager

import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.phone_dialer/default_dialer"
    private val EVENT_CHANNEL = "com.example.phone_dialer/call_events"
    private val REQUEST_CODE_SET_DEFAULT_DIALER = 123

    companion object {
        var callEventSink: EventChannel.EventSink? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    callEventSink = events
                    // Check if there's already an active call
                    CallService.currentCall?.let {
                        val number = it.details?.handle?.schemeSpecificPart ?: "Unknown"
                        val isIncoming = it.state == android.telecom.Call.STATE_RINGING
                        callEventSink?.success(mapOf("number" to number, "isIncoming" to isIncoming))
                    }
                }
                override fun onCancel(arguments: Any?) {
                    callEventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "requestDefaultDialer" -> {
                    requestDefaultDialer()
                    result.success(null)
                }
                "isDefaultDialer" -> {
                    result.success(isDefaultDialer())
                }
                "answerCall" -> {
                    CallService.currentCall?.answer(0)
                    result.success(null)
                }
                "rejectCall" -> {
                    CallService.currentCall?.reject(false, null)
                    result.success(null)
                }
                "disconnectCall" -> {
                    CallService.currentCall?.disconnect()
                    result.success(null)
                }
                "setMute" -> {
                    val isMuted = call.argument<Boolean>("isMuted") ?: false
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    // Not easily toggled without InCallService CallAudioState, but InCallService provides setMuted
                    CallService.instance?.setMuted(isMuted)
                    result.success(null)
                }
                "setSpeaker" -> {
                    val isSpeaker = call.argument<Boolean>("isSpeaker") ?: false
                    CallService.instance?.setAudioRoute(
                        if (isSpeaker) android.telecom.CallAudioState.ROUTE_SPEAKER
                        else android.telecom.CallAudioState.ROUTE_EARPIECE
                    )
                    result.success(null)
                }
                "setHold" -> {
                    val isHold = call.argument<Boolean>("isHold") ?: false
                    if (isHold) {
                        CallService.currentCall?.hold()
                    } else {
                        CallService.currentCall?.unhold()
                    }
                    result.success(null)
                }
                "playDtmfTone" -> {
                    val digit = call.argument<String>("digit")
                    if (digit != null && digit.isNotEmpty()) {
                        CallService.currentCall?.playDtmfTone(digit[0])
                        // Stop tone immediately for short press
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            CallService.currentCall?.stopDtmfTone()
                        }, 200)
                    }
                    result.success(null)
                }
                "makeCall" -> {
                    val number = call.argument<String>("number")
                    if (number != null) {
                        makeCall(number)
                        result.success(null)
                    } else {
                        result.error("INVALID_NUMBER", "Number is null", null)
                    }
                }
                "isDeviceLocked" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                    result.success(keyguardManager.isKeyguardLocked)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun makeCall(number: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$number")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (checkSelfPermission(Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
                startActivity(intent)
            }
        } else {
            startActivity(intent)
        }
    }

    private fun requestDefaultDialer() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
            startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivity(intent)
        }
    }

    private fun isDefaultDialer(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            return roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
        } else {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            return packageName == telecomManager.defaultDialerPackage
        }
    }
}
