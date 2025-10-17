import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Map to hold tasks, keyed by day name
  final Map<String, List<Task>> _tasks = {
    'Pazartesi': [], 'Salı': [], 'Çarşamba': [], 'Perşembe': [],
    'Cuma': [], 'Cumartesi': [], 'Pazar': [],
  };

  // Day names for keys and logic
  final List<String> _dayNames = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];
  
  // Display labels with dates
  List<String> _weekDayLabels = [];
  
  // Selected day name
  String _selectedDay = 'Pazartesi';

  @override
  void initState() {
    super.initState();
    _generateWeekDayLabels();
    _loadTasks();
    // Set selected day to today
    _selectedDay = _dayNames[DateTime.now().weekday - 1];
  }

  // --- Persistence Methods ---
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> tasksToSave = _tasks.map(
      (key, value) => MapEntry(key, value.map((task) => task.toJson()).toList()),
    );
    final String encodedTasks = jsonEncode(tasksToSave);
    await prefs.setString('tasks', encodedTasks);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedTasks = prefs.getString('tasks');
    if (encodedTasks == null || encodedTasks.isEmpty) return;

    final Map<String, dynamic> decodedTasks = jsonDecode(encodedTasks);
    
    setState(() {
      _tasks.clear();
      decodedTasks.forEach((key, value) {
        final List<Task> loadedTasks = (value as List)
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
        _tasks[key] = loadedTasks;
      });
    });
  }
  // --- End Persistence Methods ---

  void _generateWeekDayLabels() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _weekDayLabels = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayName = _dayNames[index];
      final formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      return '$dayName\n$formattedDate'; // Use newline for better layout
    });
  }

  void _addTask(String name, String description, TimeOfDay? time, TaskPriority priority) {
    final newTask = Task(
      id: DateTime.now().toString(),
      name: name,
      description: description,
      time: time,
      priority: priority,
    );
    setState(() {
      _tasks[_selectedDay]?.add(newTask);
    });
    _saveTasks();
  }

  // Black and white priority colors
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade700; // More intense red
      case TaskPriority.medium:
        return Colors.pink.shade300;
      case TaskPriority.low:
        return Colors.pink.shade100;
      default:
        return Colors.grey;
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
        child: Icon(
          Icons.circle,
          color: color,
          size: 12,
        ),
      );
    });
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Center(child: Text('$_selectedDay için Yeni Görev Ekle')),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5, // Set a constrained width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Görev Adı', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3, // Allow up to 3 lines, then scrolls
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Önem Derecesi',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.displayName),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Görev Saati'),
                        subtitle: Text(selectedTime?.format(context) ?? 'Belirtilmedi'),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _addTask(
                        nameController.text,
                        descriptionController.text,
                        selectedTime,
                        selectedPriority,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTasks = _tasks[_selectedDay] ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Görev Takibi'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Day Selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDayLabels.length,
              itemBuilder: (context, index) {
                final dayLabel = _weekDayLabels[index];
                final dayName = _dayNames[index];
                final isSelected = _selectedDay == dayName;

                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 16.0 : 4.0, right: index == _weekDayLabels.length - 1 ? 16.0 : 4.0),
                  child: ChoiceChip(
                    label: Text(dayLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                    selected: isSelected,
                    onSelected: (wasSelected) {
                      if (wasSelected) {
                        setState(() {
                          _selectedDay = dayName;
                        });
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Task List
          Expanded(
            child: currentTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Harika! Bu gün için görev yok.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: currentTasks.length,
                    itemBuilder: (context, index) {
                      final task = currentTasks[index];
                      return Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          title: Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: task.description.isNotEmpty ? Text(task.description) : null,
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (val) {
                              setState(() {
                                task.isCompleted = val ?? false;
                              });
                              _saveTasks(); // Save on completion change
                            },
                            activeColor: _getPriorityColor(task.priority),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.time != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(task.time!.format(context), style: const TextStyle(fontWeight: FontWeight.w500)),
                                ),
                              ..._generatePriorityIcons(task.priority), // Spread the list of icons here
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Görev Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
