import 'package:hive/hive.dart';
import 'models.dart';
import 'storage.dart';

class Repository {
  Box<BowlEntry> get _bowls => Hive.box<BowlEntry>(Storage.bowlsBox);
  Box<BowlSet> get _sets => Hive.box<BowlSet>(Storage.setsBox);

  Iterable<BowlEntry> getAllBowls() => _bowls.values;
  Future<int> addBowl(BowlEntry b) => _bowls.add(b);
  Future<void> deleteBowl(BowlEntry b) => b.delete();

  Iterable<BowlSet> getAllSets() => _sets.values;
  Future<int> addSet(BowlSet s) => _sets.add(s);
  Future<void> deleteSet(BowlSet s) => s.delete();
}
