import BackgroundTasks
import Foundation
import UserNotifications

// MARK: - Notification Constants
extension Notification.Name {
    fileprivate static let backgroundTaskExecuted = Notification.Name(
        "BackgroundTaskExecuted")
}

/// Represents the result of a notification request
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
    // Constants for background task identifiers
    static let backgroundProcessingTaskIdentifier =
    "com.foqos.backgroundprocessing"
    static let backgroundTaskUserDefaultsKey = "com.foqos.backgroundtasks"
    
    private var backgroundTasks: [String: [String: Any]] {
        get {
            UserDefaults.standard.dictionary(
                forKey: Self.backgroundTaskUserDefaultsKey)
            as? [String: [String: Any]] ?? [:]
        }
        set {
            UserDefaults.standard.set(
                newValue, forKey: Self.backgroundTaskUserDefaultsKey)
        }
    }
    
    // Register background tasks with the system - call this in app launch
    static func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundProcessingTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Self.handleBackgroundProcessingTask(processingTask)
        }
    }
    
    private static func handleBackgroundProcessingTask(_ task: BGProcessingTask)
    {
        let timerUtil = TimersUtil()
        
        // Get all pending tasks from UserDefaults
        let tasks = timerUtil.backgroundTasks
        var completedTaskIds: [String] = []
        var hasExecutedTasks = false
        
        for (taskId, taskInfo) in tasks {
            if let executionTime = taskInfo["executionTime"] as? Date,
               executionTime <= Date()
            {
                // Task is due for execution
                if let notificationId = taskInfo["notificationId"] as? String {
                    // This was a notification task, we can cancel it as the system will handle it
                    timerUtil.cancelNotification(identifier: notificationId)
                }
                
                // Execute any custom code via notification callback
                NotificationCenter.default.post(
                    name: .backgroundTaskExecuted,
                    object: nil,
                    userInfo: ["taskId": taskId])
                
                completedTaskIds.append(taskId)
                hasExecutedTasks = true
            }
        }
        
        // Remove completed tasks
        var updatedTasks = tasks
        for taskId in completedTaskIds {
            updatedTasks.removeValue(forKey: taskId)
        }
        timerUtil.backgroundTasks = updatedTasks
        
        // Schedule next background task if needed
        if !updatedTasks.isEmpty {
            timerUtil.scheduleBackgroundProcessing()
        }
        
        task.setTaskCompleted(success: hasExecutedTasks)
    }
    
    // Schedule a background processing task
    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(
            identifier: Self.backgroundProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        // Find the earliest task execution time
        var earliestDate: Date?
        for (_, taskInfo) in backgroundTasks {
            if let executionTime = taskInfo["executionTime"] as? Date {
                if earliestDate == nil || executionTime < earliestDate! {
                    earliestDate = executionTime
                }
            }
        }
        
        // Set the earliest start date if there's a pending task
        if let earliestDate = earliestDate {
            request.earliestBeginDate = earliestDate
            
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule background task: \(error)")
            }
        }
    }
    
    // Cancel a specific background task
    func cancelBackgroundTask(taskId: String) {
        var tasks = backgroundTasks
        tasks.removeValue(forKey: taskId)
        backgroundTasks = tasks
    }
    
    // Cancel all background tasks
    func cancelAllBackgroundTasks() {
        backgroundTasks = [:]
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier: Self.backgroundProcessingTaskIdentifier)
    }
    
    @discardableResult
    func executeAfterDelay(
        seconds: TimeInterval, completion: @escaping () -> Void
    ) -> UUID {
        let taskId = UUID()
        
        // For short delays or when app is in foreground, use DispatchQueue
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
        
        // Also schedule as background task for resilience when app is killed
        scheduleBackgroundTask(
            taskId: taskId.uuidString,
            executionTime: Date().addingTimeInterval(seconds))
        
        // Set up notification observer for when task runs in background
        let observer = NotificationCenter.default.addObserver(
            forName: .backgroundTaskExecuted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let notificationTaskId = notification.userInfo?["taskId"]
                as? String,
               notificationTaskId == taskId.uuidString
            {
                completion()
                if let self = self {
                    NotificationCenter.default.removeObserver(
                        self,
                        name: .backgroundTaskExecuted,
                        object: nil)
                }
            }
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
                    identifier: notificationId, content: content,
                    trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print(
                            "Error scheduling notification: \(error.localizedDescription)"
                        )
                        completion(.failure(error))
                    } else {
                        // Also schedule as background task for resilience when app is killed
                        let taskId = UUID().uuidString
                        self.scheduleBackgroundTask(
                            taskId: taskId,
                            executionTime: Date().addingTimeInterval(seconds),
                            notificationId: notificationId
                        )
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
    
    func cancelAll() {
        cancelAllNotifications()
        cancelAllBackgroundTasks()
    }
    
    // Schedule a background task
    private func scheduleBackgroundTask(
        taskId: String, executionTime: Date, notificationId: String? = nil
    ) {
        // Store task information in UserDefaults
        var tasks = backgroundTasks
        var taskInfo: [String: Any] = ["executionTime": executionTime]
        if let notificationId = notificationId {
            taskInfo["notificationId"] = notificationId
        }
        tasks[taskId] = taskInfo
        backgroundTasks = tasks
        
        // Schedule the background processing task
        scheduleBackgroundProcessing()
    }
    
    // Request authorization to send notifications
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
                completion(.success)
            } else {
                completion(.failure(nil))
            }
        }
    }
}
