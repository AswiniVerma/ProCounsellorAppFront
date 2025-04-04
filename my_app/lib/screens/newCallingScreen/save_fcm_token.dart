import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_notification_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

 // ✅ Save or Update FCM Token Only If User is Authenticated
  static Future<void> saveFCMTokenUser(String userId) async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      print("❌ User not authenticated. Cannot save FCM Token.");
      return;
    }

    String? token = await FirebaseNotificationService.getFCMToken();
    if (token != null) {
      // ✅ Use set() with merge:true to create or update the field dynamically
      await _firestore.collection("users").doc(userId).set(
        {"fcmToken": token}, 
        SetOptions(merge: true), // 🔥 Ensures other fields remain unchanged
      );
      print("✅ FCM Token Updated for user: $userId → Token: $token");
    } else {
      print("❌ Failed to retrieve FCM Token.");
    }
  }

  // ✅ Get Receiver's FCM Token
  static Future<String?> getFCMTokenUser(String receiverId) async {
    DocumentSnapshot doc = await _firestore.collection("users").doc(receiverId).get();
    return doc.exists ? doc["fcmToken"] : null;
  }

    // ✅ Save or Update FCM Token Only If User is Authenticated
  static Future<void> saveFCMTokenCounsellor(String userId) async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      print("❌ User not authenticated. Cannot save FCM Token.");
      return;
    }

    String? token = await FirebaseNotificationService.getFCMToken();
    if (token != null) {
      // ✅ Use set() with merge:true to create or update the field dynamically
      await _firestore.collection("counsellors").doc(userId).set(
        {"fcmToken": token}, 
        SetOptions(merge: true), // 🔥 Ensures other fields remain unchanged
      );
      print("✅ FCM Token Updated for user: $userId → Token: $token");
    } else {
      print("❌ Failed to retrieve FCM Token.");
    }
  }

  // ✅ Get Receiver's FCM Token
  static Future<String?> getFCMTokenCounsellor(String receiverId) async {
    DocumentSnapshot doc = await _firestore.collection("counsellors").doc(receiverId).get();
    return doc.exists ? doc["fcmToken"] : null;
  }
}
