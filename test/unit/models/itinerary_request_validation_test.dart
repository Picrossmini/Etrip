import 'package:flutter_test/flutter_test.dart';

import '../../support/test_data.dart';

void main() {
  test('合法请求：校验通过', () {
    expect(validRequest().validate(), isEmpty);
  });

  group('等价类 - 无效输入', () {
    test('一个偏好都不选 → 报错', () {
      expect(validRequest(tourismTypeWeights: const {}).validate(),
          contains('请至少选择一项旅行偏好'));
    });

    test('城市为空 → 报错', () {
      expect(validRequest(city: '').validate(), contains('请选择目的地城市'));
    });

    test('预算取值非法 → 报错', () {
      expect(validRequest(budget: 'ultra').validate(),
          contains('预算取值非法: ultra'));
    });
  });

  group('边界值 - 旅行天数（0 / 1 / 2 / 30 / 31）', () {
    test('0 天非法', () {
      expect(validRequest(noOfDays: 0).validate(), contains('旅行天数至少为 1 天'));
    });
    test('1 天是最小合法值', () {
      expect(validRequest(noOfDays: 1).validate(), isEmpty);
    });
    test('2 天合法', () {
      expect(validRequest(noOfDays: 2).validate(), isEmpty);
    });
    test('30 天是上限', () {
      expect(validRequest(noOfDays: 30).validate(), isEmpty);
    });
    test('31 天超限', () {
      expect(validRequest(noOfDays: 31).validate(),
          contains('旅行天数不能超过 30 天'));
    });
  });

  group('边界值 - 出行人数（0 / 1 / 上限 / 上限+1）', () {
    test('0 人非法', () {
      expect(validRequest(noOfPeople: 0).validate(), contains('出行人数至少为 1 人'));
    });
    test('1 人合法', () {
      expect(validRequest(noOfPeople: 1).validate(), isEmpty);
    });
    test('上限 20 合法', () {
      expect(validRequest(noOfPeople: 20).validate(), isEmpty);
    });
    test('21 人超限', () {
      expect(validRequest(noOfPeople: 21).validate(),
          contains('出行人数不能超过 20 人'));
    });
  });

  group('边界值 - 日期区间', () {
    test('结束日期早于开始日期 → 报错', () {
      final req = validRequest(
        noOfDays: 3,
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 8),
      );
      expect(req.validate(), contains('结束日期不能早于开始日期'));
    });

    test('起始 = 结束（当天往返）合法', () {
      final req = validRequest(
        noOfDays: 1,
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 10),
      );
      expect(req.validate(), isEmpty);
    });

    test('日期区间与天数不一致 → 报错', () {
      final req = validRequest(
        noOfDays: 5,
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 12),
      );
      expect(req.validate(), contains(startsWith('日期区间共 3 天')));
    });
  });
}
