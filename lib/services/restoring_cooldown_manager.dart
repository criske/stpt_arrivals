import 'package:shared_preferences/shared_preferences.dart';

abstract class RestoringCoolDownManager {
  Future<int> loadLastCoolDown();

  Future<void> retainLastCoolDown(int timeMillis);
}

class RestoringCoolDownManagerImpl implements RestoringCoolDownManager {
  static const _restoringCoolDownKey = "RESTORING_COOLDOWN_KEY";

  @override
  Future<int> loadLastCoolDown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_restoringCoolDownKey) ?? 0;
  }

  @override
  Future<void> retainLastCoolDown(int timeMillis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restoringCoolDownKey, timeMillis);
  }
}
