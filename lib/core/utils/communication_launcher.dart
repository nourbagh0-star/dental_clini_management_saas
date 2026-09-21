import 'package:url_launcher/url_launcher.dart';

/// Utilities for direct patient communication via WhatsApp, Phone Call, and Email.
class CommunicationLauncher {
  const CommunicationLauncher._();

  /// Formats phone number into international digit-only format suitable for WhatsApp `wa.me`.
  /// Strips whitespace, dashes, brackets, plus signs, and leading international `00`.
  static String cleanPhoneNumberForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  /// Opens a WhatsApp chat directly with the specified [phone] number.
  /// If [message] is provided, it is pre-populated in the chat input.
  static Future<bool> launchWhatsApp({
    required String phone,
    String? message,
  }) async {
    final cleanPhone = cleanPhoneNumberForWhatsApp(phone);
    if (cleanPhone.isEmpty) return false;

    final query = (message != null && message.trim().isNotEmpty)
        ? '?text=${Uri.encodeComponent(message.trim())}'
        : '';
    final uri = Uri.parse('https://wa.me/$cleanPhone$query');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launches native phone dialer for [phone].
  static Future<bool> launchPhoneCall(String phone) async {
    final clean = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return false;
    final uri = Uri.parse('tel:$clean');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Launches default mail client with [email], optional [subject] and [body].
  static Future<bool> launchEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri(
      scheme: 'mailto',
      path: trimmed,
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
