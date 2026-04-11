// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 0;

  @override
  ScanResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResult(
      url: fields[0] as String,
      verdictString: fields[1] as String,
      riskScore: fields[2] as int,
      flags: (fields[3] as List).cast<PhishFlag>(),
      timestamp: fields[4] as DateTime,
      confirmedByApi: fields[5] as bool,
      apiThreatType: fields[6] as String?,
      firestoreId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.verdictString)
      ..writeByte(2)
      ..write(obj.riskScore)
      ..writeByte(3)
      ..write(obj.flags)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.confirmedByApi)
      ..writeByte(6)
      ..write(obj.apiThreatType)
      ..writeByte(7)
      ..write(obj.firestoreId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
