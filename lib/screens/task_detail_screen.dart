import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../widgets/custom_app_bar.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final DateTime taskDate;

  const TaskDetailScreen({super.key, required this.task, required this.taskDate});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  late bool _notificationsEnabled;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedPriority = widget.task.priority;
    _selectedTime = widget.task.time;
    _notificationsEnabled = widget.task.notificationsEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: const Text('Bu görevi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop('deleted'); // Pop screen with result
            },
            child: Text('Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    if (_nameController.text.isEmpty) return;

    final updatedTask = Task(
      id: widget.task.id,
      name: _nameController.text,
      description: _descriptionController.text,
      priority: _selectedPriority,
      time: _selectedTime,
      isCompleted: widget.task.isCompleted,
      notificationsEnabled: _notificationsEnabled,
    );
    Navigator.of(context).pop(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: DateFormat('d MMMM', 'tr_TR').format(widget.taskDate),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Görev Adı', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Önem Derecesi', border: OutlineInputBorder()),
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(value: priority, child: Text(priority.displayName));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedPriority = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Görev Saati'),
                    subtitle: Text(_selectedTime?.format(context) ?? 'Belirtilmedi'),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    trailing: _selectedTime != null ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.outline),
                      onPressed: () => setState(() {
                        _selectedTime = null;
                        _notificationsEnabled = false;
                      }),
                    ) : null,
                  ),
                ),
                if (_selectedTime != null)
                  SwitchListTile(
                    title: const Text('Bildirimleri Aç'),
                    subtitle: const Text('Görev zamanı geldiğinde bildirim gönder.'),
                    value: _notificationsEnabled,
                    onChanged: (bool value) => setState(() => _notificationsEnabled = value),
                  ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Değişiklikleri Kaydet'),
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text('Görevi Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onPressed: _deleteTask,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}