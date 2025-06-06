import 'package:flutter/material.dart';

import '../utils/ai_api.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // 添加动画控制器
  late AnimationController _controller;
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': '拍照解答',
      'icon': Icons.camera_alt,
      'color': Colors.blue,
      'message': '拍照解答功能即将推出'
    },
    {
      'title': '文字解答',
      'icon': Icons.text_fields,
      'color': Colors.green,
      'message': '文字解答功能已启动'
    },
    {
      'title': '笔记复习',
      'icon': Icons.book,
      'color': Colors.orange,
      'message': '笔记复习功能正在开发中'
    },
    {
      'title': '历史记录',
      'icon': Icons.history,
      'color': Colors.purple,
      'message': '查看您的历史记录'
    },
    {
      'title': '我的收藏',
      'icon': Icons.favorite,
      'color': Colors.red,
      'message': '您的收藏列表'
    },
    {
      'title': '设置',
      'icon': Icons.settings,
      'color': Colors.grey,
      'message': '个性化您的设置'
    },
    {
      'title': '测试按钮',
      'icon': Icons.check_circle,
      'color': Colors.teal,
      'message': '测试'
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('学习助手'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  '欢迎使用',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      maxCrossAxisExtent: 200,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      // 为每个卡片创建交错动画
                      final Animation<double> animation = CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                          index * 0.1,
                          1.0,
                          curve: Curves.easeOut,
                        ),
                      );
                      
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: animation.value,
                            child: Opacity(
                              opacity: animation.value,
                              child: _buildCard(index),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = _menuItems[index];
    
    return Card(
      elevation: 8,
      shadowColor: item['color'].withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          switch (index) {
            case 0: // 拍照解答
            // 处理拍照解答逻辑
              break;
            case 1: // 文字解答
            // 处理文字解答逻辑
              break;
            case 2: // 笔记复习
            // 处理笔记复习逻辑
              break;
            case 3: // 历史记录
            // 处理历史记录逻辑
              break;
            case 4: // 我的收藏
            // 处理收藏逻辑
              break;
            case 5: // 设置
            // 处理设置逻辑
              break;
            case 6: // 测试按钮
              AIApi.get_ai_request("你好，测试按钮功能").then((response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response)),
                );
              });
              break;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item['color'].withOpacity(0.7),
                item['color'],
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'],
                size: 40,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                item['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
