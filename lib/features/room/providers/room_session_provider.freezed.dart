// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_session_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomSession {

 String get roomId; String get roomName; RoomStatus get status; List<RoomMemberModel> get members; String get getstreamCallId; String? get sessionId; bool get isInCall; bool get isEnded; bool get isHost; bool get isHostDisconnected; int get hostGraceSeconds; List<String> get banners; String? get marqueeText;
/// Create a copy of RoomSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomSessionCopyWith<RoomSession> get copyWith => _$RoomSessionCopyWithImpl<RoomSession>(this as RoomSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomSession&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.getstreamCallId, getstreamCallId) || other.getstreamCallId == getstreamCallId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.isInCall, isInCall) || other.isInCall == isInCall)&&(identical(other.isEnded, isEnded) || other.isEnded == isEnded)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isHostDisconnected, isHostDisconnected) || other.isHostDisconnected == isHostDisconnected)&&(identical(other.hostGraceSeconds, hostGraceSeconds) || other.hostGraceSeconds == hostGraceSeconds)&&const DeepCollectionEquality().equals(other.banners, banners)&&(identical(other.marqueeText, marqueeText) || other.marqueeText == marqueeText));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,status,const DeepCollectionEquality().hash(members),getstreamCallId,sessionId,isInCall,isEnded,isHost,isHostDisconnected,hostGraceSeconds,const DeepCollectionEquality().hash(banners),marqueeText);

@override
String toString() {
  return 'RoomSession(roomId: $roomId, roomName: $roomName, status: $status, members: $members, getstreamCallId: $getstreamCallId, sessionId: $sessionId, isInCall: $isInCall, isEnded: $isEnded, isHost: $isHost, isHostDisconnected: $isHostDisconnected, hostGraceSeconds: $hostGraceSeconds, banners: $banners, marqueeText: $marqueeText)';
}


}

/// @nodoc
abstract mixin class $RoomSessionCopyWith<$Res>  {
  factory $RoomSessionCopyWith(RoomSession value, $Res Function(RoomSession) _then) = _$RoomSessionCopyWithImpl;
@useResult
$Res call({
 String roomId, String roomName, RoomStatus status, List<RoomMemberModel> members, String getstreamCallId, String? sessionId, bool isInCall, bool isEnded, bool isHost, bool isHostDisconnected, int hostGraceSeconds, List<String> banners, String? marqueeText
});




}
/// @nodoc
class _$RoomSessionCopyWithImpl<$Res>
    implements $RoomSessionCopyWith<$Res> {
  _$RoomSessionCopyWithImpl(this._self, this._then);

  final RoomSession _self;
  final $Res Function(RoomSession) _then;

/// Create a copy of RoomSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? roomName = null,Object? status = null,Object? members = null,Object? getstreamCallId = null,Object? sessionId = freezed,Object? isInCall = null,Object? isEnded = null,Object? isHost = null,Object? isHostDisconnected = null,Object? hostGraceSeconds = null,Object? banners = null,Object? marqueeText = freezed,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RoomStatus,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<RoomMemberModel>,getstreamCallId: null == getstreamCallId ? _self.getstreamCallId : getstreamCallId // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,isInCall: null == isInCall ? _self.isInCall : isInCall // ignore: cast_nullable_to_non_nullable
as bool,isEnded: null == isEnded ? _self.isEnded : isEnded // ignore: cast_nullable_to_non_nullable
as bool,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isHostDisconnected: null == isHostDisconnected ? _self.isHostDisconnected : isHostDisconnected // ignore: cast_nullable_to_non_nullable
as bool,hostGraceSeconds: null == hostGraceSeconds ? _self.hostGraceSeconds : hostGraceSeconds // ignore: cast_nullable_to_non_nullable
as int,banners: null == banners ? _self.banners : banners // ignore: cast_nullable_to_non_nullable
as List<String>,marqueeText: freezed == marqueeText ? _self.marqueeText : marqueeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomSession].
extension RoomSessionPatterns on RoomSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomSession value)  $default,){
final _that = this;
switch (_that) {
case _RoomSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomSession value)?  $default,){
final _that = this;
switch (_that) {
case _RoomSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String roomName,  RoomStatus status,  List<RoomMemberModel> members,  String getstreamCallId,  String? sessionId,  bool isInCall,  bool isEnded,  bool isHost,  bool isHostDisconnected,  int hostGraceSeconds,  List<String> banners,  String? marqueeText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomSession() when $default != null:
return $default(_that.roomId,_that.roomName,_that.status,_that.members,_that.getstreamCallId,_that.sessionId,_that.isInCall,_that.isEnded,_that.isHost,_that.isHostDisconnected,_that.hostGraceSeconds,_that.banners,_that.marqueeText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String roomName,  RoomStatus status,  List<RoomMemberModel> members,  String getstreamCallId,  String? sessionId,  bool isInCall,  bool isEnded,  bool isHost,  bool isHostDisconnected,  int hostGraceSeconds,  List<String> banners,  String? marqueeText)  $default,) {final _that = this;
switch (_that) {
case _RoomSession():
return $default(_that.roomId,_that.roomName,_that.status,_that.members,_that.getstreamCallId,_that.sessionId,_that.isInCall,_that.isEnded,_that.isHost,_that.isHostDisconnected,_that.hostGraceSeconds,_that.banners,_that.marqueeText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String roomName,  RoomStatus status,  List<RoomMemberModel> members,  String getstreamCallId,  String? sessionId,  bool isInCall,  bool isEnded,  bool isHost,  bool isHostDisconnected,  int hostGraceSeconds,  List<String> banners,  String? marqueeText)?  $default,) {final _that = this;
switch (_that) {
case _RoomSession() when $default != null:
return $default(_that.roomId,_that.roomName,_that.status,_that.members,_that.getstreamCallId,_that.sessionId,_that.isInCall,_that.isEnded,_that.isHost,_that.isHostDisconnected,_that.hostGraceSeconds,_that.banners,_that.marqueeText);case _:
  return null;

}
}

}

/// @nodoc


class _RoomSession implements RoomSession {
  const _RoomSession({required this.roomId, required this.roomName, required this.status, required final  List<RoomMemberModel> members, required this.getstreamCallId, this.sessionId, this.isInCall = false, this.isEnded = false, this.isHost = false, this.isHostDisconnected = false, this.hostGraceSeconds = 0, final  List<String> banners = const <String>[], this.marqueeText}): _members = members,_banners = banners;
  

@override final  String roomId;
@override final  String roomName;
@override final  RoomStatus status;
 final  List<RoomMemberModel> _members;
@override List<RoomMemberModel> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  String getstreamCallId;
@override final  String? sessionId;
@override@JsonKey() final  bool isInCall;
@override@JsonKey() final  bool isEnded;
@override@JsonKey() final  bool isHost;
@override@JsonKey() final  bool isHostDisconnected;
@override@JsonKey() final  int hostGraceSeconds;
 final  List<String> _banners;
@override@JsonKey() List<String> get banners {
  if (_banners is EqualUnmodifiableListView) return _banners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_banners);
}

@override final  String? marqueeText;

/// Create a copy of RoomSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomSessionCopyWith<_RoomSession> get copyWith => __$RoomSessionCopyWithImpl<_RoomSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomSession&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.getstreamCallId, getstreamCallId) || other.getstreamCallId == getstreamCallId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.isInCall, isInCall) || other.isInCall == isInCall)&&(identical(other.isEnded, isEnded) || other.isEnded == isEnded)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isHostDisconnected, isHostDisconnected) || other.isHostDisconnected == isHostDisconnected)&&(identical(other.hostGraceSeconds, hostGraceSeconds) || other.hostGraceSeconds == hostGraceSeconds)&&const DeepCollectionEquality().equals(other._banners, _banners)&&(identical(other.marqueeText, marqueeText) || other.marqueeText == marqueeText));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,status,const DeepCollectionEquality().hash(_members),getstreamCallId,sessionId,isInCall,isEnded,isHost,isHostDisconnected,hostGraceSeconds,const DeepCollectionEquality().hash(_banners),marqueeText);

@override
String toString() {
  return 'RoomSession(roomId: $roomId, roomName: $roomName, status: $status, members: $members, getstreamCallId: $getstreamCallId, sessionId: $sessionId, isInCall: $isInCall, isEnded: $isEnded, isHost: $isHost, isHostDisconnected: $isHostDisconnected, hostGraceSeconds: $hostGraceSeconds, banners: $banners, marqueeText: $marqueeText)';
}


}

