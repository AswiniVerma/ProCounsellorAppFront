import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/services/api_utils.dart';

class FirebaseNotificationService {
  static const String backendUrl = "${ApiUtils.baseUrl}/api/agora";

   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ✅ Get FCM Token for Current Device/User
  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // ✅ Send Notification via Backend API
  static Future<void> sendCallNotification({
    required String receiverFCMToken,
    required String senderName,
    required String channelId,
    required String receiverId,
    required String callType
  }) async {
    final response = await http.post(
      Uri.parse("$backendUrl/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "receiverFCMToken": receiverFCMToken,
        "senderName": senderName,
        "channelId": channelId,
        "receiverId": receiverId,
        "callType": callType
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Call notification sent successfully!");
    } else {
      print("❌ Failed to send notification: ${response.body}");
    }
  }
}
