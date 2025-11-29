//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ride_create.g.dart';

/// RideCreate
///
/// Properties:
/// * [passenger] 
@BuiltValue()
abstract class RideCreate implements Built<RideCreate, RideCreateBuilder> {
  @BuiltValueField(wireName: r'passenger')
  String get passenger;

  RideCreate._();

  factory RideCreate([void updates(RideCreateBuilder b)]) = _$RideCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RideCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RideCreate> get serializer => _$RideCreateSerializer();
}

class _$RideCreateSerializer implements PrimitiveSerializer<RideCreate> {
  @override
  final Iterable<Type> types = const [RideCreate, _$RideCreate];

  @override
  final String wireName = r'RideCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RideCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'passenger';
    yield serializers.serialize(
      object.passenger,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RideCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RideCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'passenger':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.passenger = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RideCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RideCreateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

