// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StaffMember {

 String get id; String get userId; String get displayName; String get email; bool get isActive; Set<StaffRole> get roles; DateTime? get deactivatedAt;
/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffMemberCopyWith<StaffMember> get copyWith => _$StaffMemberCopyWithImpl<StaffMember>(this as StaffMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffMember&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.deactivatedAt, deactivatedAt) || other.deactivatedAt == deactivatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,displayName,email,isActive,const DeepCollectionEquality().hash(roles),deactivatedAt);



}

/// @nodoc
abstract mixin class $StaffMemberCopyWith<$Res>  {
  factory $StaffMemberCopyWith(StaffMember value, $Res Function(StaffMember) _then) = _$StaffMemberCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String displayName, String email, bool isActive, Set<StaffRole> roles, DateTime? deactivatedAt
});




}
/// @nodoc
class _$StaffMemberCopyWithImpl<$Res>
    implements $StaffMemberCopyWith<$Res> {
  _$StaffMemberCopyWithImpl(this._self, this._then);

  final StaffMember _self;
  final $Res Function(StaffMember) _then;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? displayName = null,Object? email = null,Object? isActive = null,Object? roles = null,Object? deactivatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<StaffRole>,deactivatedAt: freezed == deactivatedAt ? _self.deactivatedAt : deactivatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffMember].
