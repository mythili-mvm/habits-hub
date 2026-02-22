import 'package:flutter/material.dart';
import '../core/notification_service.dart';
import '../models/habit.dart';
import 'add_habit_screen.dart';
import 'package:hive/hive.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Habit> habitBox;
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    habitBox = Hive.box<Habit>('habits');
    habits = habitBox.values.toList();
    scheduleDailyReminders();

  }

  void scheduleDailyReminders() async {
    await NotificationService.scheduleDailyNotification(
      id: 1,
      hour: 9,
      minute: 0,
      title: "Good Morning 🌅",
      body: "Your habits for today are ready!",
    );

    await NotificationService.scheduleDailyNotification(
      id: 2,
      hour: 14,
      minute: 0,
      title: "Midday Check ⏳",
      body: "Check your pending habits.",
    );

    await NotificationService.scheduleDailyNotification(
      id: 3,
      hour: 19,
      minute: 0,
      title: "Evening Reminder 🌙",
      body: "Complete your habits before the day ends!",
    );
  }



  // Format today's date as string
  String getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  int calculateStreak(Habit habit) {
    int streak = 0;

    DateTime date = DateTime.now();

    while (true) {
      String key = "${date.year}-${date.month}-${date.day}";

      // If habit not scheduled that day → skip
      if (!habit.daysOfWeek.contains(date.weekday)) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }

      double value = habit.dailyProgress[key] ?? 0;

      if (value >= habit.target) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  void deleteHabit(Habit habit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Habit"),
          content: Text("Are you sure you want to delete '${habit.name}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  habit.delete();
                  habits = habitBox.values.toList();
                });
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }


  void editHabit(Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(habit: habit),
      ),
    );

    setState(() {});
  }

  List<Habit> getIncompleteHabits() {
    String todayKey = getTodayString();

    return habits.where((habit) {
      if (!habit.daysOfWeek.contains(DateTime.now().weekday)) {
        return false;
      }

      double current = habit.dailyProgress[todayKey] ?? 0;
      return current < habit.target;
    }).toList();
  }


  // Manual entry dialog
  void showManualEntryDialog(Habit habit) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update ${habit.name}"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter value"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);

                if (value != null) {
                  setState(() {
                    String today = getTodayString();
                    habit.dailyProgress[today] = value;
                    habit.save();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int today = DateTime.now().weekday;

    final todayHabits = habits.where((habit) {
      return habit.daysOfWeek.contains(today);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Today")),

      body: todayHabits.isEmpty
          ? const Center(child: Text("No habits for today"))
          : ListView.builder(
              itemCount: todayHabits.length,
              itemBuilder: (context, index) {
                final habit = todayHabits[index];
                String todayKey = getTodayString();

                double currentValue = habit.dailyProgress[todayKey] ?? 0;

                double progress = (currentValue / habit.target).clamp(0.0, 1.0);

                int streak = calculateStreak(habit);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Name + Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            Row(
                              children: [

                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20, color: Colors.red),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () {
                                    setState(() {
                                      if (currentValue > 0) {
                                        habit.dailyProgress[todayKey] = currentValue - 1;
                                        habit.save();
                                      }
                                    });
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(Icons.add, size: 20, color: Colors.green),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () {
                                    setState(() {
                                      habit.dailyProgress[todayKey] = currentValue + 1;
                                      habit.save();
                                    });
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () {
                                    showManualEntryDialog(habit);
                                  },
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == "edit") {
                                      editHabit(habit);
                                    } else if (value == "delete") {
                                      deleteHabit(habit);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: "edit",
                                      child: Text("Edit Habit"),
                                    ),
                                    const PopupMenuItem(
                                      value: "delete",
                                      child: Text("Delete Habit"),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          ],
                        ),

                        const SizedBox(height: 6),

                        // Progress Text
                        Text(
                          "$currentValue / ${habit.target} ${habit.unit}",
                          style: TextStyle(
                            fontSize: 14,
                            color: progress >= 1 ? Colors.green : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Smaller Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6, // 👈 reduced height
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              color: progress >= 1 ? Colors.green : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (streak > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "🔥 Streak: $streak day${streak > 1 ? 's' : ''}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHabitScreen()),
          );

          if (result != null && result is Habit) {
            setState(() {
              habitBox.add(result);
              habits = habitBox.values.toList();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
