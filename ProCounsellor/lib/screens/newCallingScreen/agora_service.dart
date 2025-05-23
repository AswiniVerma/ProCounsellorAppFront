import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/services/api_utils.dart';

class AgoraService {
  static const String baseUrl = "${ApiUtils.baseUrl}/api/agora";

  static Future<String?> fetchAgoraToken(String channelName, int uid) async {
    final response = await http.get(
      Uri.parse("$baseUrl/token?channelName=$channelName&uid=$uid"),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return null;
    }
  }

  static Future<void> endCall(String callId) async {
    await http.post(Uri.parse("$baseUrl/$callId/end"));
  }
  
  static Future<void> declinedCall(String callId, String receiverId) async {
    FirebaseDatabase.instance.ref("agora_call_signaling").child(receiverId).remove();
    await http.post(Uri.parse("$baseUrl/$callId/declined"));
  }

  static Future<void> pickedCall(String callId) async {
    await http.post(Uri.parse("$baseUrl/$callId/picked"));
  }
}
