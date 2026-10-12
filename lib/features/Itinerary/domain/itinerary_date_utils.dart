/// 纯日期逻辑：旅行天数计算与日期区间校验。
///
/// 这一层不依赖 Flutter / 网络 / 存储，因此可以毫秒级、确定性地做单元测试。
/// 日期是典型的边界密集区（同日、跨月、跨年、闰日），也是方案 3.2 的重点。
class ItineraryDateUtils {
  const ItineraryDateUtils._();

  /// 只保留年月日，避免时分秒影响天数差。
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 含首含尾的天数：当天往返 = 1 天。
  ///
  /// 例如 1/31 → 2/2 返回 3；跨月、跨年都按真实日历计算。
  /// 若 end 早于 start，返回 <=0（调用方应先做区间校验）。
  static int daysBetweenInclusive(DateTime start, DateTime end) {
    final s = dateOnly(start);
    final e = dateOnly(end);
    return e.difference(s).inDays + 1;
  }

  /// 结束日期不早于开始日期（允许同一天）。
  static bool isEndNotBeforeStart(DateTime start, DateTime end) =>
      !dateOnly(end).isBefore(dateOnly(start));

  /// 是否闰年。
  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}
