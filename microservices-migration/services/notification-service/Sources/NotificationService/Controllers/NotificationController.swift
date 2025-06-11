import Vapor
import Fluent

struct NotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notifications = routes.grouped("api", "notifications")
        
        notifications.post(use: createNotification)
        notifications.post("send", use: sendNotification)
        notifications.post("bulk", use: sendBulkNotification)
        notifications.get(use: getAllNotifications)
        notifications.get(":notificationID", use: getNotification)
        notifications.put(":notificationID", use: updateNotification)
        notifications.delete(":notificationID", use: deleteNotification)
        notifications.get("user", ":userID", use: getUserNotifications)
        notifications.post(":notificationID", "resend", use: resendNotification)
        notifications.get("stats", use: getNotificationStats)
        notifications.get("templates", use: getTemplates)
    }
    
    // 创建通知（仅存储，不发送）
    func createNotification(req: Request) async throws -> Notification {
        let createDTO = try req.content.decode(CreateNotificationDTO.self)
        
        var templateDataJSON: String?
        if let templateData = createDTO.templateData {
            let encoder = JSONEncoder()
            let data = try encoder.encode(templateData)
            templateDataJSON = String(data: data, encoding: .utf8)
        }
        
        let notification = Notification(
            userID: createDTO.userID,
            type: createDTO.type,
            title: createDTO.title,
            content: createDTO.content,
            channel: createDTO.channel,
            recipient: createDTO.recipient,
            templateID: createDTO.templateID,
            templateData: templateDataJSON,
            scheduledAt: createDTO.scheduledAt
        )
        
        try await notification.save(on: req.db)
        return notification
    }
    
    // 发送通知
    func sendNotification(req: Request) async throws -> Notification {
        let sendRequest = try req.content.decode(SendNotificationRequest.self)
        
        // 创建通知记录
        var notification: Notification
        
        if let templateID = sendRequest.templateID,
           let template = NotificationTemplateService.getTemplate(for: sendRequest.type, channel: sendRequest.channel),
           let templateData = sendRequest.templateData {
            
            let rendered = NotificationTemplateService.renderTemplate(template, with: templateData)
            
            notification = Notification(
                userID: sendRequest.userID,
                type: sendRequest.type,
                title: rendered.title,
                content: rendered.content,
                channel: sendRequest.channel,
                recipient: sendRequest.recipient,
                templateID: templateID,
                templateData: try JSONEncoder().encode(templateData).string,
                scheduledAt: sendRequest.scheduledAt
            )
        } else {
            throw Abort(.badRequest, reason: "Template not found or template data missing")
        }
        
        try await notification.save(on: req.db)
        
        // 如果是立即发送
        if sendRequest.scheduledAt == nil {
            try await processNotification(notification, on: req.db)
        }
        
        return notification
    }
    
    // 批量发送通知
    func sendBulkNotification(req: Request) async throws -> [Notification] {
        let bulkRequest = try req.content.decode(BulkNotificationRequest.self)
        
        guard let template = NotificationTemplateService.getTemplate(for: bulkRequest.type, channel: bulkRequest.channel) else {
            throw Abort(.badRequest, reason: "Template not found")
        }
        
        var notifications: [Notification] = []
        
        for userID in bulkRequest.userIDs {
            let templateData = bulkRequest.templateData ?? [:]
            let rendered = NotificationTemplateService.renderTemplate(template, with: templateData)
            
            let notification = Notification(
                userID: userID,
                type: bulkRequest.type,
                title: rendered.title,
                content: rendered.content,
                channel: bulkRequest.channel,
                recipient: "user_\(userID)@example.com", // 实际项目中需要查询用户的联系方式
                templateID: bulkRequest.templateID,
                templateData: try JSONEncoder().encode(templateData).string,
                scheduledAt: bulkRequest.scheduledAt
            )
            
            try await notification.save(on: req.db)
            notifications.append(notification)
            
            // 如果是立即发送
            if bulkRequest.scheduledAt == nil {
                try await processNotification(notification, on: req.db)
            }
        }
        
        return notifications
    }
    
    // 获取所有通知
    func getAllNotifications(req: Request) async throws -> [Notification] {
        return try await Notification.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()
    }
    
    // 获取单个通知
    func getNotification(req: Request) async throws -> Notification {
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid notification ID")
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound, reason: "Notification not found")
        }
        
        return notification
    }
    
    // 更新通知
    func updateNotification(req: Request) async throws -> Notification {
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid notification ID")
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound, reason: "Notification not found")
        }
        
        let updateDTO = try req.content.decode(UpdateNotificationDTO.self)
        
        if let status = updateDTO.status {
            notification.status = status
        }
        if let sentAt = updateDTO.sentAt {
            notification.sentAt = sentAt
        }
        if let errorMessage = updateDTO.errorMessage {
            notification.errorMessage = errorMessage
        }
        
        try await notification.save(on: req.db)
        return notification
    }
    
    // 删除通知
    func deleteNotification(req: Request) async throws -> HTTPStatus {
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid notification ID")
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound, reason: "Notification not found")
        }
        
        try await notification.delete(on: req.db)
        return .noContent
    }
    
    // 获取用户通知
    func getUserNotifications(req: Request) async throws -> [Notification] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID")
        }
        
        return try await Notification.query(on: req.db)
            .filter(\.$userID == userID)
            .sort(\.$createdAt, .descending)
            .all()
    }
    
    // 重新发送通知
    func resendNotification(req: Request) async throws -> Notification {
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid notification ID")
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound, reason: "Notification not found")
        }
        
        guard notification.status == .failed else {
            throw Abort(.badRequest, reason: "Only failed notifications can be resent")
        }
        
        try await processNotification(notification, on: req.db)
        return notification
    }
    
    // 获取通知统计
    func getNotificationStats(req: Request) async throws -> NotificationStatsDTO {
        let total = try await Notification.query(on: req.db).count()
        let sent = try await Notification.query(on: req.db).filter(\.$status == .sent).count()
        let failed = try await Notification.query(on: req.db).filter(\.$status == .failed).count()
        let pending = try await Notification.query(on: req.db).filter(\.$status == .pending).count()
        
        let successRate = total > 0 ? Double(sent) / Double(total) * 100 : 0
        
        return NotificationStatsDTO(
            totalCount: total,
            sentCount: sent,
            failedCount: failed,
            pendingCount: pending,
            successRate: successRate
        )
    }
    
    // 获取模板列表
    func getTemplates(req: Request) async throws -> [NotificationTemplateDTO] {
        // 这里应该从数据库或配置文件中获取模板列表
        // 现在返回硬编码的模板
        return [
            NotificationTemplateDTO(
                id: "welcome_email",
                name: "欢迎邮件",
                type: .welcome,
                channel: .email,
                subject: "欢迎加入InsPlan保险平台",
                content: "欢迎加入模板内容...",
                variables: ["username"],
                isActive: true
            ),
            NotificationTemplateDTO(
                id: "order_created_email",
                name: "订单创建邮件",
                type: .orderCreated,
                channel: .email,
                subject: "订单创建成功",
                content: "订单创建模板内容...",
                variables: ["username", "orderNumber", "planName", "amount"],
                isActive: true
            )
        ]
    }
    
    // 处理通知发送
    private func processNotification(_ notification: Notification, on database: Database) async throws {
        do {
            notification.status = .pending
            try await notification.save(on: database)
            
            let provider = NotificationProviderFactory.create(for: notification.channel)
            let result = try await provider.send(notification: notification)
            
            if result.success {
                notification.status = .sent
                notification.sentAt = Date()
            } else {
                notification.status = .failed
                notification.errorMessage = result.error
                notification.retryCount += 1
            }
            
            try await notification.save(on: database)
        } catch {
            notification.status = .failed
            notification.errorMessage = error.localizedDescription
            notification.retryCount += 1
            try await notification.save(on: database)
        }
    }
}

extension Data {
    var string: String {
        return String(data: self, encoding: .utf8) ?? ""
    }
}
