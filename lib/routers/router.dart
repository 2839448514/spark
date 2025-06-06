
import 'package:flutter/material.dart';
import '../page/home_page.dart';
import '../page/not_found.dart';



class Routers {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutersPath.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      default:
        return MaterialPageRoute(builder: (_) => NotFound());
    }
  }
}


class RoutersPath{
  static const String home = '/home';
}