import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Conditional import for web download
import 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Exports and shares an actual .csv file
  Future<bool> exportCsv(String csvData, String fileName) async {
    try {
      if (kIsWeb) {
        downloadFileWeb(fileName, csvData, 'text/csv');
        return true;
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvData, flush: true);

        final xFile = XFile(file.path, mimeType: 'text/csv', name: fileName);
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            subject: fileName,
          ),
        );
        return result.status == ShareResultStatus.success ||
            result.status == ShareResultStatus.dismissed;
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return false;
    }
  }

  /// Exports and shares an actual .json backup file
  Future<bool> exportBackupJson(String jsonData, String fileName) async {
    try {
      if (kIsWeb) {
        downloadFileWeb(fileName, jsonData, 'application/json');
        return true;
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonData, flush: true);

        final xFile =
            XFile(file.path, mimeType: 'application/json', name: fileName);
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            subject: fileName,
          ),
        );
        return result.status == ShareResultStatus.success ||
            result.status == ShareResultStatus.dismissed;
      }
    } catch (e) {
      debugPrint('Error exporting backup file: $e');
      return false;
    }
  }

  /// Uses FilePicker to pick a .json backup file from device storage
  Future<String?> pickBackupFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        return utf8.decode(bytes);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
}
