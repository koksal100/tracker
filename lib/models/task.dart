import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'Yüksek';
      case TaskPriority.medium:
        return 'Orta';
      case TaskPriority.low:
        return 'Düşük';
    }
  }
}

class Task {
  final String id;
  final String name;
  final String description;
  final TimeOfDay? time;
  final TaskPriority priority;
  bool isCompleted;
  bool notificationsEnabled;

  Task({
    required this.id,
    required this.name,
    required this.description,
    this.time,
    required this.priority,
    this.isCompleted = false,
    this.notificationsEnabled = false,
  });

  // Serialization: Task object -> Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'time': time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'priority': priority.index, // Store enum as its index
      'isCompleted': isCompleted,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Deserialization: Map -> Task object
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      time: json['time'] != null
          ? TimeOfDay(hour: json['time']['hour'], minute: json['time']['minute'])
          : null,
      priority: TaskPriority.values[json['priority']], // Get enum from index
      isCompleted: json['isCompleted'],
      notificationsEnabled: json['notificationsEnabled'] ?? false,
    );
  }
}