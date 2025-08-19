import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 1)
class BowlEntry extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) double frequencyHz;
  @HiveField(2) String note; // e.g., A#3
  @HiveField(3) int cents; // signed
  @HiveField(4) DateTime createdAt;
  @HiveField(5) String memo;

  BowlEntry({
    required this.name,
    required this.frequencyHz,
    required this.note,
    required this.cents,
    required this.createdAt,
    required this.memo,
  });
}

@HiveType(typeId: 2)
class BowlSet extends HiveObject {
  @HiveField(0) String title;
  @HiveField(1) List<int> bowlIds; // Hive keys of BowlEntry
  @HiveField(2) DateTime createdAt;

  BowlSet({required this.title, required this.bowlIds, required this.createdAt});
}
