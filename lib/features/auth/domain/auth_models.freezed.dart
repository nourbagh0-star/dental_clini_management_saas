// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthIdentity {

 String get id; String get email;
/// Create a copy of AuthIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthIdentityCopyWith<AuthIdentity> get copyWith => _$AuthIdentityCopyWithImpl<AuthIdentity>(this as AuthIdentity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthIdentity&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,id,email);



}

/// @nodoc
abstract mixin class $AuthIdentityCopyWith<$Res>  {
  factory $AuthIdentityCopyWith(AuthIdentity value, $Res Function(AuthIdentity) _then) = _$AuthIdentityCopyWithImpl;
@useResult
$Res call({
 String id, String email
});




}
/// @nodoc
class _$AuthIdentityCopyWithImpl<$Res>
    implements $AuthIdentityCopyWith<$Res> {
  _$AuthIdentityCopyWithImpl(this._self, this._then);

  final AuthIdentity _self;
  final $Res Function(AuthIdentity) _then;

/// Create a copy of AuthIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthIdentity].
extension AuthIdentityPatterns on AuthIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthIdentity value)  $default,){
final _that = this;
switch (_that) {
case _AuthIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _AuthIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthIdentity() when $default != null:
return $default(_that.id,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email)  $default,) {final _that = this;
switch (_that) {
case _AuthIdentity():
return $default(_that.id,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email)?  $default,) {final _that = this;
switch (_that) {
case _AuthIdentity() when $default != null:
return $default(_that.id,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _AuthIdentity implements AuthIdentity {
  const _AuthIdentity({required this.id, required this.email});
  

@override final  String id;
@override final  String email;

/// Create a copy of AuthIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthIdentityCopyWith<_AuthIdentity> get copyWith => __$AuthIdentityCopyWithImpl<_AuthIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthIdentity&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,id,email);



}

/// @nodoc
abstract mixin class _$AuthIdentityCopyWith<$Res> implements $AuthIdentityCopyWith<$Res> {
  factory _$AuthIdentityCopyWith(_AuthIdentity value, $Res Function(_AuthIdentity) _then) = __$AuthIdentityCopyWithImpl;
@override @useResult
$Res call({
 String id, String email
});




}
/// @nodoc
class __$AuthIdentityCopyWithImpl<$Res>
    implements _$AuthIdentityCopyWith<$Res> {
  __$AuthIdentityCopyWithImpl(this._self, this._then);

  final _AuthIdentity _self;
  final $Res Function(_AuthIdentity) _then;

/// Create a copy of AuthIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,}) {
  return _then(_AuthIdentity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AuthViewState {

 AuthStage get stage; AuthIdentity? get identity; String get email; bool get busy; bool get hidden; AuthIssue? get issue;
/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthViewStateCopyWith<AuthViewState> get copyWith => _$AuthViewStateCopyWithImpl<AuthViewState>(this as AuthViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthViewState&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.email, email) || other.email == email)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.issue, issue) || other.issue == issue));
}


@override
int get hashCode => Object.hash(runtimeType,stage,identity,email,busy,hidden,issue);



}

/// @nodoc
abstract mixin class $AuthViewStateCopyWith<$Res>  {
  factory $AuthViewStateCopyWith(AuthViewState value, $Res Function(AuthViewState) _then) = _$AuthViewStateCopyWithImpl;
@useResult
$Res call({
 AuthStage stage, AuthIdentity? identity, String email, bool busy, bool hidden, AuthIssue? issue
});


$AuthIdentityCopyWith<$Res>? get identity;

}
/// @nodoc
class _$AuthViewStateCopyWithImpl<$Res>
    implements $AuthViewStateCopyWith<$Res> {
  _$AuthViewStateCopyWithImpl(this._self, this._then);

  final AuthViewState _self;
  final $Res Function(AuthViewState) _then;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? identity = freezed,Object? email = null,Object? busy = null,Object? hidden = null,Object? issue = freezed,}) {
  return _then(_self.copyWith(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as AuthStage,identity: freezed == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as AuthIdentity?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as AuthIssue?,
  ));
}
/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthIdentityCopyWith<$Res>? get identity {
    if (_self.identity == null) {
    return null;
  }

  return $AuthIdentityCopyWith<$Res>(_self.identity!, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthViewState].
extension AuthViewStatePatterns on AuthViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthViewState value)  $default,){
final _that = this;
switch (_that) {
case _AuthViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthViewState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthStage stage,  AuthIdentity? identity,  String email,  bool busy,  bool hidden,  AuthIssue? issue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
return $default(_that.stage,_that.identity,_that.email,_that.busy,_that.hidden,_that.issue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthStage stage,  AuthIdentity? identity,  String email,  bool busy,  bool hidden,  AuthIssue? issue)  $default,) {final _that = this;
switch (_that) {
case _AuthViewState():
return $default(_that.stage,_that.identity,_that.email,_that.busy,_that.hidden,_that.issue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthStage stage,  AuthIdentity? identity,  String email,  bool busy,  bool hidden,  AuthIssue? issue)?  $default,) {final _that = this;
switch (_that) {
case _AuthViewState() when $default != null:
return $default(_that.stage,_that.identity,_that.email,_that.busy,_that.hidden,_that.issue);case _:
  return null;

}
}

}

/// @nodoc


class _AuthViewState implements AuthViewState {
  const _AuthViewState({this.stage = AuthStage.restoring, this.identity, this.email = '', this.busy = false, this.hidden = false, this.issue});
  

@override@JsonKey() final  AuthStage stage;
@override final  AuthIdentity? identity;
@override@JsonKey() final  String email;
@override@JsonKey() final  bool busy;
@override@JsonKey() final  bool hidden;
@override final  AuthIssue? issue;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthViewStateCopyWith<_AuthViewState> get copyWith => __$AuthViewStateCopyWithImpl<_AuthViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthViewState&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.email, email) || other.email == email)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.issue, issue) || other.issue == issue));
}


@override
int get hashCode => Object.hash(runtimeType,stage,identity,email,busy,hidden,issue);



}

/// @nodoc
abstract mixin class _$AuthViewStateCopyWith<$Res> implements $AuthViewStateCopyWith<$Res> {
  factory _$AuthViewStateCopyWith(_AuthViewState value, $Res Function(_AuthViewState) _then) = __$AuthViewStateCopyWithImpl;
@override @useResult
$Res call({
 AuthStage stage, AuthIdentity? identity, String email, bool busy, bool hidden, AuthIssue? issue
});


@override $AuthIdentityCopyWith<$Res>? get identity;

}
/// @nodoc
class __$AuthViewStateCopyWithImpl<$Res>
    implements _$AuthViewStateCopyWith<$Res> {
  __$AuthViewStateCopyWithImpl(this._self, this._then);

  final _AuthViewState _self;
  final $Res Function(_AuthViewState) _then;

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? identity = freezed,Object? email = null,Object? busy = null,Object? hidden = null,Object? issue = freezed,}) {
  return _then(_AuthViewState(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as AuthStage,identity: freezed == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as AuthIdentity?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as AuthIssue?,
  ));
}

/// Create a copy of AuthViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthIdentityCopyWith<$Res>? get identity {
    if (_self.identity == null) {
    return null;
  }

  return $AuthIdentityCopyWith<$Res>(_self.identity!, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}

// dart format on
