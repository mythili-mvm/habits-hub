import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {

  @HiveField(0)
  String name;

  @HiveField(1)
  double target;

  @HiveField(2)
  String unit;

  @HiveField(3)
  List<int> daysOfWeek;

  @HiveField(4)
  Map<String, double> dailyProgress;

  Habit({
    required this.name,
    required this.target,
    required this.unit,
    required this.daysOfWeek,
    required this.dailyProgress,
  });
}
