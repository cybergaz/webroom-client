// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionRecord {

 String get id; String get roomId; DateTime get startedAt; DateTime? get endedAt; List<SessionParticipant> get participants;
/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRecordCopyWith<SessionRecord> get copyWith => _$SessionRecordCopyWithImpl<SessionRecord>(this as SessionRecord, _$identity);

  /// Serializes this SessionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.participants, participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,startedAt,endedAt,const DeepCollectionEquality().hash(participants));

@override
String toString() {
  return 'SessionRecord(id: $id, roomId: $roomId, startedAt: $startedAt, endedAt: $endedAt, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $SessionRecordCopyWith<$Res>  {
  factory $SessionRecordCopyWith(SessionRecord value, $Res Function(SessionRecord) _then) = _$SessionRecordCopyWithImpl;
@useResult
$Res call({
 String id, String roomId, DateTime startedAt, DateTime? endedAt, List<SessionParticipant> participants
});




}
/// @nodoc
class _$SessionRecordCopyWithImpl<$Res>
    implements $SessionRecordCopyWith<$Res> {
  _$SessionRecordCopyWithImpl(this._self, this._then);

  final SessionRecord _self;
  final $Res Function(SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? startedAt = null,Object? endedAt = freezed,Object? participants = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<SessionParticipant>,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionRecord].
extension SessionRecordPatterns on SessionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRecord value)  $default,){
final _that = this;
switch (_that) {
case _SessionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomId,  DateTime startedAt,  DateTime? endedAt,  List<SessionParticipant> participants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.id,_that.roomId,_that.startedAt,_that.endedAt,_that.participants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomId,  DateTime startedAt,  DateTime? endedAt,  List<SessionParticipant> participants)  $default,) {final _that = this;
switch (_that) {
case _SessionRecord():
return $default(_that.id,_that.roomId,_that.startedAt,_that.endedAt,_that.participants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomId,  DateTime startedAt,  DateTime? endedAt,  List<SessionParticipant> participants)?  $default,) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.id,_that.roomId,_that.startedAt,_that.endedAt,_that.participants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionRecord implements SessionRecord {
  const _SessionRecord({required this.id, required this.roomId, required this.startedAt, this.endedAt, final  List<SessionParticipant> participants = const []}): _participants = participants;
  factory _SessionRecord.fromJson(Map<String, dynamic> json) => _$SessionRecordFromJson(json);

@override final  String id;
@override final  String roomId;
@override final  DateTime startedAt;
@override final  DateTime? endedAt;
 final  List<SessionParticipant> _participants;
@override@JsonKey() List<SessionParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRecordCopyWith<_SessionRecord> get copyWith => __$SessionRecordCopyWithImpl<_SessionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other._participants, _participants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,startedAt,endedAt,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'SessionRecord(id: $id, roomId: $roomId, startedAt: $startedAt, endedAt: $endedAt, participants: $participants)';
}


}

/// @nodoc
abstract mixin class _$SessionRecordCopyWith<$Res> implements $SessionRecordCopyWith<$Res> {
  factory _$SessionRecordCopyWith(_SessionRecord value, $Res Function(_SessionRecord) _then) = __$SessionRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomId, DateTime startedAt, DateTime? endedAt, List<SessionParticipant> participants
});




}
/// @nodoc
class __$SessionRecordCopyWithImpl<$Res>
    implements _$SessionRecordCopyWith<$Res> {
  __$SessionRecordCopyWithImpl(this._self, this._then);

  final _SessionRecord _self;
  final $Res Function(_SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? startedAt = null,Object? endedAt = freezed,Object? participants = null,}) {
  return _then(_SessionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<SessionParticipant>,
  ));
}


}


