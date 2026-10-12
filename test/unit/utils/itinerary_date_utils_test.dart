import 'package:etrip/features/Itinerary/domain/itinerary_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daysBetweenInclusive 天数计算', () {
    test('当天往返 = 1 天', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2026, 3, 10), DateTime(2026, 3, 10)),
        1,
      );
    });

    test('普通相邻两天 = 2 天', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2026, 3, 10), DateTime(2026, 3, 11)),
        2,
      );
    });

    test('跨月：1/31 → 2/2 = 3 天', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2026, 1, 31), DateTime(2026, 2, 2)),
        3,
      );
    });

    test('跨年：12/30 → 次年 1/2 = 4 天', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2025, 12, 30), DateTime(2026, 1, 2)),
        4,
      );
    });

    test('闰年 2/29：2028-02-28 → 03-01 = 3 天', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2028, 2, 28), DateTime(2028, 3, 1)),
        3,
      );
    });

    test('非闰年 2/28 → 3/1 = 2 天（没有 2/29）', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2026, 2, 28), DateTime(2026, 3, 1)),
        2,
      );
    });

    test('忽略时分秒：只按日期算', () {
      expect(
        ItineraryDateUtils.daysBetweenInclusive(
            DateTime(2026, 3, 10, 23, 59), DateTime(2026, 3, 11, 0, 1)),
        2,
      );
    });
  });

  group('isEndNotBeforeStart 区间校验', () {
    test('结束早于开始 → false', () {
      expect(
        ItineraryDateUtils.isEndNotBeforeStart(
            DateTime(2026, 3, 10), DateTime(2026, 3, 9)),
        isFalse,
      );
    });
    test('同一天 → true', () {
      expect(
        ItineraryDateUtils.isEndNotBeforeStart(
            DateTime(2026, 3, 10), DateTime(2026, 3, 10)),
        isTrue,
      );
    });
  });

  test('isLeapYear', () {
    expect(ItineraryDateUtils.isLeapYear(2028), isTrue);
    expect(ItineraryDateUtils.isLeapYear(2026), isFalse);
    expect(ItineraryDateUtils.isLeapYear(2000), isTrue);
    expect(ItineraryDateUtils.isLeapYear(1900), isFalse);
  });
}
