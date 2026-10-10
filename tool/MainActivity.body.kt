
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val xlsxMime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    private val reqPick = 4101
    private val reqCapture = 4102
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCaptureUri: Uri? = null

    private fun copyToAttachments(uri: Uri): String? {
        val dir = File(filesDir, "attachments")
        if (!dir.exists()) dir.mkdirs()
        val out = File(dir, "img_" + System.currentTimeMillis() + ".jpg")
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { i -> out.outputStream().use { o -> i.copyTo(o) } }
        return out.absolutePath
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqPick && requestCode != reqCapture) return
        val res = pendingResult
        pendingResult = null
        val captureUri = pendingCaptureUri
        pendingCaptureUri = null
        if (res == null) return
        try {
            if (resultCode != Activity.RESULT_OK) {
                if (captureUri != null) contentResolver.delete(captureUri, null, null)
                res.success(null)
                return
            }
            val src: Uri? = if (requestCode == reqCapture) captureUri else data?.data
            if (src == null) {
                res.success(null)
                return
            }
            val path = copyToAttachments(src)
            if (requestCode == reqCapture && captureUri != null) {
                contentResolver.delete(captureUri, null, null)
            }
            res.success(path)
        } catch (e: Exception) {
            res.error("IMAGE_FAILED", e.message, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "faztyroid/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        try {
                            val name = call.argument<String>("name")
                            val bytes = call.argument<ByteArray>("bytes")
                            if (name == null || bytes == null) {
                                result.error("BAD_ARGS", "Arguments manquants", null)
                            } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                result.error("UNSUPPORTED", "Android 10 ou plus requis", null)
                            } else {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                                    put(MediaStore.Downloads.MIME_TYPE, xlsxMime)
                                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                }
                                val uri = contentResolver.insert(
                                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, values
                                )
                                if (uri == null) {
                                    result.error("NO_URI", "Création du fichier impossible", null)
                                } else {
                                    contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                                    result.success(uri.toString())
                                }
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "shareFile" -> {
                        try {
                            val uriText = call.argument<String>("uri")
                            if (uriText == null) {
                                result.error("BAD_ARGS", "URI manquante", null)
                            } else {
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = xlsxMime
                                    putExtra(Intent.EXTRA_STREAM, Uri.parse(uriText))
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(Intent.createChooser(send, null))
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.error("SHARE_FAILED", e.message, null)
                        }
                    }
                    "pickImage" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "Une sélection est déjà en cours", null)
                        } else {
                            try {
                                pendingResult = result
                                val pick = Intent(Intent.ACTION_GET_CONTENT).apply {
                                    type = "image/*"
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                }
                                startActivityForResult(Intent.createChooser(pick, null), reqPick)
                            } catch (e: Exception) {
                                pendingResult = null
                                result.error("PICK_FAILED", e.message, null)
                            }
                        }
                    }
                    "captureImage" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "Une capture est déjà en cours", null)
                        } else {
                            try {
                                val values = ContentValues().apply {
                                    put(MediaStore.Images.Media.DISPLAY_NAME, "FazTyroid_" + System.currentTimeMillis() + ".jpg")
                                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                }
                                val uri = contentResolver.insert(
                                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values
                                )
                                if (uri == null) {
                                    result.error("NO_URI", "Création de la photo impossible", null)
                                } else {
                                    pendingResult = result
                                    pendingCaptureUri = uri
                                    val shot = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                                        putExtra(MediaStore.EXTRA_OUTPUT, uri)
                                    }
                                    startActivityForResult(shot, reqCapture)
                                }
                            } catch (e: Exception) {
                                pendingResult = null
                                pendingCaptureUri = null
                                result.error("CAPTURE_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
