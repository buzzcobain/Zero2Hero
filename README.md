# Progressive Dumbbell Tracker (Zero2Hero)

A 100% offline, local-first Flutter application for tracking dumbbell progressions using scientific stage progression rules and the MET energy expenditure engine.

## Core Features
1. **Offline State**: All user profile, weight tracking, and progress logs are saved locally in the device's secure document directory.
2. **Onboarding Questionnaire**: Set your height, weight, and initial weight for 8 key exercises.
3. **Alternating A/B Workouts**:
   * **Workout A**: Chest & Arms (Floor Press, Supinating Curl, Cross Hammer, Chair Kickback)
   * **Workout B**: Shoulders & Upper Back (Military Press, Upright Row, Shrug, Rear Flye)
4. **Haptic Rest Countdown Timer**: Automatic timer triggered when checking completed sets, featuring haptic feedback and zero-touch return to training.
5. **Friday Transformation Vault**: Overlay baseline photos at 50% opacity to ensure consistency week-over-week. Compile progress images into a timelapse progress video.
6. **MET Calorie Engine**: Mathematical energy calculation based on workout duration, user weight, and weighted vest usage.
7. **Mockable AdMob Suite**: AdMob Banner, Interstitial, and Rewarded Interstitial implementations wrapped in interfaces for flawless local testing and coverage validation.

## Development & Testing
- Target Code Coverage: >=90%
- Framework: Flutter (Dart) with BLoC/Cubit state management.
