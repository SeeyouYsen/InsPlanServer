import Fluent
import Vapor

final class Notification: Model, Content, @unchecked Sendable {
    static let schema = "notifications"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_id")
    var userID: UUID
    
    @Enum(key: "type")
    var type: NotificationType
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "content")
    var content: String
    
    @Enum(key: "channel")
    var channel: NotificationChannel
    
    @Enum(key: "status")
    var status: NotificationStatus
    
    @Field(key: "recipient")
    var recipient: String // email or phone number
    
    @Field(key: "template_id")
    var templateID: String?
    
    @Field(key: "template_data")
    var templateData: String? // JSON string
    
    @Field(key: "scheduled_at")
    var scheduledAt: Date?
    
    @Field(key: "sent_at")
    var sentAt: Date?
    
    @Field(key: "retry_count")
    var retryCount: Int
    
    @Field(key: "error_message")
    var errorMessage: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil,
         userID: UUID,
         type: NotificationType,
         title: String,
         content: String,
         channel: NotificationChannel,
         recipient: String,
         templateID: String? = nil,
         templateData: String? = nil,
         scheduledAt: Date? = nil) {
        self.id = id
        self.userID = userID
        self.type = type
        self.title = title
        self.content = content
        self.channel = channel
        self.status = .pending
        self.recipient = recipient
        self.templateID = templateID
        self.templateData = templateData
        self.scheduledAt = scheduledAt
        self.retryCount = 0
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case orderCreated = "order_created"
    case paymentCompleted = "payment_completed"
    case paymentFailed = "payment_failed"
    case policyActivated = "policy_activated"
    case policyExpiring = "policy_expiring"
    case claimSubmitted = "claim_submitted"
    case claimApproved = "claim_approved"
    case claimRejected = "claim_rejected"
    case welcome = "welcome"
    case passwordReset = "password_reset"
    case promotional = "promotional"
}

enum NotificationChannel: String, Codable, CaseIterable {
    case email = "email"
    case sms = "sms"
    case push = "push"
    case inApp = "in_app"
}

enum NotificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case sent = "sent"
    case failed = "failed"
    case scheduled = "scheduled"
    case cancelled = "cancelled"
}
