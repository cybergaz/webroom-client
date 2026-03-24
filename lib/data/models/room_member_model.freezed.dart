// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomMemberModel {

@JsonKey(name: 'id') String get userId; String get name; String get role; bool get isMuted;@JsonKey(name: 'addedAt') DateTime? get joinedAt; String? get phone; String? get email;
/// Create a copy of RoomMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomMemberModelCopyWith<RoomMemberModel> get copyWith => _$RoomMemberModelCopyWithImpl<RoomMemberModel>(this as RoomMemberModel, _$identity);

  /// Serializes this RoomMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,role,isMuted,joinedAt,phone,email);

@override
String toString() {
  return 'RoomMemberModel(userId: $userId, name: $name, role: $role, isMuted: $isMuted, joinedAt: $joinedAt, phone: $phone, email: $email)';
}


}

/// @nodoc
abstract mixin class $RoomMemberModelCopyWith<$Res>  {
  factory $RoomMemberModelCopyWith(RoomMemberModel value, $Res Function(RoomMemberModel) _then) = _$RoomMemberModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String userId, String name, String role, bool isMuted,@JsonKey(name: 'addedAt') DateTime? joinedAt, String? phone, String? email
});




}
/// @nodoc
class _$RoomMemberModelCopyWithImpl<$Res>
    implements $RoomMemberModelCopyWith<$Res> {
  _$RoomMemberModelCopyWithImpl(this._self, this._then);

  final RoomMemberModel _self;
  final $Res Function(RoomMemberModel) _then;

/// Create a copy of RoomMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? role = null,Object? isMuted = null,Object? joinedAt = freezed,Object? phone = freezed,Object? email = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomMemberModel].
extension RoomMemberModelPatterns on RoomMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _RoomMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _RoomMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String userId,  String name,  String role,  bool isMuted, @JsonKey(name: 'addedAt')  DateTime? joinedAt,  String? phone,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomMemberModel() when $default != null:
return $default(_that.userId,_that.name,_that.role,_that.isMuted,_that.joinedAt,_that.phone,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String userId,  String name,  String role,  bool isMuted, @JsonKey(name: 'addedAt')  DateTime? joinedAt,  String? phone,  String? email)  $default,) {final _that = this;
switch (_that) {
case _RoomMemberModel():
return $default(_that.userId,_that.name,_that.role,_that.isMuted,_that.joinedAt,_that.phone,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String userId,  String name,  String role,  bool isMuted, @JsonKey(name: 'addedAt')  DateTime? joinedAt,  String? phone,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _RoomMemberModel() when $default != null:
return $default(_that.userId,_that.name,_that.role,_that.isMuted,_that.joinedAt,_that.phone,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomMemberModel implements RoomMemberModel {
  const _RoomMemberModel({@JsonKey(name: 'id') required this.userId, required this.name, required this.role, this.isMuted = false, @JsonKey(name: 'addedAt') this.joinedAt, this.phone, this.email});
  factory _RoomMemberModel.fromJson(Map<String, dynamic> json) => _$RoomMemberModelFromJson(json);

@override@JsonKey(name: 'id') final  String userId;
@override final  String name;
@override final  String role;
@override@JsonKey() final  bool isMuted;
@override@JsonKey(name: 'addedAt') final  DateTime? joinedAt;
@override final  String? phone;
@override final  String? email;

/// Create a copy of RoomMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomMemberModelCopyWith<_RoomMemberModel> get copyWith => __$RoomMemberModelCopyWithImpl<_RoomMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomMemberModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,role,isMuted,joinedAt,phone,email);

@override
String toString() {
  return 'RoomMemberModel(userId: $userId, name: $name, role: $role, isMuted: $isMuted, joinedAt: $joinedAt, phone: $phone, email: $email)';
}


}

/// @nodoc
abstract mixin class _$RoomMemberModelCopyWith<$Res> implements $RoomMemberModelCopyWith<$Res> {
  factory _$RoomMemberModelCopyWith(_RoomMemberModel value, $Res Function(_RoomMemberModel) _then) = __$RoomMemberModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String userId, String name, String role, bool isMuted,@JsonKey(name: 'addedAt') DateTime? joinedAt, String? phone, String? email
});




}
/// @nodoc
class __$RoomMemberModelCopyWithImpl<$Res>
    implements _$RoomMemberModelCopyWith<$Res> {
  __$RoomMemberModelCopyWithImpl(this._self, this._then);

  final _RoomMemberModel _self;
  final $Res Function(_RoomMemberModel) _then;

/// Create a copy of RoomMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? role = null,Object? isMuted = null,Object? joinedAt = freezed,Object? phone = freezed,Object? email = freezed,}) {
  return _then(_RoomMemberModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
