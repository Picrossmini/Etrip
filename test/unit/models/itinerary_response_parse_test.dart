import 'package:etrip/features/Itinerary/data/models/itinerary_response.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> placeJson(String id, String name) => {
      'place_id': id,
      'name': name,
      'profile_image': 'http://img/$id.jpg',
      'carousel': [
        {'image': 'http://img/$id.jpg'}
      ],
      'tourism_type': 'Natural Attractions',
      'category': 'garden',
      'city_name': 'Chengdu',
      'rate': 4.5,
      'total_rates': 100,
      'description': 'desc',
      'google_maps_link': 'http://maps/$id',
      'lat': 30.6,
      'lng': 104.0,
    };

void main() {
  group('ItineraryResponse.fromJson 数据模型解析', () {
    test('正常 JSON：字段齐全时正确反序列化', () {
      final resp = ItineraryResponse.fromJson({
        'no_of_days': 2,
        'description': 'trip',
        'plan': {
          '1': [placeJson('1', 'Great Wall')],
          '2': [placeJson('2', 'Forbidden City')],
        },
      });

      expect(resp.noOfDays, 2);
      expect(resp.plan.length, 2);
      expect(resp.plan[1]!.first.name, 'Great Wall');
      expect(resp.plan[2]!.first.id, '2');
      expect(resp.description, 'trip');
    });

    test('缺字段：没有 description 时按空字符串降级，不崩溃', () {
      final resp = ItineraryResponse.fromJson({
        'no_of_days': 1,
        'plan': {
          '1': [placeJson('1', 'A')],
        },
      });

      expect(resp.description, '');
      expect(resp.noOfDays, 1);
    });

    test('类型错误：no_of_days 是字符串 "3" 时容错转换', () {
      final resp = ItineraryResponse.fromJson({
        'no_of_days': '3',
        'description': 'x',
        'plan': {
          '1': [placeJson('1', 'A')],
        },
      });

      expect(resp.noOfDays, 3);
    });

    test('多出未知字段：忽略，不抛异常', () {
      final resp = ItineraryResponse.fromJson({
        'no_of_days': 1,
        'description': 'x',
        'unexpected': {'a': 1},
        'plan': {
          '1': [placeJson('1', 'A')],
        },
      });

      expect(resp.noOfDays, 1);
      expect(resp.plan[1]!.length, 1);
    });

    test('结构不合法：plan 不是对象时降级为空，不崩溃', () {
      final resp = ItineraryResponse.fromJson({
        'no_of_days': 2,
        'description': 'x',
        'plan': 'oops',
      });

      expect(resp.plan, isEmpty);
      expect(resp.noOfDays, 2);
    });
  });
}
