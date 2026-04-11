// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phish_flag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhishFlagAdapter extends TypeAdapter<PhishFlag> {
  @override
  final int typeId = 1;

  @override
  PhishFlag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhishFlag(
      ruleId: fields[0] as String,
      title: fields[1] as String,
      explanation: fields[2] as String,
      weight: fields[4] as int,
      trickType: fields[5] as String,
      urlSegment: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PhishFlag obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.ruleId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.explanation)
      ..writeByte(3)
      ..write(obj.urlSegment)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.trickType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhishFlagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
