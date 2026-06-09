class UserProfile {
  final int heightCm;
  final double currentWeightKg;
  final bool useWeightVest;
  final double weightVestKg;

  UserProfile({
    required this.heightCm,
    required this.currentWeightKg,
    required this.useWeightVest,
    required this.weightVestKg,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      heightCm: json['height_cm'] as int,
      currentWeightKg: (json['current_weight_kg'] as num).toDouble(),
      useWeightVest: json['use_weight_vest'] as bool,
      weightVestKg: (json['weight_vest_kg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'use_weight_vest': useWeightVest,
      'weight_vest_kg': weightVestKg,
    };
  }

  UserProfile copyWith({
    int? heightCm,
    double? currentWeightKg,
    bool? useWeightVest,
    double? weightVestKg,
  }) {
    return UserProfile(
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      useWeightVest: useWeightVest ?? this.useWeightVest,
      weightVestKg: weightVestKg ?? this.weightVestKg,
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

  ExerciseWeights({
    required this.floorPress,
    required this.militaryPress,
    required this.supinatingCurl,
    required this.crossHammer,
    required this.chairKickback,
    required this.uprightRow,
    required this.shrug,
    required this.rearFlye,
  });

  factory ExerciseWeights.fromJson(Map<String, dynamic> json) {
    return ExerciseWeights(
      floorPress: (json['floor_press'] as num).toDouble(),
      militaryPress: (json['military_press'] as num).toDouble(),
      supinatingCurl: (json['supinating_curl'] as num).toDouble(),
      crossHammer: (json['cross_hammer'] as num).toDouble(),
      chairKickback: (json['chair_kickback'] as num).toDouble(),
      uprightRow: (json['upright_row'] as num).toDouble(),
      shrug: (json['shrug'] as num).toDouble(),
      rearFlye: (json['rear_flye'] as num).toDouble(),
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