extension StaffMemberPatterns on StaffMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffMember value)  $default,){
final _that = this;
switch (_that) {
case _StaffMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffMember value)?  $default,){
final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String displayName,  String email,  bool isActive,  Set<StaffRole> roles,  DateTime? deactivatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
return $default(_that.id,_that.userId,_that.displayName,_that.email,_that.isActive,_that.roles,_that.deactivatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String displayName,  String email,  bool isActive,  Set<StaffRole> roles,  DateTime? deactivatedAt)  $default,) {final _that = this;
switch (_that) {
case _StaffMember():
return $default(_that.id,_that.userId,_that.displayName,_that.email,_that.isActive,_that.roles,_that.deactivatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String displayName,  String email,  bool isActive,  Set<StaffRole> roles,  DateTime? deactivatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
return $default(_that.id,_that.userId,_that.displayName,_that.email,_that.isActive,_that.roles,_that.deactivatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _StaffMember implements StaffMember {
  const _StaffMember({required this.id, required this.userId, required this.displayName, required this.email, required this.isActive, required final  Set<StaffRole> roles, this.deactivatedAt}): _roles = roles;
  

@override final  String id;
@override final  String userId;
@override final  String displayName;
@override final  String email;
@override final  bool isActive;
 final  Set<StaffRole> _roles;
@override Set<StaffRole> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override final  DateTime? deactivatedAt;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffMemberCopyWith<_StaffMember> get copyWith => __$StaffMemberCopyWithImpl<_StaffMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffMember&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.deactivatedAt, deactivatedAt) || other.deactivatedAt == deactivatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,displayName,email,isActive,const DeepCollectionEquality().hash(_roles),deactivatedAt);



}

/// @nodoc
abstract mixin class _$StaffMemberCopyWith<$Res> implements $StaffMemberCopyWith<$Res> {
  factory _$StaffMemberCopyWith(_StaffMember value, $Res Function(_StaffMember) _then) = __$StaffMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String displayName, String email, bool isActive, Set<StaffRole> roles, DateTime? deactivatedAt
});




}
/// @nodoc
class __$StaffMemberCopyWithImpl<$Res>
    implements _$StaffMemberCopyWith<$Res> {
  __$StaffMemberCopyWithImpl(this._self, this._then);

  final _StaffMember _self;
  final $Res Function(_StaffMember) _then;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? displayName = null,Object? email = null,Object? isActive = null,Object? roles = null,Object? deactivatedAt = freezed,}) {
  return _then(_StaffMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<StaffRole>,deactivatedAt: freezed == deactivatedAt ? _self.deactivatedAt : deactivatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$StaffInvitation {

 String get id; String get clinicId; String get email; Set<StaffRole> get roles; StaffInvitationStatus get status; DateTime get createdAt; DateTime get expiresAt; DateTime get lastSentAt; int get resendCount; DateTime? get acceptedAt; DateTime? get revokedAt;
/// Create a copy of StaffInvitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffInvitationCopyWith<StaffInvitation> get copyWith => _$StaffInvitationCopyWithImpl<StaffInvitation>(this as StaffInvitation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffInvitation&&(identical(other.id, id) || other.id == id)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastSentAt, lastSentAt) || other.lastSentAt == lastSentAt)&&(identical(other.resendCount, resendCount) || other.resendCount == resendCount)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,clinicId,email,const DeepCollectionEquality().hash(roles),status,createdAt,expiresAt,lastSentAt,resendCount,acceptedAt,revokedAt);



}

/// @nodoc
abstract mixin class $StaffInvitationCopyWith<$Res>  {
  factory $StaffInvitationCopyWith(StaffInvitation value, $Res Function(StaffInvitation) _then) = _$StaffInvitationCopyWithImpl;
@useResult
$Res call({
 String id, String clinicId, String email, Set<StaffRole> roles, StaffInvitationStatus status, DateTime createdAt, DateTime expiresAt, DateTime lastSentAt, int resendCount, DateTime? acceptedAt, DateTime? revokedAt
});




}
/// @nodoc
class _$StaffInvitationCopyWithImpl<$Res>
    implements $StaffInvitationCopyWith<$Res> {
  _$StaffInvitationCopyWithImpl(this._self, this._then);

  final StaffInvitation _self;
  final $Res Function(StaffInvitation) _then;

/// Create a copy of StaffInvitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clinicId = null,Object? email = null,Object? roles = null,Object? status = null,Object? createdAt = null,Object? expiresAt = null,Object? lastSentAt = null,Object? resendCount = null,Object? acceptedAt = freezed,Object? revokedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clinicId: null == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<StaffRole>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffInvitationStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSentAt: null == lastSentAt ? _self.lastSentAt : lastSentAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendCount: null == resendCount ? _self.resendCount : resendCount // ignore: cast_nullable_to_non_nullable
as int,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffInvitation].
extension StaffInvitationPatterns on StaffInvitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffInvitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffInvitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffInvitation value)  $default,){
final _that = this;
switch (_that) {
case _StaffInvitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffInvitation value)?  $default,){
final _that = this;
switch (_that) {
case _StaffInvitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clinicId,  String email,  Set<StaffRole> roles,  StaffInvitationStatus status,  DateTime createdAt,  DateTime expiresAt,  DateTime lastSentAt,  int resendCount,  DateTime? acceptedAt,  DateTime? revokedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffInvitation() when $default != null:
return $default(_that.id,_that.clinicId,_that.email,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.lastSentAt,_that.resendCount,_that.acceptedAt,_that.revokedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clinicId,  String email,  Set<StaffRole> roles,  StaffInvitationStatus status,  DateTime createdAt,  DateTime expiresAt,  DateTime lastSentAt,  int resendCount,  DateTime? acceptedAt,  DateTime? revokedAt)  $default,) {final _that = this;
switch (_that) {
case _StaffInvitation():
return $default(_that.id,_that.clinicId,_that.email,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.lastSentAt,_that.resendCount,_that.acceptedAt,_that.revokedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clinicId,  String email,  Set<StaffRole> roles,  StaffInvitationStatus status,  DateTime createdAt,  DateTime expiresAt,  DateTime lastSentAt,  int resendCount,  DateTime? acceptedAt,  DateTime? revokedAt)?  $default,) {final _that = this;
switch (_that) {
case _StaffInvitation() when $default != null:
return $default(_that.id,_that.clinicId,_that.email,_that.roles,_that.status,_that.createdAt,_that.expiresAt,_that.lastSentAt,_that.resendCount,_that.acceptedAt,_that.revokedAt);case _:
  return null;

}
}

}

/// @nodoc


class _StaffInvitation implements StaffInvitation {
  const _StaffInvitation({required this.id, required this.clinicId, required this.email, required final  Set<StaffRole> roles, required this.status, required this.createdAt, required this.expiresAt, required this.lastSentAt, required this.resendCount, this.acceptedAt, this.revokedAt}): _roles = roles;
  

@override final  String id;
@override final  String clinicId;
@override final  String email;
 final  Set<StaffRole> _roles;
@override Set<StaffRole> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override final  StaffInvitationStatus status;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  DateTime lastSentAt;
@override final  int resendCount;
@override final  DateTime? acceptedAt;
@override final  DateTime? revokedAt;

/// Create a copy of StaffInvitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffInvitationCopyWith<_StaffInvitation> get copyWith => __$StaffInvitationCopyWithImpl<_StaffInvitation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffInvitation&&(identical(other.id, id) || other.id == id)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastSentAt, lastSentAt) || other.lastSentAt == lastSentAt)&&(identical(other.resendCount, resendCount) || other.resendCount == resendCount)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,clinicId,email,const DeepCollectionEquality().hash(_roles),status,createdAt,expiresAt,lastSentAt,resendCount,acceptedAt,revokedAt);



}

/// @nodoc
abstract mixin class _$StaffInvitationCopyWith<$Res> implements $StaffInvitationCopyWith<$Res> {
  factory _$StaffInvitationCopyWith(_StaffInvitation value, $Res Function(_StaffInvitation) _then) = __$StaffInvitationCopyWithImpl;
@override @useResult
$Res call({
 String id, String clinicId, String email, Set<StaffRole> roles, StaffInvitationStatus status, DateTime createdAt, DateTime expiresAt, DateTime lastSentAt, int resendCount, DateTime? acceptedAt, DateTime? revokedAt
});




}
/// @nodoc
class __$StaffInvitationCopyWithImpl<$Res>
    implements _$StaffInvitationCopyWith<$Res> {
  __$StaffInvitationCopyWithImpl(this._self, this._then);

  final _StaffInvitation _self;
  final $Res Function(_StaffInvitation) _then;

/// Create a copy of StaffInvitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clinicId = null,Object? email = null,Object? roles = null,Object? status = null,Object? createdAt = null,Object? expiresAt = null,Object? lastSentAt = null,Object? resendCount = null,Object? acceptedAt = freezed,Object? revokedAt = freezed,}) {
  return _then(_StaffInvitation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clinicId: null == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<StaffRole>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffInvitationStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSentAt: null == lastSentAt ? _self.lastSentAt : lastSentAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendCount: null == resendCount ? _self.resendCount : resendCount // ignore: cast_nullable_to_non_nullable
as int,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$StaffInvitationDelivery {

 String get invitationId; DateTime get expiresAt;
/// Create a copy of StaffInvitationDelivery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffInvitationDeliveryCopyWith<StaffInvitationDelivery> get copyWith => _$StaffInvitationDeliveryCopyWithImpl<StaffInvitationDelivery>(this as StaffInvitationDelivery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffInvitationDelivery&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,invitationId,expiresAt);



}

/// @nodoc
abstract mixin class $StaffInvitationDeliveryCopyWith<$Res>  {
  factory $StaffInvitationDeliveryCopyWith(StaffInvitationDelivery value, $Res Function(StaffInvitationDelivery) _then) = _$StaffInvitationDeliveryCopyWithImpl;
@useResult
$Res call({
 String invitationId, DateTime expiresAt
});




}
/// @nodoc
class _$StaffInvitationDeliveryCopyWithImpl<$Res>
    implements $StaffInvitationDeliveryCopyWith<$Res> {
  _$StaffInvitationDeliveryCopyWithImpl(this._self, this._then);

  final StaffInvitationDelivery _self;
  final $Res Function(StaffInvitationDelivery) _then;

/// Create a copy of StaffInvitationDelivery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invitationId = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffInvitationDelivery].
extension StaffInvitationDeliveryPatterns on StaffInvitationDelivery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffInvitationDelivery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffInvitationDelivery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffInvitationDelivery value)  $default,){
final _that = this;
switch (_that) {
case _StaffInvitationDelivery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffInvitationDelivery value)?  $default,){
final _that = this;
switch (_that) {
case _StaffInvitationDelivery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String invitationId,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffInvitationDelivery() when $default != null:
return $default(_that.invitationId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String invitationId,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _StaffInvitationDelivery():
return $default(_that.invitationId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String invitationId,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _StaffInvitationDelivery() when $default != null:
return $default(_that.invitationId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _StaffInvitationDelivery implements StaffInvitationDelivery {
  const _StaffInvitationDelivery({required this.invitationId, required this.expiresAt});
  

@override final  String invitationId;
@override final  DateTime expiresAt;

/// Create a copy of StaffInvitationDelivery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffInvitationDeliveryCopyWith<_StaffInvitationDelivery> get copyWith => __$StaffInvitationDeliveryCopyWithImpl<_StaffInvitationDelivery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffInvitationDelivery&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,invitationId,expiresAt);



}

/// @nodoc
abstract mixin class _$StaffInvitationDeliveryCopyWith<$Res> implements $StaffInvitationDeliveryCopyWith<$Res> {
  factory _$StaffInvitationDeliveryCopyWith(_StaffInvitationDelivery value, $Res Function(_StaffInvitationDelivery) _then) = __$StaffInvitationDeliveryCopyWithImpl;
@override @useResult
$Res call({
 String invitationId, DateTime expiresAt
});




}
/// @nodoc
class __$StaffInvitationDeliveryCopyWithImpl<$Res>
    implements _$StaffInvitationDeliveryCopyWith<$Res> {
  __$StaffInvitationDeliveryCopyWithImpl(this._self, this._then);

  final _StaffInvitationDelivery _self;
  final $Res Function(_StaffInvitationDelivery) _then;

/// Create a copy of StaffInvitationDelivery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invitationId = null,Object? expiresAt = null,}) {
  return _then(_StaffInvitationDelivery(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
