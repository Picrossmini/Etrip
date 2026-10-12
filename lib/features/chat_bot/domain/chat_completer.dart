/// 聊天补全的抽象：给一段 conversation，换回模型这一条助手消息。
///
/// 生产实现是 [BackendChatCompleter]（走自建后端的 `POST /api/chat`），
/// 测试里换成假的，就能在没有网络、没有密钥的情况下确定性地跑工具循环。
///
/// **为什么要有这层抽象**：聊天是「一问一答 + 可能在客户端执行的工具」，
/// 关键协议只有一条 —— 把 messages 原样发上去、把助手消息原样拿回来
/// （含 `tool_calls` 和里面的 `id`）。把它抽出来，工具循环就能脱离 HTTP 单测。
library;

/// 一次补全的结果。
class ChatCompletion {
  const ChatCompletion({required this.message, this.finishReason = 'stop'});

  /// 模型这一条助手消息，形状对齐 OpenAI / DeepSeek：
  /// `{'role': 'assistant', 'content': ..., 'tool_calls': [...]}`。
  /// 已经是「只含约定字段」的干净版本，可直接追加进下一轮的 messages。
  final Map<String, dynamic> message;

  /// `stop` / `tool_calls` / `length` 等，由上游给出，仅用于日志与断言。
  final String finishReason;

  /// 助手给的文字（去掉首尾空白）；模型要求调工具时通常为空串。
  String get content => (message['content'] as String?)?.trim() ?? '';

  /// 模型要求执行的工具调用；没有则为空列表。
  List<Map<String, dynamic>> get toolCalls {
    final raw = message['tool_calls'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  bool get wantsTools => toolCalls.isNotEmpty;
}

/// 聊天链路上所有可预期失败的统一类型。
///
/// 页面只需要处理这一种异常（换成翻译好的网络提示），
/// 具体原因（超时 / 令牌无效 / 上游 502）保留在 [message] 里方便排查。
class ChatException implements Exception {
  const ChatException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ChatException: $message';
}

/// 抽象接口：单轮补全。
///
/// 只暴露调用方真正在乎的两样东西：整段 messages、以及工具定义。
/// `max_tokens` 这类策略留在实现里（[BackendChatCompleter.maxTokens]），
/// 不必让每个调用方都操心。
abstract class ChatCompleter {
  Future<ChatCompletion> complete({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  });
}