/// @nodoc
abstract mixin class _$RoomSessionCopyWith<$Res> implements $RoomSessionCopyWith<$Res> {
  factory _$RoomSessionCopyWith(_RoomSession value, $Res Function(_RoomSession) _then) = __$RoomSessionCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String roomName, RoomStatus status, List<RoomMemberModel> members, String getstreamCallId, String? sessionId, bool isInCall, bool isEnded, bool isHost, bool isHostDisconnected, int hostGraceSeconds, List<String> banners, String? marqueeText
});




}
/// @nodoc
class __$RoomSessionCopyWithImpl<$Res>
    implements _$RoomSessionCopyWith<$Res> {
  __$RoomSessionCopyWithImpl(this._self, this._then);

  final _RoomSession _self;
  final $Res Function(_RoomSession) _then;

/// Create a copy of RoomSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? roomName = null,Object? status = null,Object? members = null,Object? getstreamCallId = null,Object? sessionId = freezed,Object? isInCall = null,Object? isEnded = null,Object? isHost = null,Object? isHostDisconnected = null,Object? hostGraceSeconds = null,Object? banners = null,Object? marqueeText = freezed,}) {
  return _then(_RoomSession(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RoomStatus,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<RoomMemberModel>,getstreamCallId: null == getstreamCallId ? _self.getstreamCallId : getstreamCallId // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,isInCall: null == isInCall ? _self.isInCall : isInCall // ignore: cast_nullable_to_non_nullable
as bool,isEnded: null == isEnded ? _self.isEnded : isEnded // ignore: cast_nullable_to_non_nullable
as bool,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isHostDisconnected: null == isHostDisconnected ? _self.isHostDisconnected : isHostDisconnected // ignore: cast_nullable_to_non_nullable
as bool,hostGraceSeconds: null == hostGraceSeconds ? _self.hostGraceSeconds : hostGraceSeconds // ignore: cast_nullable_to_non_nullable
as int,banners: null == banners ? _self._banners : banners // ignore: cast_nullable_to_non_nullable
as List<String>,marqueeText: freezed == marqueeText ? _self.marqueeText : marqueeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
