// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StaffState {

 StaffStatus get status; String? get clinicId; List<StaffMember> get members; List<StaffInvitation> get invitations; bool get mutating; AppFailure? get failure; StaffOperationIssue? get issue;
/// Create a copy of StaffState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffStateCopyWith<StaffState> get copyWith => _$StaffStateCopyWithImpl<StaffState>(this as StaffState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffState&&(identical(other.status, status) || other.status == status)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.invitations, invitations)&&(identical(other.mutating, mutating) || other.mutating == mutating)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.issue, issue) || other.issue == issue));
}


@override
int get hashCode => Object.hash(runtimeType,status,clinicId,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(invitations),mutating,failure,issue);



}

/// @nodoc
abstract mixin class $StaffStateCopyWith<$Res>  {
  factory $StaffStateCopyWith(StaffState value, $Res Function(StaffState) _then) = _$StaffStateCopyWithImpl;
@useResult
$Res call({
 StaffStatus status, String? clinicId, List<StaffMember> members, List<StaffInvitation> invitations, bool mutating, AppFailure? failure, StaffOperationIssue? issue
});




}
/// @nodoc
class _$StaffStateCopyWithImpl<$Res>
    implements $StaffStateCopyWith<$Res> {
  _$StaffStateCopyWithImpl(this._self, this._then);

  final StaffState _self;
  final $Res Function(StaffState) _then;

/// Create a copy of StaffState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? clinicId = freezed,Object? members = null,Object? invitations = null,Object? mutating = null,Object? failure = freezed,Object? issue = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffStatus,clinicId: freezed == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<StaffMember>,invitations: null == invitations ? _self.invitations : invitations // ignore: cast_nullable_to_non_nullable
as List<StaffInvitation>,mutating: null == mutating ? _self.mutating : mutating // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as StaffOperationIssue?,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffState].
extension StaffStatePatterns on StaffState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffState value)  $default,){
final _that = this;
switch (_that) {
case _StaffState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffState value)?  $default,){
final _that = this;
switch (_that) {
case _StaffState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StaffStatus status,  String? clinicId,  List<StaffMember> members,  List<StaffInvitation> invitations,  bool mutating,  AppFailure? failure,  StaffOperationIssue? issue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffState() when $default != null:
return $default(_that.status,_that.clinicId,_that.members,_that.invitations,_that.mutating,_that.failure,_that.issue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StaffStatus status,  String? clinicId,  List<StaffMember> members,  List<StaffInvitation> invitations,  bool mutating,  AppFailure? failure,  StaffOperationIssue? issue)  $default,) {final _that = this;
switch (_that) {
case _StaffState():
return $default(_that.status,_that.clinicId,_that.members,_that.invitations,_that.mutating,_that.failure,_that.issue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StaffStatus status,  String? clinicId,  List<StaffMember> members,  List<StaffInvitation> invitations,  bool mutating,  AppFailure? failure,  StaffOperationIssue? issue)?  $default,) {final _that = this;
switch (_that) {
case _StaffState() when $default != null:
return $default(_that.status,_that.clinicId,_that.members,_that.invitations,_that.mutating,_that.failure,_that.issue);case _:
  return null;

}
}

}

/// @nodoc


class _StaffState implements StaffState {
  const _StaffState({this.status = StaffStatus.initial, this.clinicId, final  List<StaffMember> members = const <StaffMember>[], final  List<StaffInvitation> invitations = const <StaffInvitation>[], this.mutating = false, this.failure, this.issue}): _members = members,_invitations = invitations;
  

@override@JsonKey() final  StaffStatus status;
@override final  String? clinicId;
 final  List<StaffMember> _members;
@override@JsonKey() List<StaffMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<StaffInvitation> _invitations;
@override@JsonKey() List<StaffInvitation> get invitations {
  if (_invitations is EqualUnmodifiableListView) return _invitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invitations);
}

@override@JsonKey() final  bool mutating;
@override final  AppFailure? failure;
@override final  StaffOperationIssue? issue;

/// Create a copy of StaffState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffStateCopyWith<_StaffState> get copyWith => __$StaffStateCopyWithImpl<_StaffState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffState&&(identical(other.status, status) || other.status == status)&&(identical(other.clinicId, clinicId) || other.clinicId == clinicId)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._invitations, _invitations)&&(identical(other.mutating, mutating) || other.mutating == mutating)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.issue, issue) || other.issue == issue));
}


@override
int get hashCode => Object.hash(runtimeType,status,clinicId,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_invitations),mutating,failure,issue);



}

/// @nodoc
abstract mixin class _$StaffStateCopyWith<$Res> implements $StaffStateCopyWith<$Res> {
  factory _$StaffStateCopyWith(_StaffState value, $Res Function(_StaffState) _then) = __$StaffStateCopyWithImpl;
@override @useResult
$Res call({
 StaffStatus status, String? clinicId, List<StaffMember> members, List<StaffInvitation> invitations, bool mutating, AppFailure? failure, StaffOperationIssue? issue
});




}
/// @nodoc
class __$StaffStateCopyWithImpl<$Res>
    implements _$StaffStateCopyWith<$Res> {
  __$StaffStateCopyWithImpl(this._self, this._then);

  final _StaffState _self;
  final $Res Function(_StaffState) _then;

/// Create a copy of StaffState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? clinicId = freezed,Object? members = null,Object? invitations = null,Object? mutating = null,Object? failure = freezed,Object? issue = freezed,}) {
  return _then(_StaffState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffStatus,clinicId: freezed == clinicId ? _self.clinicId : clinicId // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<StaffMember>,invitations: null == invitations ? _self._invitations : invitations // ignore: cast_nullable_to_non_nullable
as List<StaffInvitation>,mutating: null == mutating ? _self.mutating : mutating // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,issue: freezed == issue ? _self.issue : issue // ignore: cast_nullable_to_non_nullable
as StaffOperationIssue?,
  ));
}


}

// dart format on
