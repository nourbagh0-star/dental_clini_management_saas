import 'dart:typed_data';

import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_models.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a JPEG signature and normalizes jpeg extension', () {
    final file = PatientFileValidator.validate(
      name: 'demo.jpeg',
      bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
    );

    expect(file.extension, 'jpg');
    expect(file.mimeType, 'image/jpeg');
  });

  test('accepts PNG and PDF signatures', () {
    final png = PatientFileValidator.validate(
      name: 'demo.png',
      bytes: Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
    );
    final pdf = PatientFileValidator.validate(
      name: 'demo.pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
    );

    expect(png.mimeType, 'image/png');
    expect(pdf.mimeType, 'application/pdf');
  });

  test('rejects an extension and signature mismatch', () {
    expect(
      () => PatientFileValidator.validate(
        name: 'fake.pdf',
        bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
      ),
      throwsA(
        isA<PatientFileSelectionException>().having(
          (error) => error.issue,
          'issue',
          PatientFileSelectionIssue.signatureMismatch,
        ),
      ),
    );
  });

  test('rejects empty and oversized files', () {
    expect(
      () =>
          PatientFileValidator.validate(name: 'empty.pdf', bytes: Uint8List(0)),
      throwsA(isA<PatientFileSelectionException>()),
    );
    expect(
      () => PatientFileValidator.validate(
        name: 'large.pdf',
        bytes: Uint8List(PatientFileValidator.maxSizeBytes + 1),
      ),
      throwsA(
        isA<PatientFileSelectionException>().having(
          (error) => error.issue,
          'issue',
          PatientFileSelectionIssue.tooLarge,
        ),
      ),
    );
  });
}
