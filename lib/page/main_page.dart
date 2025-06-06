import 'package:flutter/material.dart';
import 'package:spark/page/home_page.dart';
import 'package:spark/page/settings_page.dart';

import 'note_page.dart';





class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [HomePage(),NotePage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('学习助手')),
      body: _pages[_currentIndex],
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Action when button is pressed
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Floating Action Button Pressed')),
      //     );
      //   },
      //   child: Icon(Icons.add),
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index; // 切换页面
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '主页'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: '笔记'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
