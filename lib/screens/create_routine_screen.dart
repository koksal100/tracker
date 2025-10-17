
import 'package:flutter/material.dart';
import 'package:trackerapp/models/routine.dart';
import 'package:trackerapp/models/task.dart';
import 'package:trackerapp/services/routine_service.dart';
import '../widgets/custom_app_bar.dart';

class CreateRoutineScreen extends StatefulWidget {
  final Routine? routine; // Optional routine for editing

  const CreateRoutineScreen({super.key, this.routine});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routineService = RoutineService();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TimeOfDay? _selectedTime;
  Frequency _selectedFrequency = Frequency.daily;
  int _selectedDayOfWeek = 1; // Monday
  int _selectedDayOfMonth = 1;

  final List<String> _weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
      _descriptionController.text = widget.routine!.description;
      _selectedPriority = widget.routine!.priority;
      _selectedTime = widget.routine!.time;
      _selectedFrequency = widget.routine!.frequency;
      _selectedDayOfWeek = widget.routine!.dayOfWeek ?? 1;
      _selectedDayOfMonth = widget.routine!.dayOfMonth ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
    if (_formKey.currentState!.validate()) {
      final newRoutine = Routine(
        id: widget.routine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        time: _selectedTime,
        frequency: _selectedFrequency,
        dayOfWeek: _selectedFrequency == Frequency.weekly ? _selectedDayOfWeek : null,
        dayOfMonth: _selectedFrequency == Frequency.monthly ? _selectedDayOfMonth : null,
      );

      final routines = await _routineService.loadRoutines();
      if (widget.routine == null) {
        // Add new routine
        routines.add(newRoutine);
      } else {
        // Update existing routine
        final index = routines.indexWhere((r) => r.id == newRoutine.id);
        if (index != -1) {
          routines[index] = newRoutine;
        }
      }
      await _routineService.saveRoutines(routines);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.routine == null ? 'Rutin başarıyla kaydedildi!' : 'Rutin başarıyla güncellendi!')),
        );
        Navigator.of(context).pop(newRoutine);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.routine == null ? 'Yeni Rutin Oluştur' : 'Rutini Düzenle'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Rutin Adı', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir ad girin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                    title: const Text('Görevin Saati'),
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
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                DropdownButtonFormField<Frequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Tekrarlanma Sıklığı', border: OutlineInputBorder()),
                  items: Frequency.values.map((frequency) {
                    return DropdownMenuItem(value: frequency, child: Text(frequency.displayName));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedFrequency = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: _selectedFrequency == Frequency.weekly,
                  child: DropdownButtonFormField<int>(
                    value: _selectedDayOfWeek,
                    decoration: const InputDecoration(labelText: 'Haftanın Günü', border: OutlineInputBorder()),
                    items: List.generate(7, (index) {
                      return DropdownMenuItem(value: index + 1, child: Text(_weekDays[index]));
                    }),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDayOfWeek = newValue);
                      }
                    },
                  ),
                ),
                Visibility(
                  visible: _selectedFrequency == Frequency.monthly,
                  child: DropdownButtonFormField<int>(
                    value: _selectedDayOfMonth,
                    decoration: const InputDecoration(labelText: 'Ayın Günü', border: OutlineInputBorder()),
                    items: List.generate(31, (index) {
                      return DropdownMenuItem(value: index + 1, child: Text('${index + 1}'));
                    }),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDayOfMonth = newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Rutini Kaydet'),
                  onPressed: _saveRoutine,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
