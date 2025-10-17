
import 'package:flutter/material.dart';
import 'package:trackerapp/models/task.dart';

enum Frequency { daily, weekly, monthly }

extension FrequencyExtension on Frequency {
  String get displayName {
    switch (this) {
      case Frequency.daily:
        return 'Her Gün';
      case Frequency.weekly:
        return 'Her Hafta';
      case Frequency.monthly:
        return 'Her Ay';
    }
  }
}

class Routine {
  final String id;
  final String name;
  final String description;
  final TimeOfDay? time;
  final TaskPriority priority;
  final Frequency frequency;
  final int? dayOfWeek; // 1-7 for Monday-Sunday
  final int? dayOfMonth; // 1-31

  Routine({
    required this.id,
    required this.name,
    required this.description,
    this.time,
    required this.priority,
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'time': time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'priority': priority.index,
      'frequency': frequency.index,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      time: json['time'] != null
          ? TimeOfDay(hour: json['time']['hour'], minute: json['time']['minute'])
          : null,
      priority: TaskPriority.values[json['priority']],
      frequency: Frequency.values[json['frequency']],
      dayOfWeek: json['dayOfWeek'],
      dayOfMonth: json['dayOfMonth'],
    );
  }
}
