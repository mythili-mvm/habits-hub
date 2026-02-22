import 'package:flutter/material.dart';
import '../models/habit.dart';


class AddHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddHabitScreen({super.key,this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {

  @override
  void initState() {
    super.initState();

    if (widget.habit != null) {
      nameController.text = widget.habit!.name;
      targetController.text = widget.habit!.target.toString();
      unitController.text = widget.habit!.unit;
      selectedDays = List.from(widget.habit!.daysOfWeek);
    }
  }


  final nameController = TextEditingController();
  final targetController = TextEditingController();
  final unitController = TextEditingController();

  String repeatOption = "Daily";
  List<int> selectedDays = [1,2,3,4,5,6,7];


  String selectedType = "Count";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Habit"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Habit Name",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Target",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: "Unit (liters, km, pages, times)",
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: repeatOption,
              decoration: const InputDecoration(
                labelText: "Repeat",
                border: OutlineInputBorder(),
              ),
              items: ["Daily", "Weekdays", "Weekends", "Custom"]
                  .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  repeatOption = value!;

                  if (repeatOption == "Daily") {
                    selectedDays = [1,2,3,4,5,6,7];
                  } else if (repeatOption == "Weekdays") {
                    selectedDays = [1,2,3,4,5];
                  } else if (repeatOption == "Weekends") {
                    selectedDays = [6,7];
                  } else {
                    selectedDays = [];
                  }
                });
              },
            ),

            if (repeatOption == "Custom")
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  int day = index + 1;
                  List<String> dayNames = [
                    "Mon","Tue","Wed","Thu","Fri","Sat","Sun"
                  ];

                  return FilterChip(
                    label: Text(dayNames[index]),
                    selected: selectedDays.contains(day),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final targetValue = double.tryParse(targetController.text);

                if (nameController.text.isEmpty ||
                    unitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fill all fields")),
                  );
                  return;
                }

                if (targetValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter valid number")),
                  );
                  return;
                }

                if (widget.habit != null) {
                  // Editing existing habit
                  widget.habit!.name = nameController.text;
                  widget.habit!.target = targetValue;
                  widget.habit!.unit = unitController.text;
                  widget.habit!.daysOfWeek = selectedDays;

                  await widget.habit!.save();

                  Navigator.pop(context);
                } else {
                  final newHabit = Habit(
                    name: nameController.text,
                    target: targetValue,
                    unit: unitController.text,
                    daysOfWeek: selectedDays,
                    dailyProgress: {},
                  );

                  Navigator.pop(context, newHabit);
                }
              },
              child: const Text("Save"),
            )



          ],
        ),
      ),
    );
  }
}
