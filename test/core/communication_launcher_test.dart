import 'package:dental_clini_management_saas/core/utils/communication_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunicationLauncher phone number formatting', () {
    test('cleans international plus format correctly', () {
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('+963 991 234 567'),
        '963991234567',
      );
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('+1 (555) 123-4567'),
        '15551234567',
      );
    });

    test('strips leading 00 international prefix', () {
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('00963991234567'),
        '963991234567',
      );
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('00 1 555 123 4567'),
        '15551234567',
      );
    });

    test('handles punctuation, spaces, and hyphens', () {
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('+44-20-7946-0958'),
        '442079460958',
      );
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp(' (971) 50-123-4567 '),
        '971501234567',
      );
    });

    test('returns empty string when no digits exist', () {
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('+++---()'),
        '',
      );
      expect(
        CommunicationLauncher.cleanPhoneNumberForWhatsApp('   '),
        '',
      );
    });
  });
}
