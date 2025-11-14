// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 3;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      id: fields[0] as String,
      studentId: fields[1] as String,
      studentName: fields[2] as String,
      teacherId: fields[3] as String,
      classId: fields[4] as String,
      timestamp: fields[5] as DateTime,
      confidence: fields[6] as double?,
      status: fields[7] as String,
      isManual: fields[8] as bool,
      synced: fields[9] as bool,
      notes: fields[10] as String?,
      retryCount: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.studentName)
      ..writeByte(3)
      ..write(obj.teacherId)
      ..writeByte(4)
      ..write(obj.classId)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.confidence)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.isManual)
      ..writeByte(9)
      ..write(obj.synced)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
