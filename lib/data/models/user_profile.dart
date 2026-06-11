class UserProfile {
  final String name;
  final int heightCm;
  final double currentWeightKg;
  final bool useWeightVest;
  final double weightVestKg;
  final bool useMetricSystem;
  final List<String> selectedRoutines;

  UserProfile({
    this.name = 'User',
    required this.heightCm,
    required this.currentWeightKg,
    required this.useWeightVest,
    required this.weightVestKg,
    this.useMetricSystem = true,
    this.selectedRoutines = const ['chest_arms', 'shoulders_back', 'legs'],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'User',
      heightCm: json['height_cm'] as int,
      currentWeightKg: (json['current_weight_kg'] as num).toDouble(),
      useWeightVest: json['use_weight_vest'] as bool,
      weightVestKg: (json['weight_vest_kg'] as num).toDouble(),
      useMetricSystem: json['use_metric_system'] as bool? ?? true,
      selectedRoutines: (json['selected_routines'] as List?)?.map((e) => e as String).toList() ?? ['chest_arms', 'shoulders_back', 'legs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'use_weight_vest': useWeightVest,
      'weight_vest_kg': weightVestKg,
      'use_metric_system': useMetricSystem,
      'selected_routines': selectedRoutines,
    };
  }

  UserProfile copyWith({
    String? name,
    int? heightCm,
    double? currentWeightKg,
    bool? useWeightVest,
    double? weightVestKg,
    bool? useMetricSystem,
    List<String>? selectedRoutines,
  }) {
    return UserProfile(
      name: name ?? this.name,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      useWeightVest: useWeightVest ?? this.useWeightVest,
      weightVestKg: weightVestKg ?? this.weightVestKg,
      useMetricSystem: useMetricSystem ?? this.useMetricSystem,
      selectedRoutines: selectedRoutines ?? this.selectedRoutines,
    );
  }
}

class ExerciseWeights {
  final double floorPress;
  final double militaryPress;
  final double supinatingCurl;
  final double crossHammer;
  final double chairKickback;
  final double uprightRow;
  final double shrug;
  final double rearFlye;
  final double gobletSquat;
  final double romanianDeadlift;
  final double splitSquat;
  final double calfRaise;

  ExerciseWeights({
    required this.floorPress,
    required this.militaryPress,
    required this.supinatingCurl,
    required this.crossHammer,
    required this.chairKickback,
    required this.uprightRow,
    required this.shrug,
    required this.rearFlye,
    required this.gobletSquat,
    required this.romanianDeadlift,
    required this.splitSquat,
    required this.calfRaise,
  });

  factory ExerciseWeights.fromJson(Map<String, dynamic> json) {
    return ExerciseWeights(
      floorPress: (json['floor_press'] as num?)?.toDouble() ?? 8.0,
      militaryPress: (json['military_press'] as num?)?.toDouble() ?? 8.0,
      supinatingCurl: (json['supinating_curl'] as num?)?.toDouble() ?? 8.0,
      crossHammer: (json['cross_hammer'] as num?)?.toDouble() ?? 8.0,
      chairKickback: (json['chair_kickback'] as num?)?.toDouble() ?? 8.0,
      uprightRow: (json['upright_row'] as num?)?.toDouble() ?? 8.0,
      shrug: (json['shrug'] as num?)?.toDouble() ?? 8.0,
      rearFlye: (json['rear_flye'] as num?)?.toDouble() ?? 8.0,
      gobletSquat: (json['goblet_squat'] as num?)?.toDouble() ?? 8.0,
      romanianDeadlift: (json['romanian_deadlift'] as num?)?.toDouble() ?? 8.0,
      splitSquat: (json['split_squat'] as num?)?.toDouble() ?? 8.0,
      calfRaise: (json['calf_raise'] as num?)?.toDouble() ?? 8.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floor_press': floorPress,
      'military_press': militaryPress,
      'supinating_curl': supinatingCurl,
      'cross_hammer': crossHammer,
      'chair_kickback': chairKickback,
      'upright_row': uprightRow,
      'shrug': shrug,
      'rear_flye': rearFlye,
      'goblet_squat': gobletSquat,
      'romanian_deadlift': romanianDeadlift,
      'split_squat': splitSquat,
      'calf_raise': calfRaise,
    };
  }

  double getWeightForExercise(String exerciseId) {
    switch (exerciseId) {
      case 'floor_press': return floorPress;
      case 'military_press': return militaryPress;
      case 'supinating_curl': return supinatingCurl;
      case 'cross_hammer': return crossHammer;
      case 'chair_kickback': return chairKickback;
      case 'upright_row': return uprightRow;
      case 'shrug': return shrug;
      case 'rear_flye': return rearFlye;
      case 'goblet_squat': return gobletSquat;
      case 'romanian_deadlift': return romanianDeadlift;
      case 'split_squat': return splitSquat;
      case 'calf_raise': return calfRaise;
      default: return 8.0;
    }
  }

  ExerciseWeights copyWithExercise(String exerciseId, double newWeight) {
    return ExerciseWeights(
      floorPress: exerciseId == 'floor_press' ? newWeight : floorPress,
      militaryPress: exerciseId == 'military_press' ? newWeight : militaryPress,
      supinatingCurl: exerciseId == 'supinating_curl' ? newWeight : supinatingCurl,
      crossHammer: exerciseId == 'cross_hammer' ? newWeight : crossHammer,
      chairKickback: exerciseId == 'chair_kickback' ? newWeight : chairKickback,
      uprightRow: exerciseId == 'upright_row' ? newWeight : uprightRow,
      shrug: exerciseId == 'shrug' ? newWeight : shrug,
      rearFlye: exerciseId == 'rear_flye' ? newWeight : rearFlye,
      gobletSquat: exerciseId == 'goblet_squat' ? newWeight : gobletSquat,
      romanianDeadlift: exerciseId == 'romanian_deadlift' ? newWeight : romanianDeadlift,
      splitSquat: exerciseId == 'split_squat' ? newWeight : splitSquat,
      calfRaise: exerciseId == 'calf_raise' ? newWeight : calfRaise,
    );
  }
}

class UserData {
  final UserProfile profile;
  final ExerciseWeights weights;

  UserData({
    required this.profile,
    required this.weights,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      profile: UserProfile.fromJson(json['user_profile'] as Map<String, dynamic>),
      weights: ExerciseWeights.fromJson(json['current_weights_kg'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_profile': profile.toJson(),
      'current_weights_kg': weights.toJson(),
    };
  }
}
