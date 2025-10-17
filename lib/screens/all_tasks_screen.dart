import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/models/routine.dart';
import 'package:trackerapp/models/task.dart';
import 'package:trackerapp/screens/create_routine_screen.dart';
import 'package:trackerapp/services/routine_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

enum SortMethodRoutines { byName, byFrequency, byTime, byPriority }

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final RoutineService _routineService = RoutineService();
  List<Routine> _routines = [];
  bool _isLoading = true;

  SortMethodRoutines _sortMethod = SortMethodRoutines.byName;
  bool _sortAscending = true;

  final List<String> _weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await _routineService.loadRoutines();
    setState(() {
      _routines = routines;
      _isLoading = false;
    });
  }

  void _setSortMethod(SortMethodRoutines method) {
    setState(() {
      if (_sortMethod == method) {
        _sortAscending = !_sortAscending;
      } else {
        _sortMethod = method;
        _sortAscending = true;
      }
    });
  }

  List<Routine> _sortRoutines(List<Routine> routines) {
    List<Routine> sortedRoutines = List.from(routines);
    switch (_sortMethod) {
      case SortMethodRoutines.byName:
        sortedRoutines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMethodRoutines.byFrequency:
        sortedRoutines.sort((a, b) => a.frequency.index.compareTo(b.frequency.index));
        break;
      case SortMethodRoutines.byPriority:
        sortedRoutines.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case SortMethodRoutines.byTime:
        sortedRoutines.sort((a, b) {
          if (a.time == null && b.time == null) return 0;
          if (a.time == null) return 1;
          if (b.time == null) return -1;
          final aMinutes = a.time!.hour * 60 + a.time!.minute;
          final bMinutes = b.time!.hour * 60 + b.time!.minute;
          return aMinutes.compareTo(bMinutes);
        });
        break;
    }
    return _sortAscending ? sortedRoutines : sortedRoutines.reversed.toList();
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rutini Sil'),
        content: Text('"${routine.name}" rutinini ve bu rutinden oluşturulmuş tüm tamamlanmamış görevleri silmek istediğinizden emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Remove the routine itself
      _routines.removeWhere((r) => r.id == routine.id);
      await _routineService.saveRoutines(_routines);

      // 2. Remove its generated tasks from the main task list
      final prefs = await SharedPreferences.getInstance();
      final String? tasksString = prefs.getString('tasks');
      if (tasksString != null) {
        Map<String, dynamic> tasksJson = jsonDecode(tasksString);
        Map<String, List<dynamic>> tasks = tasksJson.map((key, value) => MapEntry(key, value as List<dynamic>));
        
        tasks.forEach((dateKey, taskList) {
          taskList.removeWhere((taskJson) {
            String taskId = taskJson['id'];
            bool isCompleted = taskJson['isCompleted'] ?? false;
            return taskId.startsWith(routine.id + '-') && !isCompleted;
          });
        });

        await prefs.setString('tasks', jsonEncode(tasks));
      }
      
      setState(() {});
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutin ve ilgili görevler silindi.')),
        );
      }
    }
  }

  void _navigateToCreateRoutine({Routine? routine}) async {
    final result = await Navigator.push<Routine>(
      context,
      MaterialPageRoute(builder: (context) => CreateRoutineScreen(routine: routine)),
    );

    if (result != null && mounted) {
      // If a routine was edited, replace it in the list
      if (routine != null) {
        final index = _routines.indexWhere((r) => r.id == result.id);
        if (index != -1) {
          setState(() {
            _routines[index] = result;
          });
        }
      } else {
        // If a new routine was created, add it to the list
        setState(() {
          _routines.add(result);
        });
      }
    }
  }


  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHighColor;
      case TaskPriority.medium:
        return AppColors.priorityMediumColor;
      case TaskPriority.low:
        return AppColors.priorityLowColor;
      default:
        return AppColors.priorityDefaultColor;
    }
  }

  List<Widget> _generatePriorityIcons(TaskPriority priority) {
    final color = _getPriorityColor(priority);
    int count;
    switch (priority) {
      case TaskPriority.high:
        count = 5;
        break;
      case TaskPriority.medium:
        count = 3;
        break;
      case TaskPriority.low:
      default:
        count = 1;
        break;
    }

    return List.generate(count, (index) {
      return Padding(
        padding: const EdgeInsets.only(left: 2.0),
        child: Icon(Icons.circle, color: color, size: 12),
      );
    });
  }

  Widget _buildSortableHeader() {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold,fontSize:12);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: TextButton.icon(
              onPressed: () => _setSortMethod(SortMethodRoutines.byName),
              icon: _sortMethod == SortMethodRoutines.byName
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  : const SizedBox(width: 0),
              label: const Text('Rutin Adı', style: boldStyle,textAlign: TextAlign.left),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: () => _setSortMethod(SortMethodRoutines.byFrequency),
              icon: _sortMethod == SortMethodRoutines.byFrequency
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  : const SizedBox(width: 0),
              label: const Text('Sıklık', style: boldStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: () => _setSortMethod(SortMethodRoutines.byPriority),
              icon: _sortMethod == SortMethodRoutines.byPriority
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  : const SizedBox(width: 0),
              label: const Text('Önem', style: boldStyle),
            ),
          ),
          const SizedBox(width: 48), // For delete button
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedRoutines = _sortRoutines(_routines);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Tüm Görevler & Rutinler'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                onPressed: _navigateToCreateRoutine,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Yeni Rutin Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  side: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.0), // White thin border
                ),
              ),
            ),
            const Divider(),
            _buildSortableHeader(),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _routines.isEmpty
                      ? Center(
                          child: Text(
                            'Henüz hiç rutin oluşturmadın.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          itemCount: sortedRoutines.length,
                          itemBuilder: (context, index) {
                            final routine = sortedRoutines[index];
                            String frequencyDetail = routine.frequency.displayName;
                            if (routine.frequency == Frequency.weekly && routine.dayOfWeek != null) {
                              frequencyDetail += ' (${_weekDays[routine.dayOfWeek! - 1]})';
                            } else if (routine.frequency == Frequency.monthly && routine.dayOfMonth != null) {
                              frequencyDetail += ' (${routine.dayOfMonth})';
                            }
                            return Card(
                              elevation: 1.0,
                              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: InkWell(
                                onTap: () => _navigateToCreateRoutine(routine: routine),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (routine.description.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0),
                                                child: Text(routine.description, style: Theme.of(context).textTheme.bodySmall),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(frequencyDetail, textAlign: TextAlign.center),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: _generatePriorityIcons(routine.priority),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: IconButton(
                                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                          onPressed: () => _deleteRoutine(routine),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}