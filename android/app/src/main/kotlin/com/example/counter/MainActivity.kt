package com.wqar.quran_mem_helper

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedWriter
import java.io.OutputStream
import java.io.OutputStreamWriter
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
  private val CHANNEL_NAME = "org.quran_rev_helper/backupDB"
  private val WRITE_REQUEST_CODE = 101
  private lateinit var result: MethodChannel.Result
    private lateinit var data: String

      override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
          flutterEngine.dartExecutor.binaryMessenger,
          CHANNEL_NAME
        ).setMethodCallHandler { call, callResult ->

          if (call.method == "backupDB") {
            val jsonData = call.argument<String?>("data")
            if (jsonData != null) {
              result = callResult
              data = jsonData
              backupDatabase()
            } else {
              result.error("ERROR", "No data provided", null)
            }
          } else {
            result.notImplemented()
          }
        }
      }

      private fun backupDatabase() {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.type = "application/json"
        intent.putExtra(Intent.EXTRA_TITLE, "quran_memorization_backup.json")
        startActivityForResult(intent, WRITE_REQUEST_CODE)
      }

      override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        // Check which request we're responding to
        if (requestCode == WRITE_REQUEST_CODE) {
          // Make sure the request was successful
          if (resultCode == Activity.RESULT_OK) {
            val uri = data?.data
            if (uri != null) {
              writeInFile(uri)
            } else {
              result.error("ERROR", "No uri", null)
            }
          } else {
            result.success("CANCELED")
          }
        }
      }

      private fun writeInFile(uri: Uri){
        try {
          val outputStream = contentResolver.openOutputStream(uri) as FileOutputStream?
          if (outputStream == null) {
            result.error("ERROR", "Failed to get output stream", null)
            return
          }
          outputStream.channel.truncate(0)
          outputStream.write(data.toByteArray())
          outputStream.close()
          result.success("SUCCESS")
        } catch (e:Exception){
          result.error("ERROR", "Unable to write: $e", null)
        }
      }
}
