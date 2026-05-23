package com.igreja.centro_social_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
	private val channelName = "centro_social_app/report_export"
	private val createDocumentRequestCode = 7421

	private var pendingResult: MethodChannel.Result? = null
	private var pendingBytes: ByteArray? = null
	private var pendingFileName: String? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"saveCsvReport" -> {
						if (pendingResult != null) {
							result.error(
								"IN_PROGRESS",
								"Já existe uma exportação em andamento.",
								null,
							)
							return@setMethodCallHandler
						}

						val fileName = call.argument<String>("fileName")
						val csvContent = call.argument<String>("csvContent")
						if (fileName.isNullOrBlank() || csvContent == null) {
							result.error(
								"INVALID_ARGS",
								"fileName e csvContent são obrigatórios.",
								null,
							)
							return@setMethodCallHandler
						}

						pendingResult = result
						pendingBytes = csvContent.toByteArray(Charsets.UTF_8)
						pendingFileName = fileName

						val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
							addCategory(Intent.CATEGORY_OPENABLE)
							type = "text/csv"
							putExtra(Intent.EXTRA_TITLE, fileName)
						}

						try {
							startActivityForResult(intent, createDocumentRequestCode)
						} catch (error: Exception) {
							pendingBytes = null
							pendingFileName = null
							pendingResult = null
							result.error(
								"SAVE_FAILED",
								error.message,
								null,
							)
						}
					}

					else -> result.notImplemented()
				}
			}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)

		if (requestCode != createDocumentRequestCode) {
			return
		}

		val result = pendingResult ?: return
		val bytes = pendingBytes
		val fileName = pendingFileName

		pendingBytes = null
		pendingFileName = null
		pendingResult = null

		if (resultCode != Activity.RESULT_OK) {
			result.success(null)
			return
		}

		val uri: Uri = data?.data ?: run {
			result.error("SAVE_FAILED", "Nenhum destino foi selecionado.", null)
			return
		}

		if (bytes == null) {
			result.error("SAVE_FAILED", "Conteúdo do CSV ausente.", null)
			return
		}

		try {
			contentResolver.openOutputStream(uri)?.use { outputStream ->
				outputStream.write(bytes)
				outputStream.flush()
			} ?: throw IOException("Não foi possível abrir o arquivo de saída.")

			result.success(fileName ?: "arquivo.csv")
		} catch (error: Exception) {
			result.error("SAVE_FAILED", error.message, null)
		}
	}
}
