// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ptt_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PttState {

 bool get isTransmitting; double get audioLevel;
/// Create a copy of PttState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PttStateCopyWith<PttState> get copyWith => _$PttStateCopyWithImpl<PttState>(this as PttState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PttState&&(identical(other.isTransmitting, isTransmitting) || other.isTransmitting == isTransmitting)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel));
}


@override
int get hashCode => Object.hash(runtimeType,isTransmitting,audioLevel);

@override
String toString() {
  return 'PttState(isTransmitting: $isTransmitting, audioLevel: $audioLevel)';
}


}

/// @nodoc
abstract mixin class $PttStateCopyWith<$Res>  {
  factory $PttStateCopyWith(PttState value, $Res Function(PttState) _then) = _$PttStateCopyWithImpl;
@useResult
$Res call({
 bool isTransmitting, double audioLevel
});




}
/// @nodoc
class _$PttStateCopyWithImpl<$Res>
    implements $PttStateCopyWith<$Res> {
  _$PttStateCopyWithImpl(this._self, this._then);

  final PttState _self;
  final $Res Function(PttState) _then;

/// Create a copy of PttState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isTransmitting = null,Object? audioLevel = null,}) {
  return _then(_self.copyWith(
isTransmitting: null == isTransmitting ? _self.isTransmitting : isTransmitting // ignore: cast_nullable_to_non_nullable
as bool,audioLevel: null == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PttState].
extension PttStatePatterns on PttState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PttState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PttState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PttState value)  $default,){
final _that = this;
switch (_that) {
case _PttState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PttState value)?  $default,){
final _that = this;
switch (_that) {
case _PttState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isTransmitting,  double audioLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PttState() when $default != null:
return $default(_that.isTransmitting,_that.audioLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isTransmitting,  double audioLevel)  $default,) {final _that = this;
switch (_that) {
case _PttState():
return $default(_that.isTransmitting,_that.audioLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isTransmitting,  double audioLevel)?  $default,) {final _that = this;
switch (_that) {
case _PttState() when $default != null:
return $default(_that.isTransmitting,_that.audioLevel);case _:
  return null;

}
}

}

/// @nodoc


class _PttState implements PttState {
  const _PttState({this.isTransmitting = false, this.audioLevel = 0.0});
  

@override@JsonKey() final  bool isTransmitting;
@override@JsonKey() final  double audioLevel;

/// Create a copy of PttState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PttStateCopyWith<_PttState> get copyWith => __$PttStateCopyWithImpl<_PttState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PttState&&(identical(other.isTransmitting, isTransmitting) || other.isTransmitting == isTransmitting)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel));
}


@override
int get hashCode => Object.hash(runtimeType,isTransmitting,audioLevel);

@override
String toString() {
  return 'PttState(isTransmitting: $isTransmitting, audioLevel: $audioLevel)';
}


}

/// @nodoc
abstract mixin class _$PttStateCopyWith<$Res> implements $PttStateCopyWith<$Res> {
  factory _$PttStateCopyWith(_PttState value, $Res Function(_PttState) _then) = __$PttStateCopyWithImpl;
@override @useResult
$Res call({
 bool isTransmitting, double audioLevel
});




}
/// @nodoc
class __$PttStateCopyWithImpl<$Res>
    implements _$PttStateCopyWith<$Res> {
  __$PttStateCopyWithImpl(this._self, this._then);

  final _PttState _self;
  final $Res Function(_PttState) _then;

/// Create a copy of PttState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTransmitting = null,Object? audioLevel = null,}) {
  return _then(_PttState(
isTransmitting: null == isTransmitting ? _self.isTransmitting : isTransmitting // ignore: cast_nullable_to_non_nullable
as bool,audioLevel: null == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
