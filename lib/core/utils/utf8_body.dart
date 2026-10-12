import 'dart:convert';

import 'package:http/http.dart' as http;

/// 把响应体按 UTF-8 解出来。
///
/// 为什么不直接用 `response.body`：`http` 包在没有 charset 时按 HTTP 老规矩退回
/// **latin1**，于是服务端返回的中文会变成乱码（`成都` → `æé½`）。
/// 我们的后端（FastAPI）返回的正是只写 `application/json`、不带 charset 的
/// Content-Type —— 所以这里一律拿 bodyBytes 自己按 UTF-8 解。
///
/// `allowMalformed: true` 的考虑：真收到坏字节时，宁可让后面的 `jsonDecode`
/// 抛「不是合法 JSON」，也不要在这里直接崩掉。
String decodeUtf8Body(http.Response response) =>
    utf8.decode(response.bodyBytes, allowMalformed: true);