/// @nodoc
mixin _$SessionParticipant {

 String get id; String get sessionId; String get userId; DateTime get joinedAt; DateTime? get leftAt;@JsonKey(name: 'user') SessionParticipantUser? get userInfo;
/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionParticipantCopyWith<SessionParticipant> get copyWith => _$SessionParticipantCopyWithImpl<SessionParticipant>(this as SessionParticipant, _$identity);

  /// Serializes this SessionParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,joinedAt,leftAt,userInfo);

@override
String toString() {
  return 'SessionParticipant(id: $id, sessionId: $sessionId, userId: $userId, joinedAt: $joinedAt, leftAt: $leftAt, userInfo: $userInfo)';
}


}

/// @nodoc
abstract mixin class $SessionParticipantCopyWith<$Res>  {
  factory $SessionParticipantCopyWith(SessionParticipant value, $Res Function(SessionParticipant) _then) = _$SessionParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String userId, DateTime joinedAt, DateTime? leftAt,@JsonKey(name: 'user') SessionParticipantUser? userInfo
});


$SessionParticipantUserCopyWith<$Res>? get userInfo;

}
/// @nodoc
class _$SessionParticipantCopyWithImpl<$Res>
    implements $SessionParticipantCopyWith<$Res> {
  _$SessionParticipantCopyWithImpl(this._self, this._then);

  final SessionParticipant _self;
  final $Res Function(SessionParticipant) _then;

/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? joinedAt = null,Object? leftAt = freezed,Object? userInfo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as SessionParticipantUser?,
  ));
}
/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionParticipantUserCopyWith<$Res>? get userInfo {
    if (_self.userInfo == null) {
    return null;
  }

  return $SessionParticipantUserCopyWith<$Res>(_self.userInfo!, (value) {
    return _then(_self.copyWith(userInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionParticipant].
extension SessionParticipantPatterns on SessionParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionParticipant value)  $default,){
final _that = this;
switch (_that) {
case _SessionParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _SessionParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  DateTime joinedAt,  DateTime? leftAt, @JsonKey(name: 'user')  SessionParticipantUser? userInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionParticipant() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.joinedAt,_that.leftAt,_that.userInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  DateTime joinedAt,  DateTime? leftAt, @JsonKey(name: 'user')  SessionParticipantUser? userInfo)  $default,) {final _that = this;
switch (_that) {
case _SessionParticipant():
return $default(_that.id,_that.sessionId,_that.userId,_that.joinedAt,_that.leftAt,_that.userInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String userId,  DateTime joinedAt,  DateTime? leftAt, @JsonKey(name: 'user')  SessionParticipantUser? userInfo)?  $default,) {final _that = this;
switch (_that) {
case _SessionParticipant() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.joinedAt,_that.leftAt,_that.userInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionParticipant implements SessionParticipant {
  const _SessionParticipant({required this.id, required this.sessionId, required this.userId, required this.joinedAt, this.leftAt, @JsonKey(name: 'user') this.userInfo});
  factory _SessionParticipant.fromJson(Map<String, dynamic> json) => _$SessionParticipantFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String userId;
@override final  DateTime joinedAt;
@override final  DateTime? leftAt;
@override@JsonKey(name: 'user') final  SessionParticipantUser? userInfo;

/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionParticipantCopyWith<_SessionParticipant> get copyWith => __$SessionParticipantCopyWithImpl<_SessionParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.leftAt, leftAt) || other.leftAt == leftAt)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,joinedAt,leftAt,userInfo);

@override
String toString() {
  return 'SessionParticipant(id: $id, sessionId: $sessionId, userId: $userId, joinedAt: $joinedAt, leftAt: $leftAt, userInfo: $userInfo)';
}


}

/// @nodoc
abstract mixin class _$SessionParticipantCopyWith<$Res> implements $SessionParticipantCopyWith<$Res> {
  factory _$SessionParticipantCopyWith(_SessionParticipant value, $Res Function(_SessionParticipant) _then) = __$SessionParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String userId, DateTime joinedAt, DateTime? leftAt,@JsonKey(name: 'user') SessionParticipantUser? userInfo
});


@override $SessionParticipantUserCopyWith<$Res>? get userInfo;

}
/// @nodoc
class __$SessionParticipantCopyWithImpl<$Res>
    implements _$SessionParticipantCopyWith<$Res> {
  __$SessionParticipantCopyWithImpl(this._self, this._then);

  final _SessionParticipant _self;
  final $Res Function(_SessionParticipant) _then;

/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? joinedAt = null,Object? leftAt = freezed,Object? userInfo = freezed,}) {
  return _then(_SessionParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,leftAt: freezed == leftAt ? _self.leftAt : leftAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as SessionParticipantUser?,
  ));
}

