
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/models/routine.dart';

class RoutineService {
  static const _routinesKey = 'routines';

  Future<List<Routine>> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? routinesString = prefs.getString(_routinesKey);
    if (routinesString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(routinesString);
    return jsonList.map((json) => Routine.fromJson(json)).toList();
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        routines.map((routine) => routine.toJson()).toList();
    await prefs.setString(_routinesKey, jsonEncode(jsonList));
  }
}
