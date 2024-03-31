package com.khokan.flutter_method_channel

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Build.VERSION
import android.os.Handler
import android.os.Looper
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.widget.Toast
import androidx.annotation.ColorRes
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Timer
import java.util.TimerTask

class MainActivity : FlutterActivity() {

    companion object {
        private const val DEFAULT_NOTIFICATION_ID = 1001
        private const val DEFAULT_NOTIFICATION_CHANNEL_ID = "DefaultChannel"
        private const val DEFAULT_CHANNEL_NAME = "Default Notification"

        const val INCOMING_CALL_NOTIFICATION_ID = 1002
        private const val INCOMING_CALL_CHANNEL_ID = "IncomingCallChannel"
        private const val INCOMING_CHANNEL_NAME = "Incoming call"
    }

    private val channelName = "nativeEvent"
    private val eventChannelName = "timeHandlerEvent"
    private var timeCounter = 100
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(TimeHandler)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ShowToast" -> {
                val msg = call.arguments as String
                showToast(msg)
            }

            "getBatteryLevel" -> {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            }

            "getDateTime" -> {
                scheduleDateTimeEvent()
            }

            "displayNotification" -> {
                val title = call.argument<String>("title")
                val text = call.argument<String>("text")
                displayNotification(title, text)
                result.success(null)
            }

            "showIncomingCallBanner" -> {
                showIncomingCallNotification()
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getActionText(title: String, @ColorRes colorRes: Int): Spannable {
        val spannable: Spannable = SpannableString(title)
        if (VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            spannable.setSpan(ForegroundColorSpan(getColor(colorRes)), 0, spannable.length, 0)
        }
        return spannable
    }

    @SuppressLint("MissingPermission")
    private fun showIncomingCallNotification() {
        val intentAccept = Intent(context, MyReceiverAccept::class.java)
        intentAccept.putExtra("NOTIFICATION_ID", INCOMING_CALL_NOTIFICATION_ID)
        intentAccept.action = ("accept")

        val intentReject = Intent(context, MyReceiverAccept::class.java)
        intentReject.putExtra("NOTIFICATION_ID", INCOMING_CALL_NOTIFICATION_ID)
        intentReject.action = ("reject")

        val flag = if (VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntentAccept = PendingIntent.getBroadcast(context, 0, intentAccept, flag)
        val pendingIntentReject = PendingIntent.getBroadcast(context, 0, intentReject, flag)

        val acceptCall: NotificationCompat.Action = NotificationCompat.Action.Builder(
            R.drawable.btn_acpt, getActionText("Accept", R.color.green), pendingIntentAccept
        ).build()

        val rejectCall: NotificationCompat.Action = NotificationCompat.Action.Builder(
            R.drawable.btn_rjt, getActionText("Reject", R.color.red), pendingIntentReject
        ).build()

        // When device locked show fullscreen notification start
        val fullScreenPIntent =
            PendingIntent.getActivity(this, 1204, Intent(), PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, INCOMING_CALL_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Incoming Call")
            .setContentText("You have an incoming call")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(acceptCall)
            .addAction(rejectCall)
            .setFullScreenIntent(fullScreenPIntent, true)
            .setTimeoutAfter(30000L)
            .build()

        with(NotificationManagerCompat.from(this)) {
            createNotificationChannel()
            notify(INCOMING_CALL_NOTIFICATION_ID, notification)
        }
    }

    private fun NotificationManagerCompat.createNotificationChannel() {
        if (VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                INCOMING_CALL_CHANNEL_ID,
                INCOMING_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setShowBadge(false)
                enableVibration(true)
            }
            createNotificationChannel(channel)
        }
    }

    private fun displayNotification(title: String?, text: String?) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create the Notification Channel
        if (VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                DEFAULT_NOTIFICATION_CHANNEL_ID,
                DEFAULT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        // Build the notification
        val notificationBuilder = NotificationCompat.Builder(this, DEFAULT_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        // Display the notification
        notificationManager.notify(DEFAULT_NOTIFICATION_ID, notificationBuilder.build())
    }

    private fun showToast(msg: String) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(
                null, IntentFilter(
                    Intent.ACTION_BATTERY_CHANGED
                )
            )
            batteryLevel =
                intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(
                    BatteryManager.EXTRA_SCALE,
                    -1
                )
        }

        return batteryLevel
    }

    private fun scheduleDateTimeEvent() {
        Timer().schedule(object : TimerTask() {
            override fun run() {
                Handler(Looper.getMainLooper()).post {
                    dateTimeEvent()
                }
            }
        }, 0, 2000)
    }

    private fun dateTimeEvent() {
        timeCounter++
        methodChannel.invokeMethod("dateTimeHandler", timeCounter)
    }

    object TimeHandler : EventChannel.StreamHandler {
        private val handler = Handler(Looper.getMainLooper())
        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            eventSink = sink
            val runnable = object : Runnable {
                override fun run() {
                    handler.post {
                        val dateFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
                        val time = dateFormat.format(Date())
                        eventSink?.success(time)
                    }
                    handler.postDelayed(this, 1000)
                }
            }
            handler.postDelayed(runnable, 1000)
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }
}

class MyReceiverAccept : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val notificationManager = NotificationManagerCompat.from(context!!)
        when (intent?.action) {
            "accept" -> {
                Toast.makeText(context, "Call Accepted", Toast.LENGTH_LONG).show()
            }

            "reject" -> {
                Toast.makeText(context, "Call Rejected", Toast.LENGTH_LONG).show()
            }
        }
        if (MainActivity.INCOMING_CALL_NOTIFICATION_ID != null) {
            notificationManager.cancel(MainActivity.INCOMING_CALL_NOTIFICATION_ID)
        }
    }

}