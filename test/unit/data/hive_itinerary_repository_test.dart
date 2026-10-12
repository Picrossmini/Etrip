import 'dart:io';

import 'package:etrip/features/Itinerary/data/models/saved_itinerary.dart';
import 'package:etrip/features/Itinerary/data/repositories/hive_itinerary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

SavedItinerary saved(String id, String uid,
        {int days = 3, DateTime? created}) =>
    SavedItinerary(
      id: id,
      userId: uid,
      createdAt: created ?? DateTime(2026, 1, 1, 12, 0),
      noOfDays: days,
      city: 'Chengdu',
      budget: 'medium',
      withWho: 'solo',
      tourismTypes: const ['Natural Attractions'],
      placeIds: const ['1', '2'],
    );

void main() {
  late Directory dir;
  late HiveItineraryRepository repo;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('hive_itinerary_test');
    Hive.init(dir.path);
    repo = HiveItineraryRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('空：没有任何记录时返回空列表', () async {
    expect(await repo.loadAll('u1'), isEmpty);
  });

  test('存进去再读出来一致（字段完整）', () async {
    await repo.save(saved('a', 'u1'));
    final list = await repo.loadAll('u1');

    expect(list.length, 1);
    expect(list.first.id, 'a');
    expect(list.first.city, 'Chengdu');
    expect(list.first.placeIds, ['1', '2']);
  });

  test('多条按创建时间倒序（最新在前）', () async {
    await repo.save(saved('old', 'u1', created: DateTime(2026, 1, 1)));
    await repo.save(saved('new', 'u1', created: DateTime(2026, 2, 1)));

    final list = await repo.loadAll('u1');
    expect(list.map((e) => e.id).toList(), ['new', 'old']);
  });

  test('按用户隔离', () async {
    await repo.save(saved('a', 'u1'));
    await repo.save(saved('b', 'u2'));

    expect((await repo.loadAll('u1')).single.id, 'a');
    expect((await repo.loadAll('u2')).single.id, 'b');
  });

  test('删除指定记录', () async {
    await repo.save(saved('a', 'u1'));
    await repo.save(saved('b', 'u1'));
    await repo.delete('u1', 'a');

    expect((await repo.loadAll('u1')).map((e) => e.id).toList(), ['b']);
  });

  test('多次保存累积，且新实例能读到（真实落盘）', () async {
    await repo.save(saved('a', 'u1'));
    await repo.save(saved('b', 'u1'));

    final reopened = HiveItineraryRepository();
    final list = await reopened.loadAll('u1');
    expect(list.length, 2);
  });
}
