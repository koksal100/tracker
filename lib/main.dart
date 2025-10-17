
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/controllers/notification_controller.dart';
import 'package:trackerapp/screens/all_tasks_screen.dart';
import 'package:trackerapp/screens/home_screen.dart';
import 'package:trackerapp/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Initialize Notification Controller
  await NotificationController.initializeLocalNotifications();
  await NotificationController.requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 0; // Default to light (index 0)
  themeNotifier.value = ThemeMode.values[themeIndex];
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
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
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              secondary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
              background: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: Colors.grey.shade200, // Unselected background
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
              background: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodTextColor: Colors.white,
              dayPeriodColor: Colors.black, // Unselected background
            ),
            useMaterial3: true,
          ),
          themeMode: currentMode,
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
