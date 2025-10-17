
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/main.dart'; // Import main.dart to access AppThemeMode
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  Future<void> _saveTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Ayarlar'),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Uygulama Teması'),
            trailing: DropdownButton<AppThemeMode>(
              value: themeMode,
              onChanged: (AppThemeMode? newValue) {
                if (newValue != null) {
                  onThemeModeChanged(newValue);
                  _saveTheme(newValue);
                }
              },
              items: AppThemeMode.values.map<DropdownMenuItem<AppThemeMode>>((AppThemeMode mode) {
                return DropdownMenuItem<AppThemeMode>(
                  value: mode,
                  child: Text(mode.displayName),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
