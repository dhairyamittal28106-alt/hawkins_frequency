import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class EnergyManager {
  static const String _energyKey = 'psychic_energy';
  static const String _lastRegenKey = 'last_regen_timestamp';
  static int _energy = 100;
  static Timer? _regenTimer;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _energy = prefs.getInt(_energyKey) ?? 100;

    // Offline regeneration
    final lastTime = prefs.getInt(_lastRegenKey) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastTime) ~/ 1000;
    final regenAmount = elapsedSeconds ~/ 30;
    if (regenAmount > 0 && _energy < 100) {
      _energy = (_energy + regenAmount).clamp(0, 100);
      await _save();
    }
    await prefs.setInt(_lastRegenKey, now);

    // Periodic regeneration
    _regenTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_energy < 100) {
        _energy += 1;
        await _save();
      }
    });
  }

  static int get energy => _energy;

  static Future<void> consume(int amount) async {
    _energy = (_energy - amount).clamp(0, 100);
    await _save();
  }

  static Future<void> recharge(int amount) async {
    _energy = (_energy + amount).clamp(0, 100);
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_energyKey, _energy);
    await prefs.setInt(_lastRegenKey, DateTime.now().millisecondsSinceEpoch);
  }

  static void dispose() {
    _regenTimer?.cancel();
  }
}