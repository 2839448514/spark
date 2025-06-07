import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark/provider/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AIApi {
  final Config config;
  AIApi(BuildContext context)
    : config = Provider.of<Config>(context, listen: false);
    
  // 普通请求方法（保持向后兼容）
  static Future<dynamic> get_ai_request(String prompt) async {
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
        return responseData;
      } else {
        return 'API请求失败: ${response.statusCode}';
      }
    } catch (e) {
      print('请求错误: $e');
      return '请求失败: $e';
    }
  }
    // 流式输出方法 - 返回包含内容类型的数据
  static Stream<Map<String, String>> get_ai_stream_request_with_reasoning(String prompt) async* {
    var url = Uri.parse(Config.url);

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Config.api_key}',
    };

    var body = jsonEncode({
      "model": "x1",
      "user": "123456",
      "stream": true,
      "messages": [
        {"role": "user", "content": prompt},
      ],
    });

    try {
      var request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;
      
      var streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // 处理 Server-Sent Events 格式
          var lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              var data = line.substring(6);
              if (data.trim() == '[DONE]') {
                return;
              }
              try {
                var json = jsonDecode(data);
                var content = json['choices']?[0]?['delta']?['content'];
                var reasoning = json['choices']?[0]?['delta']?['reasoning_content'];
                
                Map<String, String> result = {};
                if (content != null && content.isNotEmpty) {
                  result['content'] = content;
                }
                if (reasoning != null && reasoning.isNotEmpty) {
                  result['reasoning'] = reasoning;
                }
                
                if (result.isNotEmpty) {
                  yield result;
                }
              } catch (e) {
                // 忽略无法解析的数据块
                continue;
              }
            }
          }
        }
      } else {
        yield {'error': 'API请求失败: ${streamedResponse.statusCode}'};
      }
    } catch (e) {
      print('流式请求错误: $e');
      yield {'error': '请求失败: $e'};
    }
  }

  // 流式输出方法（保持向后兼容）
  static Stream<String> get_ai_stream_request(String prompt) async* {
    var url = Uri.parse(Config.url);

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Config.api_key}',
    };

    var body = jsonEncode({
      "model": "x1",
      "user": "123456",
      "stream": true,
      "messages": [
        {"role": "user", "content": prompt},
      ],
    });

    try {
      var request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;
      
      var streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // 处理 Server-Sent Events 格式
          var lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              var data = line.substring(6);
              if (data.trim() == '[DONE]') {
                return;
              }
              try {
                var json = jsonDecode(data);
                var content = json['choices']?[0]?['delta']?['content'];
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              } catch (e) {
                // 忽略无法解析的数据块
                continue;
              }
            }
          }
        }
      } else {
        yield 'API请求失败: ${streamedResponse.statusCode}';
      }
    } catch (e) {
      print('流式请求错误: $e');
      yield '请求失败: $e';
    }
  }
}
