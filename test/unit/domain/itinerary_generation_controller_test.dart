import 'dart:async';

import 'package:etrip/features/Itinerary/domain/itinerary_generation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_travel_plan_generator.dart';
import '../../support/in_memory_itinerary_repository.dart';
import '../../support/test_data.dart';

void main() {
  late InMemoryItineraryRepository repo;
  setUp(() => repo = InMemoryItineraryRepository());

  test('规则 5：合法且空闲 → 进入加载态并产出结果', () async {
    final gen = FakeTravelPlanGenerator(result: sampleResponse(days: 3));
    final ctrl =
        ItineraryGenerationController(generator: gen, repository: repo);

    final future = ctrl.generate(userId: 'u1', request: validRequest());
    expect(ctrl.isLoading, isTrue, reason: '发起后应立即进入加载态');

    await future;
    expect(ctrl.isLoading, isFalse);
    expect(ctrl.hasError, isFalse);
    expect(ctrl.response, isNotNull);
  });

  test('规则 4：生成中重复调用被拦截（幂等，不会生成两份）', () async {
    final gate = Completer<void>();
    final gen = FakeTravelPlanGenerator(result: sampleResponse(), gate: gate);
    final ctrl =
        ItineraryGenerationController(generator: gen, repository: repo);

    final f1 = ctrl.generate(userId: 'u1', request: validRequest());
    final f2 = ctrl.generate(userId: 'u1', request: validRequest());
    expect(ctrl.isLoading, isTrue);

    gate.complete();
    await Future.wait([f1, f2]);

    expect(gen.callCount, 1, reason: '第二次点击不应再调用生成器');
    expect(ctrl.response, isNotNull);
  });

  test('规则 6：失败后退出加载态，且可重试成功', () async {
    final gen = FakeTravelPlanGenerator(error: Exception('boom'));
    final ctrl =
        ItineraryGenerationController(generator: gen, repository: repo);

    await ctrl.generate(userId: 'u1', request: validRequest());
    expect(ctrl.hasError, isTrue);
    expect(ctrl.response, isNull);
    expect(ctrl.isLoading, isFalse);

    gen.error = null;
    gen.result = sampleResponse();
    await ctrl.generate(userId: 'u1', request: validRequest());

    expect(ctrl.hasError, isFalse);
    expect(ctrl.response, isNotNull);
    expect(gen.callCount, 2);
  });

  test('规则 1~3：请求非法 → 不调用生成器，直接报错', () async {
    final gen = FakeTravelPlanGenerator(result: sampleResponse());
    final ctrl =
        ItineraryGenerationController(generator: gen, repository: repo);

    await ctrl.generate(
      userId: 'u1',
      request: validRequest(tourismTypeWeights: const {}),
    );

    expect(gen.callCount, 0);
    expect(ctrl.hasError, isTrue);
    expect(ctrl.isLoading, isFalse);
  });

  test('成功后写入仓储（持久化）', () async {
    final gen = FakeTravelPlanGenerator(result: sampleResponse(days: 2));
    final ctrl =
        ItineraryGenerationController(generator: gen, repository: repo);

    await ctrl.generate(userId: 'u1', request: validRequest());

    final saved = await repo.loadAll('u1');
    expect(saved.length, 1);
    expect(saved.first.userId, 'u1');
    expect(saved.first.noOfDays, 2);
    expect(saved.first.placeIds, isNotEmpty);
  });
}
