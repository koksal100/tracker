import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Tüm Görevler'),
      body: const Center(
        child: Text('Tüm görevler burada gösterilecek.'),
      ),
    );
  }
}