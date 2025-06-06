import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark/page/main_page.dart';
import 'package:spark/provider/config.dart';
import 'package:spark/utils/NoteDatabase.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  // 初始化 sqflite_ffi
  if (Platform.isWindows || Platform.isLinux) {
    // 初始化FFI
    // Windows和Linux需要使用FFI
    sqfliteFfiInit();
    // 设置数据库工厂
    databaseFactory = databaseFactoryFfi;
    print('初始化了 databaseFactoryFfi');
  }
  // 初始化数据库
  try {
    await NoteDatabase.initializeDatabase();
    print('数据库初始化成功');
  } catch (e) {
    print('数据库初始化错误: $e');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => Config())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainPage(),
    );
  }
}
