import 'dart:io';

import 'package:flutter/services.dart';

/// Pont natif (MainActivity.kt) : Telechargements, partage, photos.
/// Aucun plugin tiers.
class FileSaver {
  static const MethodChannel _channel = MethodChannel('faztyroid/files');

  /// Retourne l'URI du fichier cree.
  static Future<String> saveToDownloads(String name, Uint8List bytes) async {
    final uri = await _channel
        .invokeMethod<String>('saveToDownloads', {'name': name, 'bytes': bytes});
    if (uri == null) {
      throw PlatformException(code: 'NO_RESULT', message: 'Aucun fichier créé');
    }
    return uri;
  }

  static Future<void> share(String uri) async {
    await _channel.invokeMethod<void>('shareFile', {'uri': uri});
  }

  /// Choisit une photo dans la galerie ; la copie dans le stockage prive de
  /// l'application. Retourne le chemin du fichier, ou null si annule.
  static Future<String?> pickImage() =>
      _channel.invokeMethod<String>('pickImage');

  /// Prend une photo avec l'appareil photo ; meme retour que [pickImage].
  static Future<String?> captureImage() =>
      _channel.invokeMethod<String>('captureImage');
}

/// Supprime un fichier local sans jamais lever d'erreur.
Future<void> deleteLocalFile(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
