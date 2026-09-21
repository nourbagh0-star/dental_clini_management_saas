// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Appearance _$AppearanceFromJson(Map<String, dynamic> json) => _Appearance(
  theme:
      $enumDecodeNullable(_$AppThemeModeEnumMap, json['theme']) ??
      AppThemeMode.system,
  language:
      $enumDecodeNullable(_$AppLanguageEnumMap, json['language']) ??
      AppLanguage.system,
);

Map<String, dynamic> _$AppearanceToJson(_Appearance instance) =>
    <String, dynamic>{
      'theme': _$AppThemeModeEnumMap[instance.theme]!,
      'language': _$AppLanguageEnumMap[instance.language]!,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$AppLanguageEnumMap = {
  AppLanguage.system: 'system',
  AppLanguage.english: 'english',
  AppLanguage.russian: 'russian',
  AppLanguage.arabic: 'arabic',
};
