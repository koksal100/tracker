
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  Future<void> _saveTheme(ThemeMode mode) async {
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
            subtitle: Text(themeMode == ThemeMode.dark ? 'Karanlık Mod' : 'Aydınlık Mod'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                final newMode = value ? ThemeMode.dark : ThemeMode.light;
                onThemeModeChanged(newMode);
                _saveTheme(newMode);
              },
            ),
          ),
        ],
      ),
    );
  }
}
