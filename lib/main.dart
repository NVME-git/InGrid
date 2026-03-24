import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warm SharedPreferences so it's ready before the first game load.
  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: InGridApp()));
}
