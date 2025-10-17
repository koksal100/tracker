
import 'package:flutter/material.dart';

class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Görevler'),
      ),
      body: const Center(
        child: Text('Tüm görevler burada gösterilecek.'),
      ),
    );
  }
}
