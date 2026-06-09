import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final File? overrideFile;

  ProfileRepository({this.overrideFile});

  Future<File> get _localFile async {
    if (overrideFile != null) return overrideFile!;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/user_profile.json');
  }

  Future<bool> profileExists() async {
    try {
      final file = await _localFile;
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<UserData?> loadProfile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonMap = jsonDecode(contents) as Map<String, dynamic>;
        return UserData.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfile(UserData data) async {
    final file = await _localFile;
    final jsonString = jsonEncode(data.toJson());
    await file.writeAsString(jsonString);
  }
}
