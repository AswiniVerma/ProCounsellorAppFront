import UIKit
import Flutter
import Firebase
import UserNotifications
import PushKit
import flutter_callkit_incoming
import FirebaseFirestore

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    // Register for VoIP PushKit
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle foreground notification display
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    print("📱 VoIP Token: \(deviceToken)")

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)

    let userDefaults = UserDefaults.standard
    userDefaults.set(deviceToken, forKey: "flutter.cached_voip_token")
  }


  // ✅ PushKit: Invalidate Token
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    print("🔕 VoIP token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }
  
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let dictionary = payload.dictionaryPayload

    // 🔍 Check for call cancellation
    if let pushType = dictionary["type"] as? String, pushType == "cancel_call" {
        print("📴 VoIP Push: Cancel call received via PushKit")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        completion()
        return
    }

    // 🟢 Incoming call - proceed as usual
    var info = [String: Any?]()
    info["id"] = dictionary["id"] ?? UUID().uuidString
    info["nameCaller"] = dictionary["nameCaller"] ?? "Unknown"
    info["handle"] = dictionary["handle"] ?? "Caller"
    info["type"] = dictionary["type"] ?? 0
    info["textAccept"] = dictionary["textAccept"] ?? "Answer"
    info["textDecline"] = dictionary["textDecline"] ?? "Decline"
    info["textMissedCall"] = dictionary["textMissedCall"] ?? "Missed call"
    info["textCallback"] = dictionary["textCallback"] ?? "Call back"
    info["extra"] = dictionary["extra"] ?? [:]
    info["ios"] = dictionary["ios"] ?? [
        "iconName": "CallKitIcon",
        "handleType": "generic",
        "supportsVideo": true,
        "maximumCallGroups": 2,
        "maximumCallsPerCallGroup": 1
    ]

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
        flutter_callkit_incoming.Data(args: info),
        fromPushKit: true
    )

    completion()
}
}
