import 'dart:typed_data';

import 'patient_file_models.dart';

abstract final class PatientFileValidator {
  static const maxSizeBytes = 15 * 1024 * 1024;

  static SelectedPatientFile validate({
    required String name,
    required Uint8List bytes,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > 255 ||
        normalizedName.contains('/') ||
        normalizedName.contains('\\') ||
        normalizedName.runes.any((value) => value < 32 || value == 127)) {
      throw const PatientFileSelectionException(
        PatientFileSelectionIssue.invalidName,
      );
    }
    if (bytes.isEmpty) {
      throw const PatientFileSelectionException(
        PatientFileSelectionIssue.empty,
      );
    }
    if (bytes.length > maxSizeBytes) {
      throw const PatientFileSelectionException(
        PatientFileSelectionIssue.tooLarge,
      );
    }
    final separator = normalizedName.lastIndexOf('.');
    final rawExtension = separator < 0
        ? ''
        : normalizedName.substring(separator + 1).toLowerCase();
    final extension = rawExtension == 'jpeg' ? 'jpg' : rawExtension;
    final mimeType = switch (extension) {
      'jpg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => throw const PatientFileSelectionException(
        PatientFileSelectionIssue.typeNotAllowed,
      ),
    };
    if (_detectedMime(bytes) != mimeType) {
      throw const PatientFileSelectionException(
        PatientFileSelectionIssue.signatureMismatch,
      );
    }
    return SelectedPatientFile(
      name: normalizedName,
      extension: extension,
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  static String? _detectedMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 5 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2d) {
      return 'application/pdf';
    }
    return null;
  }
}
