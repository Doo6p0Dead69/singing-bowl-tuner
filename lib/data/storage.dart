import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class Storage {
  static const bowlsBox = 'bowls';
  static const setsBox = 'sets';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BowlEntryAdapter());
    Hive.registerAdapter(BowlSetAdapter());
    await Hive.openBox<BowlEntry>(bowlsBox);
    await Hive.openBox<BowlSet>(setsBox);
  }
}
