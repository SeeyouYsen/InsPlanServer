import Fluent

struct CreateNotification: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("notification_type")
            .case("order_created")
            .case("payment_completed")
            .case("payment_failed")
            .case("policy_activated")
            .case("policy_expiring")
            .case("claim_submitted")
            .case("claim_approved")
            .case("claim_rejected")
            .case("welcome")
            .case("password_reset")
            .case("promotional")
            .create()
            .flatMap { notificationType in
                database.enum("notification_channel")
                    .case("email")
                    .case("sms")
                    .case("push")
                    .case("in_app")
                    .create()
                    .flatMap { notificationChannel in
                        database.enum("notification_status")
                            .case("pending")
                            .case("sent")
                            .case("failed")
                            .case("scheduled")
                            .case("cancelled")
                            .create()
                            .flatMap { notificationStatus in
                                database.schema("notifications")
                                    .id()
                                    .field("user_id", .uuid, .required)
                                    .field("type", notificationType, .required)
                                    .field("title", .string, .required)
                                    .field("content", .string, .required)
                                    .field("channel", notificationChannel, .required)
                                    .field("status", notificationStatus, .required)
                                    .field("recipient", .string, .required)
                                    .field("template_id", .string)
                                    .field("template_data", .string)
                                    .field("scheduled_at", .datetime)
                                    .field("sent_at", .datetime)
                                    .field("retry_count", .int, .required)
                                    .field("error_message", .string)
                                    .field("created_at", .datetime)
                                    .field("updated_at", .datetime)
                                    .create()
                            }
                    }
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("notifications").delete()
            .flatMap {
                database.enum("notification_status").delete()
            }
            .flatMap {
                database.enum("notification_channel").delete()
            }
            .flatMap {
                database.enum("notification_type").delete()
            }
    }
}
