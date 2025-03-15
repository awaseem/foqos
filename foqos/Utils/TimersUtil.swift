import Foundation
import UserNotifications

enum NotificationResult {
    case success
    case failure(Error?)
    
    var succeeded: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

class TimersUtil {

    init() {}

    @discardableResult
    func executeAfterDelay(
        seconds: TimeInterval, completion: @escaping () -> Void
    ) -> UUID {
        let taskId = UUID()

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }

        return taskId
    }

    @discardableResult
    func scheduleNotification(
        title: String,
        message: String,
        seconds: TimeInterval,
        identifier: String? = nil,
        completion: @escaping (NotificationResult) -> Void = { _ in }
    ) -> String {
        let notificationId = identifier ?? UUID().uuidString

        // Request authorization before scheduling
        requestNotificationAuthorization { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success:
                // Proceed with scheduling the notification
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = message
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: seconds, repeats: false)
                let request = UNNotificationRequest(
                    identifier: notificationId, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print(
                            "Error scheduling notification: \(error.localizedDescription)"
                        )
                        completion(.failure(error))
                    } else {
                        completion(.success)
                    }
                }
            }
        }

        return notificationId
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    private func requestNotificationAuthorization(
        completion: @escaping (NotificationResult) -> Void = { _ in }
    ) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) {
            granted, error in
            if let error = error {
                print(
                    "Error requesting notification authorization: \(error.localizedDescription)"
                )
                completion(.failure(error))
                return
            }

            if granted {
                print("Notification authorization granted")
                completion(.success)
            } else {
                print("Notification authorization denied")
                completion(.failure(nil))
            }
        }
    }
}