/// Create a copy of SessionParticipant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionParticipantUserCopyWith<$Res>? get userInfo {
    if (_self.userInfo == null) {
    return null;
  }

  return $SessionParticipantUserCopyWith<$Res>(_self.userInfo!, (value) {
    return _then(_self.copyWith(userInfo: value));
  });
}
}


/// @nodoc
mixin _$SessionParticipantUser {

 String get id; String get name; String? get phone; String? get email;
/// Create a copy of SessionParticipantUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionParticipantUserCopyWith<SessionParticipantUser> get copyWith => _$SessionParticipantUserCopyWithImpl<SessionParticipantUser>(this as SessionParticipantUser, _$identity);

  /// Serializes this SessionParticipantUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionParticipantUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email);

@override
String toString() {
  return 'SessionParticipantUser(id: $id, name: $name, phone: $phone, email: $email)';
}


}

/// @nodoc
abstract mixin class $SessionParticipantUserCopyWith<$Res>  {
  factory $SessionParticipantUserCopyWith(SessionParticipantUser value, $Res Function(SessionParticipantUser) _then) = _$SessionParticipantUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? phone, String? email
});




}
/// @nodoc
class _$SessionParticipantUserCopyWithImpl<$Res>
    implements $SessionParticipantUserCopyWith<$Res> {
  _$SessionParticipantUserCopyWithImpl(this._self, this._then);

  final SessionParticipantUser _self;
  final $Res Function(SessionParticipantUser) _then;

/// Create a copy of SessionParticipantUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? email = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionParticipantUser].
extension SessionParticipantUserPatterns on SessionParticipantUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionParticipantUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionParticipantUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionParticipantUser value)  $default,){
final _that = this;
switch (_that) {
case _SessionParticipantUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionParticipantUser value)?  $default,){
final _that = this;
switch (_that) {
case _SessionParticipantUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionParticipantUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  String? email)  $default,) {final _that = this;
switch (_that) {
case _SessionParticipantUser():
return $default(_that.id,_that.name,_that.phone,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? phone,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _SessionParticipantUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionParticipantUser implements SessionParticipantUser {
  const _SessionParticipantUser({required this.id, required this.name, this.phone, this.email});
  factory _SessionParticipantUser.fromJson(Map<String, dynamic> json) => _$SessionParticipantUserFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? phone;
@override final  String? email;

/// Create a copy of SessionParticipantUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionParticipantUserCopyWith<_SessionParticipantUser> get copyWith => __$SessionParticipantUserCopyWithImpl<_SessionParticipantUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionParticipantUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionParticipantUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email);

@override
String toString() {
  return 'SessionParticipantUser(id: $id, name: $name, phone: $phone, email: $email)';
}


}

/// @nodoc
abstract mixin class _$SessionParticipantUserCopyWith<$Res> implements $SessionParticipantUserCopyWith<$Res> {
  factory _$SessionParticipantUserCopyWith(_SessionParticipantUser value, $Res Function(_SessionParticipantUser) _then) = __$SessionParticipantUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? phone, String? email
});




}
/// @nodoc
class __$SessionParticipantUserCopyWithImpl<$Res>
    implements _$SessionParticipantUserCopyWith<$Res> {
  __$SessionParticipantUserCopyWithImpl(this._self, this._then);

  final _SessionParticipantUser _self;
  final $Res Function(_SessionParticipantUser) _then;

/// Create a copy of SessionParticipantUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? email = freezed,}) {
  return _then(_SessionParticipantUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
