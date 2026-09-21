import 'package:freezed_annotation/freezed_annotation.dart';

part 'appearance.freezed.dart';
part 'appearance.g.dart';

enum AppThemeMode { system, light, dark }

enum AppLanguage { system, english, russian, arabic }

/// Non-sensitive application preferences, not a clinical database DTO.
@freezed
abstract class Appearance with _$Appearance {
  const factory Appearance({
    @Default(AppThemeMode.system) AppThemeMode theme,
    @Default(AppLanguage.system) AppLanguage language,
  }) = _Appearance;

  factory Appearance.fromJson(Map<String, dynamic> json) =>
      _$AppearanceFromJson(json);
}

@freezed
abstract class AppearanceState with _$AppearanceState {
  const factory AppearanceState({
    @Default(Appearance()) Appearance preferences,
    @Default(false) bool busy,
    @Default(false) bool storageFailed,
  }) = _AppearanceState;
}
