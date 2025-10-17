
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Uygulama Teması'),
            subtitle: Text(themeMode == ThemeMode.dark ? 'Karanlık Mod' : 'Aydınlık Mod'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                onThemeModeChanged(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
        ],
      ),
    );
  }
}

