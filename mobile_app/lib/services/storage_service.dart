import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _reportsBox = 'symptom_reports';
  static const String _settingsBox = 'settings';
  static const String _chatSessionsBox = 'chat_sessions';

  static Future<void> init() async {
    await Hive.openBox(_reportsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_chatSessionsBox);
  }

  // Save symptom report
  static Future<void> saveReport(Map<String, dynamic> report) async {
    final box = Hive.box(_reportsBox);
    await box.add(report);
  }

  // Get all reports
  static List<Map<String, dynamic>> getAllReports() {
    final box = Hive.box(_reportsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Save settings
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  // Get setting
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await Hive.box(_reportsBox).clear();
  }

  // ========== Chat Session Methods ==========

  // Save or update a chat session
  static Future<void> saveChatSession(ChatSession session) async {
    final box = Hive.box(_chatSessionsBox);
    await box.put(session.id, session.toJson());
  }

  // Get all chat sessions (sorted by last updated, newest first)
  static List<ChatSession> getAllChatSessions() {
    final box = Hive.box(_chatSessionsBox);
    final sessions = box.values
        .map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Sort by last updated date (newest first)
    sessions.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return sessions;
  }

  // Get a specific chat session by ID
  static ChatSession? getChatSession(String id) {
    final box = Hive.box(_chatSessionsBox);
    final data = box.get(id);
    if (data == null) return null;
    return ChatSession.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // Delete a chat session
  static Future<void> deleteChatSession(String id) async {
    final box = Hive.box(_chatSessionsBox);
    await box.delete(id);
  }

  // Clear all chat sessions
  static Future<void> clearAllChatSessions() async {
    await Hive.box(_chatSessionsBox).clear();
  }

  // Get active chat session
  static ChatSession? getActiveChatSession() {
    final sessions = getAllChatSessions();
    try {
      return sessions.firstWhere((s) => s.isActive);
    } catch (e) {
      return null;
    }
  }

  // Deactivate all sessions
  static Future<void> deactivateAllSessions() async {
    final box = Hive.box(_chatSessionsBox);
    final sessions = getAllChatSessions();

    for (var session in sessions) {
      if (session.isActive) {
        final updated = session.copyWith(isActive: false);
        await box.put(session.id, updated.toJson());
      }
    }
  }
}
