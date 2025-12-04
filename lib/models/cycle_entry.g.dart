// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleEntryAdapter extends TypeAdapter<CycleEntry> {
  @override
  final int typeId = 1;

  @override
  CycleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleEntry(
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime?,
      symptoms: (fields[2] as List).cast<String>(),
      mood: (fields[3] as List).cast<String>(),
      flowLevel: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CycleEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.symptoms)
      ..writeByte(3)
      ..write(obj.mood)
      ..writeByte(4)
      ..write(obj.flowLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
