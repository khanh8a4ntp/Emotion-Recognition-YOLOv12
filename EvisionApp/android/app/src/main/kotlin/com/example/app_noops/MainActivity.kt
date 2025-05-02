package com.example.app_noops

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app1/video_thumbnail"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getVideoThumbnail") {
                val videoPath = call.argument<String>("videoPath")
                val thumbnail = getVideoThumbnail(videoPath!!)
                if (thumbnail != null) {
                    result.success(thumbnail)
                } else {
                    result.error("UNAVAILABLE", "Không thể trích xuất khung hình.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getVideoThumbnail(videoPath: String): ByteArray? {
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(context, Uri.parse(videoPath))
            val bitmap = retriever.getFrameAtTime(1000000) // Lấy khung hình tại giây thứ 1
            val stream = ByteArrayOutputStream()
            bitmap?.compress(Bitmap.CompressFormat.PNG, 75, stream)
            val byteArray = stream.toByteArray()
            bitmap?.recycle()
            retriever.release()
            byteArray
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}