// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassModelAdapter extends TypeAdapter<ClassModel> {
  @override
  final int typeId = 3;

  @override
  ClassModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassModel(
      id: fields[0] as String,
      name: fields[1] as String,
      gradeLevel: fields[2] as String?,
      subject: fields[3] as String?,
      room: fields[4] as String?,
      teacherId: fields[5] as String,
      academicYear: fields[6] as String?,
      studentIds: (fields[7] as List?)?.cast<String>(),
      schedule: (fields[8] as List?)?.cast<ClassSchedule>(),
      color: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      isActive: fields[12] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, ClassModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.gradeLevel)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.room)
      ..writeByte(5)
      ..write(obj.teacherId)
      ..writeByte(6)
      ..write(obj.academicYear)
      ..writeByte(7)
      ..write(obj.studentIds)
      ..writeByte(8)
      ..write(obj.schedule)
      ..writeByte(9)
      ..write(obj.color)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClassScheduleAdapter extends TypeAdapter<ClassSchedule> {
  @override
  final int typeId = 4;

  @override
  ClassSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSchedule(
      dayOfWeek: fields[0] as int,
      startTime: fields[1] as String,
      endTime: fields[2] as String,
      period: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassSchedule obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.period);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
