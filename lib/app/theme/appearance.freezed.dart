// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appearance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Appearance {

 AppThemeMode get theme; AppLanguage get language;
/// Create a copy of Appearance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppearanceCopyWith<Appearance> get copyWith => _$AppearanceCopyWithImpl<Appearance>(this as Appearance, _$identity);

  /// Serializes this Appearance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Appearance&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,language);

@override
String toString() {
  return 'Appearance(theme: $theme, language: $language)';
}


}

/// @nodoc
abstract mixin class $AppearanceCopyWith<$Res>  {
  factory $AppearanceCopyWith(Appearance value, $Res Function(Appearance) _then) = _$AppearanceCopyWithImpl;
@useResult
$Res call({
 AppThemeMode theme, AppLanguage language
});




}
/// @nodoc
class _$AppearanceCopyWithImpl<$Res>
    implements $AppearanceCopyWith<$Res> {
  _$AppearanceCopyWithImpl(this._self, this._then);

  final Appearance _self;
  final $Res Function(Appearance) _then;

/// Create a copy of Appearance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? language = null,}) {
  return _then(_self.copyWith(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemeMode,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,
  ));
}

}


/// Adds pattern-matching-related methods to [Appearance].
extension AppearancePatterns on Appearance {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Appearance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Appearance() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Appearance value)  $default,){
final _that = this;
switch (_that) {
case _Appearance():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Appearance value)?  $default,){
final _that = this;
switch (_that) {
case _Appearance() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode theme,  AppLanguage language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Appearance() when $default != null:
return $default(_that.theme,_that.language);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode theme,  AppLanguage language)  $default,) {final _that = this;
switch (_that) {
case _Appearance():
return $default(_that.theme,_that.language);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode theme,  AppLanguage language)?  $default,) {final _that = this;
switch (_that) {
case _Appearance() when $default != null:
return $default(_that.theme,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Appearance implements Appearance {
  const _Appearance({this.theme = AppThemeMode.system, this.language = AppLanguage.system});
  factory _Appearance.fromJson(Map<String, dynamic> json) => _$AppearanceFromJson(json);

@override@JsonKey() final  AppThemeMode theme;
@override@JsonKey() final  AppLanguage language;

/// Create a copy of Appearance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppearanceCopyWith<_Appearance> get copyWith => __$AppearanceCopyWithImpl<_Appearance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppearanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Appearance&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,language);

@override
String toString() {
  return 'Appearance(theme: $theme, language: $language)';
}


}

/// @nodoc
abstract mixin class _$AppearanceCopyWith<$Res> implements $AppearanceCopyWith<$Res> {
  factory _$AppearanceCopyWith(_Appearance value, $Res Function(_Appearance) _then) = __$AppearanceCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode theme, AppLanguage language
});




}
/// @nodoc
class __$AppearanceCopyWithImpl<$Res>
    implements _$AppearanceCopyWith<$Res> {
  __$AppearanceCopyWithImpl(this._self, this._then);

  final _Appearance _self;
  final $Res Function(_Appearance) _then;

/// Create a copy of Appearance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? language = null,}) {
  return _then(_Appearance(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemeMode,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,
  ));
}


}

/// @nodoc
mixin _$AppearanceState {

 Appearance get preferences; bool get busy; bool get storageFailed;
/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppearanceStateCopyWith<AppearanceState> get copyWith => _$AppearanceStateCopyWithImpl<AppearanceState>(this as AppearanceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppearanceState&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.storageFailed, storageFailed) || other.storageFailed == storageFailed));
}


@override
int get hashCode => Object.hash(runtimeType,preferences,busy,storageFailed);

@override
String toString() {
  return 'AppearanceState(preferences: $preferences, busy: $busy, storageFailed: $storageFailed)';
}


}

/// @nodoc
abstract mixin class $AppearanceStateCopyWith<$Res>  {
  factory $AppearanceStateCopyWith(AppearanceState value, $Res Function(AppearanceState) _then) = _$AppearanceStateCopyWithImpl;
@useResult
$Res call({
 Appearance preferences, bool busy, bool storageFailed
});


$AppearanceCopyWith<$Res> get preferences;

}
/// @nodoc
class _$AppearanceStateCopyWithImpl<$Res>
    implements $AppearanceStateCopyWith<$Res> {
  _$AppearanceStateCopyWithImpl(this._self, this._then);

  final AppearanceState _self;
  final $Res Function(AppearanceState) _then;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preferences = null,Object? busy = null,Object? storageFailed = null,}) {
  return _then(_self.copyWith(
preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Appearance,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,storageFailed: null == storageFailed ? _self.storageFailed : storageFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppearanceCopyWith<$Res> get preferences {
  
  return $AppearanceCopyWith<$Res>(_self.preferences, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppearanceState].
extension AppearanceStatePatterns on AppearanceState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppearanceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppearanceState value)  $default,){
final _that = this;
switch (_that) {
case _AppearanceState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppearanceState value)?  $default,){
final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Appearance preferences,  bool busy,  bool storageFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that.preferences,_that.busy,_that.storageFailed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Appearance preferences,  bool busy,  bool storageFailed)  $default,) {final _that = this;
switch (_that) {
case _AppearanceState():
return $default(_that.preferences,_that.busy,_that.storageFailed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Appearance preferences,  bool busy,  bool storageFailed)?  $default,) {final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that.preferences,_that.busy,_that.storageFailed);case _:
  return null;

}
}

}

/// @nodoc


class _AppearanceState implements AppearanceState {
  const _AppearanceState({this.preferences = const Appearance(), this.busy = false, this.storageFailed = false});
  

@override@JsonKey() final  Appearance preferences;
@override@JsonKey() final  bool busy;
@override@JsonKey() final  bool storageFailed;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppearanceStateCopyWith<_AppearanceState> get copyWith => __$AppearanceStateCopyWithImpl<_AppearanceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppearanceState&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.storageFailed, storageFailed) || other.storageFailed == storageFailed));
}


@override
int get hashCode => Object.hash(runtimeType,preferences,busy,storageFailed);

@override
String toString() {
  return 'AppearanceState(preferences: $preferences, busy: $busy, storageFailed: $storageFailed)';
}


}

/// @nodoc
abstract mixin class _$AppearanceStateCopyWith<$Res> implements $AppearanceStateCopyWith<$Res> {
  factory _$AppearanceStateCopyWith(_AppearanceState value, $Res Function(_AppearanceState) _then) = __$AppearanceStateCopyWithImpl;
@override @useResult
$Res call({
 Appearance preferences, bool busy, bool storageFailed
});


@override $AppearanceCopyWith<$Res> get preferences;

}
/// @nodoc
class __$AppearanceStateCopyWithImpl<$Res>
    implements _$AppearanceStateCopyWith<$Res> {
  __$AppearanceStateCopyWithImpl(this._self, this._then);

  final _AppearanceState _self;
  final $Res Function(_AppearanceState) _then;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preferences = null,Object? busy = null,Object? storageFailed = null,}) {
  return _then(_AppearanceState(
preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as Appearance,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,storageFailed: null == storageFailed ? _self.storageFailed : storageFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppearanceCopyWith<$Res> get preferences {
  
  return $AppearanceCopyWith<$Res>(_self.preferences, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}

// dart format on
