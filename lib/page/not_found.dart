import 'package:flutter/material.dart';

class NotFound extends StatefulWidget {

  @override
  _NotFoundState createState() => new _NotFoundState();

}

class _NotFoundState extends State<NotFound> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Not Found'),
      ),
      body: Center(
        child: Text(
          '404 - Page Not Found',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}