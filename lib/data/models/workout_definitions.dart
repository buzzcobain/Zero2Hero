class ExerciseDefinition {
  final String id;
  final String name;
  final String focus;
  final int restSeconds;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.focus,
    required this.restSeconds,
  });

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) {
    return ExerciseDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      focus: json['focus'] as String,
      restSeconds: json['rest_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'rest_seconds': restSeconds,
    };
  }
}

class WorkoutDefinition {
  final String title;
  final List<ExerciseDefinition> exercises;

  const WorkoutDefinition({
    required this.title,
    required this.exercises,
  });

  factory WorkoutDefinition.fromJson(Map<String, dynamic> json) {
    return WorkoutDefinition(
      title: json['title'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutRoutines {
  static const WorkoutDefinition workoutA = WorkoutDefinition(
    title: 'Chest & Arms',
    exercises: [
      ExerciseDefinition(id: 'floor_press', name: 'Dumbbell Floor Press', focus: 'Pecs & Triceps', restSeconds: 60),
      ExerciseDefinition(id: 'supinating_curl', name: 'Supinating Bicep Curl', focus: 'Biceps', restSeconds: 45),
      ExerciseDefinition(id: 'cross_hammer', name: 'Cross-Body Hammer Curl', focus: 'Biceps & Forearms (Width)', restSeconds: 45),
      ExerciseDefinition(id: 'chair_kickback', name: 'Dining Chair Kickback', focus: 'Triceps', restSeconds: 45),
    ],
  );

  static const WorkoutDefinition workoutB = WorkoutDefinition(
    title: 'Shoulders & Upper Back',
    exercises: [
      ExerciseDefinition(id: 'military_press', name: 'Standing Military Press', focus: 'Shoulders & Upper Chest', restSeconds: 60),
      ExerciseDefinition(id: 'upright_row', name: 'Dumbbell Upright Row', focus: 'Traps & Side Shoulders', restSeconds: 45),
      ExerciseDefinition(id: 'shrug', name: 'Dumbbell Shrug', focus: 'Traps', restSeconds: 45),
      ExerciseDefinition(id: 'rear_flye', name: 'Bent-Over Rear Delt Flye', focus: 'Rear Shoulders & Upper Back', restSeconds: 45),
    ],
  );

  static const WorkoutDefinition workoutC = WorkoutDefinition(
    title: 'Legs & Glutes',
    exercises: [
      ExerciseDefinition(id: 'goblet_squat', name: 'Goblet Squat', focus: 'Quads & Glutes', restSeconds: 60),
      ExerciseDefinition(id: 'romanian_deadlift', name: 'Romanian Deadlift', focus: 'Hamstrings & Glutes', restSeconds: 60),
      ExerciseDefinition(id: 'split_squat', name: 'Bulgarian Split Squat', focus: 'Quads & Glutes', restSeconds: 45),
      ExerciseDefinition(id: 'calf_raise', name: 'Standing Calf Raise', focus: 'Calves', restSeconds: 45),
    ],
  );

  static WorkoutDefinition getById(String id) {
    if (id == 'Workout A' || id == 'A' || id == 'Chest & Arms' || id == 'chest_arms') {
      return workoutA;
    } else if (id == 'Workout B' || id == 'B' || id == 'Shoulders & Upper Back' || id == 'shoulders_back') {
      return workoutB;
    } else {
      return workoutC;
    }
  }
}
