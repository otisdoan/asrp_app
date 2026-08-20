import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Top-level function dùng cho compute() để parse JSON trong Background Isolate
List<Map<String, dynamic>> _parseChatHistoryJson(String jsonString) {
  final List<dynamic> decodedList = jsonDecode(jsonString);
  return decodedList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

class ChatStorageService {
  static const String _prefix = 'chat_history_';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  /// Lưu trữ toàn bộ lịch sử chat kèm metadata UI (hóa đơn, mã QR, vé đã thanh toán, v.v.)
  Future<void> saveChatHistory(String sessionId, List<Map<String, dynamic>> messages) async {
    final key = '$_prefix$sessionId';
    try {
      final jsonString = jsonEncode(messages);
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      print('[ChatStorageService] Lỗi mã hóa JSON khi lưu Chat History: $e');
    }
  }

  /// Khôi phục lịch sử chat từ Local Storage thông qua Background Isolate (compute)
  Future<List<Map<String, dynamic>>?> loadChatHistory(String sessionId) async {
    final key = '$_prefix$sessionId';
    final jsonString = await _storage.read(key: key);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return await compute(_parseChatHistoryJson, jsonString);
      } catch (e) {
        print('[ChatStorageService] Lỗi giải mã JSON Chat History: $e');
        return null;
      }
    }
    return null;
  }

  /// Xóa bộ nhớ đệm của một session cụ thể
  Future<void> clearChatHistory(String sessionId) async {
    final key = '$_prefix$sessionId';
    await _storage.delete(key: key);
  }
}
