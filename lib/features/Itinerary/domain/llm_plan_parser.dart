import 'dart:convert';

import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/itinerary_plan_schema.dart';
import 'package:etrip/features/Itinerary/domain/plan_hydrator.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

/// 大模型返回内容无法解析成一份合法行程时抛出。
class ItineraryParseException implements Exception {
  final String message;
  const ItineraryParseException(this.message);

  @override
  String toString() => 'ItineraryParseException: $message';
}

/// 把大模型返回的文本解析成结构化 [ItineraryResponse]。
///
/// 纯函数、无 IO —— 因此「正常 / 缺字段 / 类型错误 / 非法 JSON / 空 / 超长」
/// 这些夹具可以被确定性地、毫秒级地测到（超时属于 HTTP 层，见生成器）。
class LlmPlanParser {
  final PlanHydrator _hydrator;

  const LlmPlanParser({PlanHydrator hydrator = const PlanHydrator()})
      : _hydrator = hydrator;

  /// 从 OpenAI 兼容的响应 envelope（choices[0].message.content）中取出助手文本。
  static String extractContent(String responseBody) {
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      throw const ItineraryParseException('响应不是 JSON 对象');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ItineraryParseException('响应缺少 choices');
    }
    final message = (choices.first as Map)['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const ItineraryParseException('模型返回空内容');
    }
    return content;
  }

  ItineraryResponse parse(
    String rawContent, {
    required ItineraryRequest request,
    required List<PlaceModel> catalog,
  }) {
    final content = rawContent.trim();
    if (content.isEmpty) {
      throw const ItineraryParseException('模型返回空响应');
    }

    final jsonText = _extractJsonObject(content);
    if (jsonText == null) {
      throw const ItineraryParseException('未找到合法 JSON');
    }

    Object? data;
    try {
      data = jsonDecode(jsonText);
    } catch (_) {
      throw const ItineraryParseException('JSON 解析失败');
    }
    if (data is! Map<String, dynamic>) {
      throw const ItineraryParseException('顶层不是 JSON 对象');
    }

    final problems =
        ItineraryPlanSchema.validate(data, expectedDays: request.noOfDays);
    if (problems.isNotEmpty) {
      throw ItineraryParseException('结构校验未通过: ${problems.join('; ')}');
    }

    return _hydrate(data, catalog);
  }

  /// 剥离 markdown 代码块标记、跳过自然语言，取出第一个配平的 JSON 对象。
  static String? _extractJsonObject(String text) {
    var t = text;
    final fence =
        RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
    final match = fence.firstMatch(t);
    if (match != null) t = match.group(1)!.trim();

    final start = t.indexOf('{');
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < t.length; i++) {
      final c = t[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == '\\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
      } else {
        if (c == '"') {
          inString = true;
        } else if (c == '{') {
          depth++;
        } else if (c == '}') {
          depth--;
          if (depth == 0) return t.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  /// 把 `days[].place_ids` 交给 [PlanHydrator] 水合成真实的 [PlaceModel]。
  ItineraryResponse _hydrate(Map<String, dynamic> data, List<PlaceModel> catalog) {
    final rawDays = data['days'] as List;
    final dayPlaceIds = [
      for (final entry in rawDays)
        [
          for (final id in (entry as Map)['place_ids'] as List)
            id?.toString() ?? '',
        ],
    ];

    final description =
        data['description'] is String ? (data['description'] as String).trim() : '';

    return _hydrator.hydrate(
      dayPlaceIds: dayPlaceIds,
      description: description,
      catalog: catalog,
    );
  }
}
