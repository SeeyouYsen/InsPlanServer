import Vapor

struct NotificationDTO: Content {
    let id: UUID?
    let userID: UUID
    let type: String
    let title: String
    let content: String
    let channel: String
    let status: String
    let recipient: String
    let templateID: String?
    let templateData: String?
    let scheduledAt: Date?
    let sentAt: Date?
    let retryCount: Int
    let errorMessage: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateNotificationDTO: Content {
    let userID: UUID
    let type: NotificationType
    let title: String
    let content: String
    let channel: NotificationChannel
    let recipient: String
    let templateID: String?
    let templateData: [String: String]?
    let scheduledAt: Date?
}

struct UpdateNotificationDTO: Content {
    let status: NotificationStatus?
    let sentAt: Date?
    let errorMessage: String?
}

struct SendNotificationRequest: Content {
    let userID: UUID
    let type: NotificationType
    let channel: NotificationChannel
    let recipient: String
    let templateID: String?
    let templateData: [String: String]?
    let scheduledAt: Date?
}

struct BulkNotificationRequest: Content {
    let userIDs: [UUID]
    let type: NotificationType
    let channel: NotificationChannel
    let templateID: String
    let templateData: [String: String]?
    let scheduledAt: Date?
}

struct NotificationStatsDTO: Content {
    let totalCount: Int
    let sentCount: Int
    let failedCount: Int
    let pendingCount: Int
    let successRate: Double
}

struct ChannelStatsDTO: Content {
    let channel: String
    let count: Int
    let successRate: Double
}

struct NotificationTemplateDTO: Content {
    let id: String
    let name: String
    let type: NotificationType
    let channel: NotificationChannel
    let subject: String?
    let content: String
    let variables: [String]
    let isActive: Bool
}
