import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:etrip/core/config.dart';
import 'package:etrip/core/mock_data.dart';
import 'package:etrip/core/utils/utf8_body.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_request.dart';
import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:etrip/features/Itinerary/domain/plan_hydrator.dart';
import 'package:etrip/features/Itinerary/domain/travel_plan_generator.dart';
import 'package:etrip/features/places/data/models/place_model.dart';

/// 走后端（etrip-backend 的 `POST /api/itinerary`）生成行程。
///
/// 与 [LlmTravelPlanGenerator] 的差别在于 **DeepSeek 密钥不在客户端**：
/// 它只存在于服务端的环境变量里，客户端带的是一个访问令牌。
///
/// 景点仍然由「本地目录」兜底，只是挑选动作挪到了服务端：
/// 客户端把目录的精简版（只有 id / 名字 / 城市 / 类别，够用来挑就行）放进 `catalog`
/// 字段，后端写进提示词、要求模型只能从里面挑 place_id；拿回来后再用
/// [PlanHydrator] 在本地水合成完整的 [PlaceModel]，图片、评分、简介一样不少。
class BackendTravelPlanGenerator implements TravelPlanGenerator {
  final http.Client client;
  final String baseUrl;
  final String? token;
  final Duration timeout;
  final List<PlaceModel> catalog;
  final PlanHydrator hydrator;

  /// 后端默认给上游 30s（`DEEPSEEK_TIMEOUT`），客户端要比它宽松，
  /// 否则会出现「服务端还在等模型、客户端已经超时」的假超时。
  static const Duration _defaultTimeout = Duration(seconds: 40);

  BackendTravelPlanGenerator({
    http.Client? client,
    String? baseUrl,
    String? token,
    this.timeout = _defaultTimeout,
    List<PlaceModel>? catalog,
    this.hydrator = const PlanHydrator(),
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.backendBaseUrl,
        token = token ?? AppConfig.backendToken,
        catalog = catalog ?? mockPlaces;

  @override
  Future<ItineraryResponse> generate({
    required String userId,
    required ItineraryRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl/api/itinerary');

    final http.Response response;
    try {
      response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (token != null && token!.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(buildBody(userId, request)),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw ItineraryGenerationException('生成超时，请稍后重试', cause: e);
    } on http.ClientException catch (e) {
      throw ItineraryGenerationException('网络连接失败，请检查网络后重试', cause: e);
    }

    if (response.statusCode != 200) {
      throw ItineraryGenerationException(
        _errorMessage(response),
        cause: decodeUtf8Body(response),
      );
    }

    return parseBody(decodeUtf8Body(response));
  }

  /// 组装请求体。
  ///
  /// 后端要的是 `tourism_types`（字符串数组），客户端存的是权重表，
  /// 这里取键；权重本身是给「以后做排序」留的，当前后端用不上。
  Map<String, dynamic> buildBody(String userId, ItineraryRequest request) => {
        'user_id': _normalizedUserId(userId),
        'city': request.city,
        'tourism_types': request.tourismTypeWeights.keys.toList(),
        'days': request.noOfDays,
        'no_of_people': request.noOfPeople,
        if (request.startDate != null) 'start_date': _isoDate(request.startDate!),
        if (request.endDate != null) 'end_date': _isoDate(request.endDate!),
        'catalog': [
          for (final place in catalog)
            {
              'place_id': place.id,
              'name': place.name,
              'city_name': place.cityName,
              'tourism_type': place.tourismType,
            },
        ],
      };

  /// `user_id` 是后端的必填字段（1~64 字符）。未登录时本地 uid 是空串，
  /// 这里补一个匿名值，免得白跑一趟 422。
  static String _normalizedUserId(String userId) {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return 'anonymous';
    return trimmed.length <= 64 ? trimmed : trimmed.substring(0, 64);
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 把后端的响应体解析成行程。响应格式见 README 的 `POST /api/itinerary`。
  ItineraryResponse parseBody(String responseBody) {
    Object? decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      throw const ItineraryGenerationException('服务返回的内容不是合法 JSON');
    }
    if (decoded is! Map) {
      throw const ItineraryGenerationException('服务返回的内容不是 JSON 对象');
    }

    final rawDays = decoded['days'];
    if (rawDays is! List) {
      throw const ItineraryGenerationException('服务返回的内容缺少 days');
    }

    final dayPlaceIds = <List<String>>[];
    for (var i = 0; i < rawDays.length; i++) {
      final day = rawDays[i];
      if (day is! Map) {
        throw ItineraryGenerationException('服务返回的第 ${i + 1} 天格式不对');
      }
      final rawPlaces = day['places'];
      if (rawPlaces is! List) {
        throw ItineraryGenerationException('服务返回的第 ${i + 1} 天缺少 places');
      }
      dayPlaceIds.add([
        for (final place in rawPlaces)
          if (place is Map && place['place_id'] != null)
            place['place_id'].toString(),
      ]);
    }

    final description =
        decoded['description'] is String ? decoded['description'] as String : '';

    return hydrator.hydrate(
      dayPlaceIds: dayPlaceIds,
      description: description,
      catalog: catalog,
    );
  }

  /// 后端所有错误都是 `{"error": {"code", "message", "details"}}`，
  /// 直接把 message 透给用户；解析不出来才退回通用文案。
  static String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(decodeUtf8Body(response));
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          if (error['code'] == 'unauthorized') {
            return '访问令牌无效，请检查客户端配置';
          }
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // 响应体不是 JSON（比如网关直接返回 HTML），走下面的兜底文案。
    }
    return '服务暂时不可用（HTTP ${response.statusCode}）';
  }
}
