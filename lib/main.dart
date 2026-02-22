import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'screens/home_screen.dart';
import 'core/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await NotificationService.init();

  Hive.registerAdapter(HabitAdapter());

  await Hive.openBox<Habit>('habits');

  runApp(const HabitHub());
}

class HabitHub extends StatelessWidget {
  const HabitHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
