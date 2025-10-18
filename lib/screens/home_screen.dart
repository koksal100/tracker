
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/controllers/notification_controller.dart';
import 'package:trackerapp/models/routine.dart';
import 'package:trackerapp/screens/task_detail_screen.dart';
import 'package:trackerapp/services/routine_service.dart';
import 'package:trackerapp/services/task_service.dart';
import '../models/task.dart';
import '../utils/app_colors.dart';

enum SortMethod { byCreation, byStatus, byPriority, byTime }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  Map<String, List<Task>> _tasks = {};
  List<Routine> _routines = [];
  final RoutineService _routineService = RoutineService();
  final TaskService _taskService = TaskService();

  final List<String> _dayNames = [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
  ];
  
  List<String> _weekDayLabels = [];
  
  DateTime _focusedDate = DateTime.now();
  final DateTime _initialDate = DateTime.now();

  int _selectedIndex = 0;
  SortMethod _sortMethod = SortMethod.byCreation;
  bool _sortAscending = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDataAndGenerateTasks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDataAndGenerateTasks();
    }
  }

  Future<void> refreshTasks() async {
    await _loadDataAndGenerateTasks();
  }

  Future<void> _loadDataAndGenerateTasks() async {
    setState(() => _isLoading = true);
    await _loadTasks();
    await _loadRoutines();
    _generateTasksFromRoutines();
    
    _selectedIndex = _focusedDate.weekday - 1;
    _pageController = PageController(initialPage: _selectedIndex);
    _generateWeekDayLabels();

    setState(() => _isLoading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSelectedDay(_selectedIndex);
      }
    });
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
    await _taskService.saveTasks(_tasks);
  }

  Future<void> _loadTasks() async {
    _tasks = await _taskService.loadTasks();
  }

  Future<void> _loadRoutines() async {
    _routines = await _routineService.loadRoutines();
  }

  void _generateTasksFromRoutines() {
    if (_routines.isEmpty) return;

    // Generate for a range of weeks to be safe (-2 to +2 weeks from current)
    final today = DateTime.now();
    final generationStartDate = today.subtract(const Duration(days: 14));

    for (int i = 0; i < 30; i++) { // Generate for roughly a month
      final date = generationStartDate.add(Duration(days: i));
      final dateKey = _getDateKey(date);

      for (final routine in _routines) {
        bool shouldCreate = false;
        switch (routine.frequency) {
          case Frequency.daily:
            shouldCreate = true;
            break;
          case Frequency.weekly:
            if (date.weekday == routine.dayOfWeek) shouldCreate = true;
            break;
          case Frequency.monthly:
            if (date.day == routine.dayOfMonth) shouldCreate = true;
            break;
        }

        if (shouldCreate) {
          final taskInstanceId = '${routine.id}-${dateKey}';
          final dayTasks = _tasks.putIfAbsent(dateKey, () => []);
          final taskExists = dayTasks.any((task) => task.id == taskInstanceId);

          if (!taskExists) {
            final newTask = Task(
              id: taskInstanceId,
              name: routine.name,
              description: routine.description,
              time: routine.time,
              priority: routine.priority,
              isCompleted: false,
              notificationsEnabled: false, // Routines don't auto-enable notifications
            );
            dayTasks.add(newTask);
          }
        }
      }
    }
    _saveTasks();
  }

  void _generateWeekDayLabels() {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    _weekDayLabels = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayName = _dayNames[index];
      return '${dayName} ${date.day}';
    });
  }

  void _setSortMethod(SortMethod method) {
    setState(() {
      if (_sortMethod == method) {
        _sortAscending = !_sortAscending;
      } else {
        _sortMethod = method;
        _sortAscending = true;
      }
    });
  }

  List<Task> _sortTasks(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks);
    switch (_sortMethod) {
      case SortMethod.byStatus:
        sortedTasks.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));
        break;
      case SortMethod.byPriority:
        sortedTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case SortMethod.byTime:
        sortedTasks.sort((a, b) {
          if (a.time == null && b.time == null) return 0;
          if (a.time == null) return 1;
          if (b.time == null) return -1;
          final aMinutes = a.time!.hour * 60 + a.time!.minute;
          final bMinutes = b.time!.hour * 60 + b.time!.minute;
          return aMinutes.compareTo(bMinutes);
        });
        break;
      case SortMethod.byCreation:
        break;
    }
    return _sortAscending ? sortedTasks : sortedTasks.reversed.toList();
  }

  void _addTask(String name, String description, TimeOfDay? time, TaskPriority priority, bool notificationsEnabled) {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    final selectedDate = startOfWeek.add(Duration(days: _selectedIndex));
    final dateKey = _getDateKey(selectedDate);

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      time: time,
      priority: priority,
      notificationsEnabled: notificationsEnabled,
    );
    setState(() {
      _tasks.putIfAbsent(dateKey, () => []).add(newTask);
    });
    _saveTasks();
    if (newTask.notificationsEnabled) {
      NotificationController.scheduleNotification(newTask, selectedDate);
    }
  }

  void _updateTask(Task oldTask, Task newTask) {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    final dateForTask = startOfWeek.add(Duration(days: _selectedIndex));
    final dateKey = _getDateKey(dateForTask);

    final tasksForDay = _tasks[dateKey];
    if (tasksForDay == null) return;

    final taskIndex = tasksForDay.indexWhere((t) => t.id == oldTask.id);
    if (taskIndex != -1) {
      setState(() {
        tasksForDay[taskIndex] = newTask;
      });
      _saveTasks();

      NotificationController.cancelNotification(oldTask);
      if (newTask.notificationsEnabled) {
        NotificationController.scheduleNotification(newTask, dateForTask);
      }
    }
  }

  void _deleteTask(Task taskToDelete) {
    final startOfWeek = _getStartOfWeek(_focusedDate);
    final dateForTask = startOfWeek.add(Duration(days: _selectedIndex));
    final dateKey = _getDateKey(dateForTask);
    final tasksForDay = _tasks[dateKey];
    if (tasksForDay == null) return;

    setState(() {
      tasksForDay.removeWhere((t) => t.id == taskToDelete.id);
    });
    _saveTasks();
    NotificationController.cancelNotification(taskToDelete);
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

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? selectedTime;
    TaskPriority selectedPriority = TaskPriority.medium;
    bool notificationsEnabled = false;

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
                           trailing: selectedTime != null ? IconButton(
                            icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.outline),
                            onPressed: () => setDialogState(() {
                              selectedTime = null;
                              notificationsEnabled = false;
                            }),
                          ) : null,
                        ),
                      ),
                      if (selectedTime != null)
                        SwitchListTile(
                          title: const Text('Bildirimleri Aç'),
                          value: notificationsEnabled,
                          onChanged: (bool value) => setDialogState(() => notificationsEnabled = value),
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
                      _addTask(nameController.text, descriptionController.text, selectedTime, selectedPriority, notificationsEnabled);
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

  Widget _buildSortableHeader() {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: TextButton(
              onPressed: () => _setSortMethod(SortMethod.byStatus),
              child: Icon(
                Icons.check_box_outline_blank,
                size: 20,
                color: _sortMethod == SortMethod.byStatus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const Expanded(child: Text('Görev', style: boldStyle)),
          SizedBox(
            width: 100,
            child: TextButton.icon(
              onPressed: () => _setSortMethod(SortMethod.byTime),
              icon: _sortMethod == SortMethod.byTime
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  : const SizedBox(width: 4),
              label: const Text('Saat', style: boldStyle),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextButton.icon(
              onPressed: () => _setSortMethod(SortMethod.byPriority),
              icon: _sortMethod == SortMethod.byPriority
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16)
                  : const SizedBox(width: 4),
              label: const Text('Önem', style: boldStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, DateTime dateForTasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
             Text('Harika! Bu gün için görev yok.', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    task: task,
                    taskDate: dateForTasks,
                  ),
                ),
              );

              if (result != null && mounted) {
                if (result == 'deleted') {
                  _deleteTask(task);
                } else if (result is Task) {
                  _updateTask(task, result);
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (val) {
                        setState(() => task.isCompleted = val ?? false);
                        _saveTasks();
                      },
                      activeColor: _getPriorityColor(task.priority),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (task.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(task.description, style: Theme.of(context).textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: task.time != null
                        ? Text(task.time!.format(context), textAlign: TextAlign.center)
                        : const Text('-', textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _generatePriorityIcons(task.priority),
                    ),
                  ),
                ],
              ),
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
          style: const TextStyle(
            fontFamily: 'DancingScript',
            fontSize: 28, // Increased font size for handwritten style
            fontWeight: FontWeight.bold,
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                              _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                      final sortedTasks = _sortTasks(tasksForDay);
                      return Column(
                        children: [
                          _buildSortableHeader(),
                          Expanded(
                            child: _buildTaskList(sortedTasks, dateForPage),
                          ),
                        ],
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
