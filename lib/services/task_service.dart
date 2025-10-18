
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/models/task.dart';

class TaskService {
  static const _tasksKey = 'tasks';

  Future<Map<String, List<Task>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_tasksKey);
    if (tasksString == null) {
      return {};
    }
    final Map<String, dynamic> jsonMap = jsonDecode(tasksString);
    return jsonMap.map((date, taskList) {
      final tasks = (taskList as List).map((json) => Task.fromJson(json)).toList();
      return MapEntry(date, tasks);
    });
  }

  Future<void> saveTasks(Map<String, List<Task>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = tasks.map((date, taskList) {
      final jsonList = taskList.map((task) => task.toJson()).toList();
      return MapEntry(date, jsonList);
    });
    await prefs.setString(_tasksKey, jsonEncode(jsonMap));
  }

  Future<void> deleteTasksByRoutine(String routineId) async {
    final tasks = await loadTasks();
    tasks.forEach((date, taskList) {
      taskList.removeWhere((task) => task.id.startsWith(routineId + '-') && !task.isCompleted);
    });
    await saveTasks(tasks);
  }
}
