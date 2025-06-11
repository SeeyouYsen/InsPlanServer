import Vapor
import AsyncHTTPClient

protocol NotificationProvider {
    func send(notification: Notification) async throws -> NotificationSendResult
}

struct NotificationSendResult {
    let success: Bool
    let messageID: String?
    let error: String?
}

// 邮件通知提供者
class EmailNotificationProvider: NotificationProvider {
    private let httpClient: HTTPClient
    private let config: EmailConfig
    
    init(httpClient: HTTPClient, config: EmailConfig) {
        self.httpClient = httpClient
        self.config = config
    }
    
    func send(notification: Notification) async throws -> NotificationSendResult {
        // 模拟发送邮件
        let messageID = "email_\(UUID().uuidString)"
        
        // 这里应该集成真实的邮件服务提供商，如阿里云邮件推送、腾讯云SES等
        print("Sending email to: \(notification.recipient)")
        print("Subject: \(notification.title)")
        print("Content: \(notification.content)")
        
        // 模拟发送成功
        return NotificationSendResult(
            success: true,
            messageID: messageID,
            error: nil
        )
    }
}

// 短信通知提供者
class SMSNotificationProvider: NotificationProvider {
    private let httpClient: HTTPClient
    private let config: SMSConfig
    
    init(httpClient: HTTPClient, config: SMSConfig) {
        self.httpClient = httpClient
        self.config = config
    }
    
    func send(notification: Notification) async throws -> NotificationSendResult {
        // 模拟发送短信
        let messageID = "sms_\(UUID().uuidString)"
        
        // 这里应该集成真实的短信服务提供商，如阿里云短信、腾讯云SMS等
        print("Sending SMS to: \(notification.recipient)")
        print("Content: \(notification.content)")
        
        // 模拟发送成功
        return NotificationSendResult(
            success: true,
            messageID: messageID,
            error: nil
        )
    }
}

// 推送通知提供者
class PushNotificationProvider: NotificationProvider {
    private let httpClient: HTTPClient
    private let config: PushConfig
    
    init(httpClient: HTTPClient, config: PushConfig) {
        self.httpClient = httpClient
        self.config = config
    }
    
    func send(notification: Notification) async throws -> NotificationSendResult {
        // 模拟发送推送通知
        let messageID = "push_\(UUID().uuidString)"
        
        print("Sending push notification to: \(notification.recipient)")
        print("Title: \(notification.title)")
        print("Content: \(notification.content)")
        
        return NotificationSendResult(
            success: true,
            messageID: messageID,
            error: nil
        )
    }
}

// 配置结构体
struct EmailConfig {
    let smtpHost: String
    let smtpPort: Int
    let username: String
    let password: String
    let fromEmail: String
    let fromName: String
}

struct SMSConfig {
    let accessKeyId: String
    let accessKeySecret: String
    let endpoint: String
    let signName: String
}

struct PushConfig {
    let appKey: String
    let appSecret: String
    let endpoint: String
}

// 通知提供者工厂
class NotificationProviderFactory {
    private static let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    
    private static let emailConfig = EmailConfig(
        smtpHost: Environment.get("SMTP_HOST") ?? "smtp.example.com",
        smtpPort: Int(Environment.get("SMTP_PORT") ?? "587") ?? 587,
        username: Environment.get("SMTP_USERNAME") ?? "test@example.com",
        password: Environment.get("SMTP_PASSWORD") ?? "password",
        fromEmail: Environment.get("FROM_EMAIL") ?? "noreply@insplan.com",
        fromName: Environment.get("FROM_NAME") ?? "InsPlan"
    )
    
    private static let smsConfig = SMSConfig(
        accessKeyId: Environment.get("SMS_ACCESS_KEY_ID") ?? "test_key_id",
        accessKeySecret: Environment.get("SMS_ACCESS_KEY_SECRET") ?? "test_key_secret",
        endpoint: Environment.get("SMS_ENDPOINT") ?? "https://dysmsapi.aliyuncs.com",
        signName: Environment.get("SMS_SIGN_NAME") ?? "InsPlan"
    )
    
    private static let pushConfig = PushConfig(
        appKey: Environment.get("PUSH_APP_KEY") ?? "test_app_key",
        appSecret: Environment.get("PUSH_APP_SECRET") ?? "test_app_secret",
        endpoint: Environment.get("PUSH_ENDPOINT") ?? "https://cloudpush.aliyuncs.com"
    )
    
    static func create(for channel: NotificationChannel) -> NotificationProvider {
        switch channel {
        case .email:
            return EmailNotificationProvider(httpClient: httpClient, config: emailConfig)
        case .sms:
            return SMSNotificationProvider(httpClient: httpClient, config: smsConfig)
        case .push:
            return PushNotificationProvider(httpClient: httpClient, config: pushConfig)
        case .inApp:
            // In-app notifications are stored in database only
            return EmailNotificationProvider(httpClient: httpClient, config: emailConfig)
        }
    }
}

// 通知模板服务
class NotificationTemplateService {
    static func getTemplate(for type: NotificationType, channel: NotificationChannel) -> NotificationTemplate? {
        let templates: [NotificationTemplate] = [
            NotificationTemplate(
                id: "welcome_email",
                type: .welcome,
                channel: .email,
                subject: "欢迎加入InsPlan保险平台",
                content: """
                亲爱的{{username}}，
                
                欢迎加入InsPlan保险平台！我们为您提供最优质的保险服务。
                
                您的账户已成功创建，现在可以开始浏览我们的保险产品。
                
                如有任何问题，请随时联系我们的客服团队。
                
                祝好，
                InsPlan团队
                """,
                variables: ["username"]
            ),
            NotificationTemplate(
                id: "order_created_email",
                type: .orderCreated,
                channel: .email,
                subject: "订单创建成功 - {{orderNumber}}",
                content: """
                您好{{username}}，
                
                您的保险订单已成功创建：
                
                订单号：{{orderNumber}}
                保险产品：{{planName}}
                保费金额：￥{{amount}}
                创建时间：{{createdAt}}
                
                请在24小时内完成支付，逾期订单将自动取消。
                
                支付链接：{{paymentUrl}}
                
                InsPlan团队
                """,
                variables: ["username", "orderNumber", "planName", "amount", "createdAt", "paymentUrl"]
            ),
            NotificationTemplate(
                id: "payment_completed_sms",
                type: .paymentCompleted,
                channel: .sms,
                subject: nil,
                content: "【InsPlan】您的保险订单{{orderNumber}}支付成功，保单将在1个工作日内生效。如有疑问请联系客服。",
                variables: ["orderNumber"]
            )
        ]
        
        return templates.first { $0.type == type && $0.channel == channel }
    }
    
    static func renderTemplate(_ template: NotificationTemplate, with data: [String: String]) -> (title: String, content: String) {
        var renderedSubject = template.subject ?? ""
        var renderedContent = template.content
        
        for (key, value) in data {
            let placeholder = "{{\(key)}}"
            renderedSubject = renderedSubject.replacingOccurrences(of: placeholder, with: value)
            renderedContent = renderedContent.replacingOccurrences(of: placeholder, with: value)
        }
        
        return (title: renderedSubject, content: renderedContent)
    }
}

struct NotificationTemplate {
    let id: String
    let type: NotificationType
    let channel: NotificationChannel
    let subject: String?
    let content: String
    let variables: [String]
}
