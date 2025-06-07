import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spark/provider/config.dart';

class SettingsPage extends StatefulWidget {

  @override
  _SettingsPageState createState() => new _SettingsPageState();

}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _apiKeyController;

   @override
   void initState() {
     super.initState();
     final cfg = Provider.of<Config>(context, listen: false);
     _apiKeyController = TextEditingController(text: cfg.api_key);
   }

   @override
   void dispose() {
     _apiKeyController.dispose();
     super.dispose();
   }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Config>(context, listen: false);
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Settings Page'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                config.api_key = _apiKeyController.text.trim();
                config.notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API Key 已保存'))
                );
              },
              child: Text("保存设置"),
            ),
          ],
        )
      ),
    );
  }
}