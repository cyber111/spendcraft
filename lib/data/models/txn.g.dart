// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'txn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxnAdapter extends TypeAdapter<Txn> {
  @override
  final int typeId = 0;

  @override
  Txn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Txn(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      categoryId: fields[3] as String,
      note: fields[4] as String?,
      date: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      synced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Txn obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxnAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
