// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'predictions.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PredictionsAdapter extends TypeAdapter<Predictions> {
  @override
  final int typeId = 2;

  @override
  Predictions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Predictions(
      nextPeriod: fields[0] as DateTime,
      ovulationDay: fields[1] as DateTime,
      fertileStart: fields[2] as DateTime,
      fertileEnd: fields[3] as DateTime,
      confidenceDays: fields[4] as int? ?? 2,
      predictedCycleLength: fields[5] as double? ?? 28.0,
      trend: fields[6] as String? ?? 'stable',
    );
  }

  @override
  void write(BinaryWriter writer, Predictions obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nextPeriod)
      ..writeByte(1)
      ..write(obj.ovulationDay)
      ..writeByte(2)
      ..write(obj.fertileStart)
      ..writeByte(3)
      ..write(obj.fertileEnd)
      ..writeByte(4)
      ..write(obj.confidenceDays)
      ..writeByte(5)
      ..write(obj.predictedCycleLength)
      ..writeByte(6)
      ..write(obj.trend);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
