import 'dart:convert';

abstract final class AuthValidation {
  static bool email(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  static bool code(String value) => RegExp(r'^\d{6}$').hasMatch(value);
  static bool password(String value) =>
      value.runes.length >= 15 && utf8.encode(value).length <= 72;
}
