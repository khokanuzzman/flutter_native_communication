import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "method_channel_ios", binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
            if call.method == "showToast" {
                // When showToast method is called from Flutter, display a toast message
                if let args = call.arguments as? [String: Any], let message = args["message"] as? String {
                    self?.showToast(message:message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
            }else if call.method == "showNotification" {
                print("working...")
                if let args = call.arguments as? [String: Any], let message = args["message"] as? String {
                    print(message)
                    self?.showNotification(message: message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
            }
            else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Request notification permissions
              UNUserNotificationCenter.current().delegate = self
              requestNotificationPermission()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Function to display a toast message
    private func showToast(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        window?.rootViewController?.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alertController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // Method to show notification
    private func showNotification(message: String) {
        // Define the custom actions.
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
              title: "Accept",
              options: [])
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
              title: "Decline",
              options: [])
        // Define the notification type
        
        // Define the category
        let category = UNNotificationCategory(identifier: "MEETING_INVITATION",
                                              actions: [acceptAction, declineAction],
                                              intentIdentifiers: [],
                                              hiddenPreviewsBodyPlaceholder: "",
                                              options: .customDismissAction)
        
        
        // Register the category with the notification center
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let content = UNMutableNotificationContent()
        content.title = "Notification"
        content.body = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MEETING_INVITATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification request: \(error.localizedDescription)")
            } else {
                print("Notification request added successfully")
            }
        }
    }
    
    // Handle tap on notification when the app is in the foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
