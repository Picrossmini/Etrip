import 'dart:async';
import 'dart:convert';

import 'package:etrip/core/config.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/llm_plan_parser.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/places/data/models/place_model.dart';
import 'package:http/http.dart' as http;

/// 真实实现：调用 DeepSeek 生成结构化行程。
///
/// 关键点（方案 4.3 / 4.4）：
/// - [client]、[apiKey]、[baseUrl]、[catalog] 都可注入 —— 测试时塞入
///   MockClient / 假目录，就能确定性地覆盖正常、超时、非 200、脏 JSON 等路径；
/// - 返回值一律先过 [LlmPlanParser] 做结构校验，绝不假设模型一定返回合法 JSON；
/// - 所有可预期失败都收敛成 [ItineraryGenerationException]，页面只需处理一种错误。
class LlmTravelPlanGenerator implements TravelPlanGenerator {
  static const String _model = 'deepseek-chat';

  final http.Client client;
  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  final List<PlaceModel> catalog;
  final LlmPlanParser parser;

  LlmTravelPlanGenerator({
    http.Client? client,
    String? apiKey,
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
    List<PlaceModel>? catalog,
    this.parser = const LlmPlanParser(),
  })  : client = client ?? http.Client(),
        apiKey = apiKey ?? AppConfig.deepseekApiKey,
        baseUrl = baseUrl ?? AppConfig.deepseekBaseUrl,
        catalog = catalog ?? mockPlaces;

  @override
  Future<ItineraryResponse> generate({
    required String userId,
    required ItineraryRequest request,
  }) async {
    final endpoint = Uri.parse('$baseUrl/chat/completions');

    http.Response response;
    try {
      response = await client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(_buildBody(request)),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw ItineraryGenerationException('生成超时，请稍后重试', cause: e);
    } on http.ClientException catch (e) {
      throw ItineraryGenerationException('网络连接失败，请检查网络后重试', cause: e);
    } catch (e) {
      throw ItineraryGenerationException('生成失败：$e', cause: e);
    }

    if (response.statusCode != 200) {
      throw ItineraryGenerationException('服务暂时不可用（HTTP ${response.statusCode}）');
    }

    try {
      final content = LlmPlanParser.extractContent(response.body);
      return parser.parse(content, request: request, catalog: catalog);
    } on ItineraryParseException catch (e) {
      throw ItineraryGenerationException(e.message, cause: e);
    }
  }

  Map<String, dynamic> _buildBody(ItineraryRequest request) => {
        'model': _model,
        'response_format': {'type': 'json_object'},
        'temperature': 0.7,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': _userPrompt(request)},
        ],
      };

  static const String _systemPrompt =
      'You are a travel planner for a China travel app. '
      'Choose places ONLY from the provided catalog, using their exact place_id. '
      'Return STRICT JSON (no markdown, no extra text) shaped exactly like: '
      '{"description": string, "days": [{"day": 1, "place_ids": ["1", "20"]}]}. '
      'The number of day objects must equal the requested number of days, '
      'and every day must contain at least one place_id.';

  String _userPrompt(ItineraryRequest request) {
    final types = request.tourismTypeWeights.isEmpty
        ? 'any'
        : request.tourismTypeWeights.keys.join(', ');
    final buffer = StringBuffer()
      ..writeln('Plan a ${request.noOfDays}-day trip to '
          '${request.city.isEmpty ? 'China' : request.city}.')
      ..writeln('Budget: ${request.budget}; popularity: ${request.popularity}; '
          'traveling with: ${request.withWho}; people: ${request.noOfPeople}; '
          'interests: $types.')
      ..writeln('Available places (place_id | name | city | type):');
    for (final p in catalog) {
      buffer.writeln('- ${p.id} | ${p.name} | ${p.cityName} | ${p.tourismType}');
    }
    return buffer.toString();
  }
}
