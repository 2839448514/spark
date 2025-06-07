import 'package:flutter/material.dart';
import '../page/home_page.dart';
import '../page/home_utils/textsolve_page.dart';
import '../page/not_found.dart';


class Routers {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutersPath.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case RoutersPath.textsolve:
        return MaterialPageRoute(builder: (_) => TextSolvePage());
      default:
        return MaterialPageRoute(builder: (_) => NotFound());
    }
  }
}


class RoutersPath {
  static const String home = '/home';
  static const String textsolve = '/textsolve';
}