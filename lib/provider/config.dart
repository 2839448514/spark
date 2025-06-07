import 'package:flutter/foundation.dart';

class Config extends ChangeNotifier {
  String url =
      "https://spark-api-open.xf-yun.com/v2/chat/completions";
  String _apiKey = "BPAkTeBQxqWbHFsMpDNv:nXkJsomXOQdyljyouPIm1";

  /// 获取 API Key
  String get api_key => _apiKey;

  /// 设置 API Key，并通知监听器
  set api_key(String value) {
    if (value != _apiKey) {
      _apiKey = value;
      notifyListeners();
    }
  }
}
