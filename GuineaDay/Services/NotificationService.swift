import Foundation
import UserNotifications

/// Wraps UNUserNotificationCenter for task reminders.
/// Uses task.id.uuidString as the notification identifier so any device
/// can cancel it without storing a separate field.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // MARK: - Permission

    /// Requests notification permission if not yet decided. Returns true if granted.
    func requestPermission() async -> Bool {
        let center   = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional: return true
        case .denied:                   return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    // MARK: - Schedule

    /// Schedules a local notification for a task's reminderTime.
    /// Safe to call even if reminderEnabled is false — it's a no-op.
    func schedule(for task: TaskItem) {
        guard task.reminderEnabled,
              let fireAt = task.reminderTime,
              fireAt > Date()          // don't schedule past reminders
        else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Guinea Day 🐾"
        content.body      = task.title
        content.sound     = .default

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    /// Cancels the pending notification for a task (if any).
    func cancel(for task: TaskItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
