import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark/provider/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIApi {
  final Config config;

  AIApi(BuildContext context)
    : config = Provider.of<Config>(context, listen: false);
  static Future<String> get_ai_request(String prompt) async {
    var url = Uri.parse(Config.url);

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Config.api_key}',
    };

    var body = jsonEncode({
      "model": "x1",
      "user": "123456",
      "messages": [
        {"role": "user", "content": prompt},
      ],
    });

    try {
      var response = await http.post(url, headers: headers, body: body);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        // 根据实际API响应格式解析
        return responseData.toString();
      } else {
        return 'API请求失败: ${response.statusCode}';
      }
    } catch (e) {
      print('请求错误: $e');
      return '请求失败: $e';
    }
  }
}
