import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  final Map<String, List<Task>> _tasks = {};

  final List<String> _dayNames = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];
  
  List<String> _weekDayLabels = [];
  
  DateTime _focusedDate = DateTime.now();
  final DateTime _initialDate = DateTime.now();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    
    _selectedIndex = _focusedDate.weekday - 1;
    _pageController = PageController(initialPage: _selectedIndex);
    _generateWeekDayLabels();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSelectedDay(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _scrollToSelectedDay(int index) {
    final key = _dayKeys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item
      );
    }
  }

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

  void _generateWeekDayLabels() {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    _weekDayLabels = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayName = _dayNames[index];
      return '${dayName.substring(0, 3)} ${date.day}';
    });
  }

  void _addTask(String name, String description, TimeOfDay? time, TaskPriority priority) {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    final selectedDate = startOfWeek.add(Duration(days: _selectedIndex));
    final dateKey = _getDateKey(selectedDate);

    final newTask = Task(
      id: DateTime.now().toString(),
      name: name,
      description: description,
      time: time,
      priority: priority,
    );
    setState(() {
      if (_tasks.containsKey(dateKey)) {
        _tasks[dateKey]!.add(newTask);
      } else {
        _tasks[dateKey] = [newTask];
      }
    });
    _saveTasks();
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade700;
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
        child: Icon(Icons.circle, color: color, size: 12),
      );
    });
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;
    TaskPriority selectedPriority = TaskPriority.medium;

    final startOfWeek = _getStartOfWeek(_focusedDate);
    final selectedDate = startOfWeek.add(Duration(days: _selectedIndex));
    final title = '${DateFormat('d MMMM', 'tr_TR').format(selectedDate)} için Yeni Görev';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Center(child: Text(title)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
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
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskPriority>(
                        value: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Önem Derecesi', border: OutlineInputBorder()),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(value: priority, child: Text(priority.displayName));
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() => selectedPriority = newValue);
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
                              setDialogState(() => selectedTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _addTask(nameController.text, descriptionController.text, selectedTime, selectedPriority);
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

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Harika! Bu gün için görev yok.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: task.description.isNotEmpty ? Text(task.description) : null,
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (val) {
                setState(() => task.isCompleted = val ?? false);
                _saveTasks();
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
                ..._generatePriorityIcons(task.priority),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekDifference = _getStartOfWeek(_focusedDate).difference(_getStartOfWeek(_initialDate)).inDays;
    final canGoBack = weekDifference > -7;
    final canGoForward = weekDifference < 7;

    return Scaffold(
      appBar: AppBar(
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedDate = _focusedDate.subtract(const Duration(days: 7));
                  _generateWeekDayLabels();
                }),
              )
            : const SizedBox(width: 48),
        title: Text(
          DateFormat.yMMMM('tr_TR').format(_focusedDate),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          canGoForward
              ? IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _focusedDate = _focusedDate.add(const Duration(days: 7));
                    _generateWeekDayLabels();
                  }),
                )
              : const SizedBox(width: 48), // Balance the leading button
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDayLabels.length,
              itemBuilder: (context, index) {
                final dayLabel = _weekDayLabels[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  key: _dayKeys[index],
                  padding: EdgeInsets.only(left: index == 0 ? 16.0 : 4.0, right: index == _weekDayLabels.length - 1 ? 16.0 : 4.0),
                  child: ChoiceChip(
                    label: Text(dayLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedIndex = index);
                        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        _scrollToSelectedDay(index);
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
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _dayNames.length,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
                _scrollToSelectedDay(index);
              },
              itemBuilder: (context, index) {
                final startOfWeek = _getStartOfWeek(_focusedDate);
                final dateForPage = startOfWeek.add(Duration(days: index));
                final dateKey = _getDateKey(dateForPage);
                final tasksForDay = _tasks[dateKey] ?? [];
                return _buildTaskList(tasksForDay);
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