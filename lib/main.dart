
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/controllers/notification_controller.dart';
import 'package:trackerapp/screens/all_tasks_screen.dart';
import 'package:trackerapp/screens/home_screen.dart';
import 'package:trackerapp/screens/settings_screen.dart';
import 'package:trackerapp/utils/app_colors.dart';

enum AppThemeMode {
  light,
  dark,
  lemon,
  tulip,
  cake,
  ocean,
  forest,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Aydınlık Mod';
      case AppThemeMode.dark:
        return 'Karanlık Mod';
      case AppThemeMode.lemon:
        return 'Limon Teması';
      case AppThemeMode.tulip:
        return 'Lale Teması';
      case AppThemeMode.cake:
        return 'Pasta Teması';
      case AppThemeMode.ocean:
        return 'Okyanus Teması';
      case AppThemeMode.forest:
        return 'Orman Teması';
    }
  }
}

ThemeData _buildTheme(AppThemeMode mode) {
  ColorScheme colorScheme;
  Brightness brightness;
  TimePickerThemeData timePickerTheme;

  switch (mode) {
    case AppThemeMode.light:
      brightness = Brightness.light;
      colorScheme = AppColors.lightColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.dark:
      brightness = Brightness.dark;
      colorScheme = AppColors.darkColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.lemon:
      brightness = Brightness.light;
      colorScheme = AppColors.lemonColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.tulip:
      brightness = Brightness.light;
      colorScheme = AppColors.tulipColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.cake:
      brightness = Brightness.light;
      colorScheme = AppColors.cakeColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.ocean:
      brightness = Brightness.light;
      colorScheme = AppColors.oceanColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
    case AppThemeMode.forest:
      brightness = Brightness.dark; // Forest theme can be dark
      colorScheme = AppColors.forestColorScheme;
      timePickerTheme = TimePickerThemeData(
        dayPeriodTextColor: colorScheme.onSurface,
        dayPeriodColor: colorScheme.surfaceVariant,
      );
      break;
  }

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    timePickerTheme: timePickerTheme,
    useMaterial3: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Initialize Notification Controller
  await NotificationController.initializeLocalNotifications();
  await NotificationController.requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? AppThemeMode.light.index;
  themeNotifier.value = AppThemeMode.values[themeIndex];
  runApp(const MyApp());
}

final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(AppThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Görev Takip',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
          ],
          theme: _buildTheme(currentMode),
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Add a listener to rebuild the widget when the theme changes.
    themeNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the options list on every build to pass the latest themeMode.
    final List<Widget> _widgetOptions = <Widget>[
      const HomeScreen(),
      const AllTasksScreen(),
      SettingsScreen(
        themeMode: themeNotifier.value,
        onThemeModeChanged: (newMode) {
          themeNotifier.value = newMode;
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Haftalık Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Tüm Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
