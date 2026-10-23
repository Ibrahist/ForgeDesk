import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/client_settings.dart';
import '../models/remote_session.dart';

class SessionStorageService {
  static Future<List<RecentSessionItem>> loadRecentSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.keyRecentSessions);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        return list.map((item) => RecentSessionItem.fromJson(item)).toList();
      } catch (_) {}
    }

    // Default sample entries to give an immediate polished feel
    final defaultRecents = [
      RecentSessionItem(
        id: '812 491 033',
        alias: 'Office Workstation (Main)',
        lastConnected: DateTime.now().subtract(const Duration(hours: 3)),
        osType: 'Windows',
        isFavorite: true,
      ),
      RecentSessionItem(
        id: '294 105 872',
        alias: 'Homelab Linux Build Server',
        lastConnected: DateTime.now().subtract(const Duration(days: 1)),
        osType: 'Linux',
        isFavorite: false,
      ),
      RecentSessionItem(
        id: '670 918 244',
        alias: 'Design MacBook Pro',
        lastConnected: DateTime.now().subtract(const Duration(days: 4)),
        osType: 'macOS',
        isFavorite: false,
      ),
    ];
    await saveRecentSessions(defaultRecents);
    return defaultRecents;
  }

  static Future<void> saveRecentSessions(List<RecentSessionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(AppConstants.keyRecentSessions, jsonEncode(jsonList));
  }

  static Future<void> addRecentSession(RecentSessionItem newItem) async {
    final current = await loadRecentSessions();
    current.removeWhere((item) => item.id == newItem.id);
    current.insert(0, newItem);
    if (current.length > 15) {
      current.removeLast();
    }
    await saveRecentSessions(current);
  }

  static Future<ClientSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.keySettings);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final map = jsonDecode(jsonString);
        return ClientSettings.fromJson(map);
      } catch (_) {}
    }
    return ClientSettings.defaultSettings();
  }

  static Future<void> saveSettings(ClientSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySettings, jsonEncode(settings.toJson()));
  }
}
