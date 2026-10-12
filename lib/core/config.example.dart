// Copy this file to `config.dart` and fill in your own values.
// `config.dart` is git-ignored so secrets never get committed.
class AppConfig {
  static const String apiBaseUrl = "http://192.168.1.2:8000";

  // 自建后端（etrip-backend）：生成行程走 POST /api/itinerary，聊天走 POST /api/chat。
  // DeepSeek 密钥只存在于服务端的环境变量里，客户端不再持有它，只带一个访问令牌。
  static const String backendBaseUrl = "http://192.168.1.2:8000";
  static const String backendToken = "YOUR_BACKEND_TOKEN";
}
