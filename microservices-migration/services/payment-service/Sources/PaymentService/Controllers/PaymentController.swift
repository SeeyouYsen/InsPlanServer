import Vapor
import Fluent

struct PaymentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let payments = routes.grouped("api", "payments")
        
        payments.post(use: createPayment)
        payments.get(use: getAllPayments)
        payments.get(":paymentID", use: getPayment)
        payments.put(":paymentID", use: updatePayment)
        payments.get("user", ":userID", use: getUserPayments)
        payments.get("order", ":orderID", use: getOrderPayment)
        payments.post(":paymentID", "process", use: processPayment)
        payments.post(":paymentID", "cancel", use: cancelPayment)
        payments.post(":paymentID", "refund", use: refundPayment)
        payments.post("webhook", use: handleWebhook)
    }
    
    // 创建支付
    func createPayment(req: Request) async throws -> Payment {
        let createDTO = try req.content.decode(CreatePaymentDTO.self)
        
        let payment = Payment(
            orderID: createDTO.orderID,
            userID: createDTO.userID,
            amount: createDTO.amount,
            currency: createDTO.currency,
            method: createDTO.method
        )
        
        try await payment.save(on: req.db)
        return payment
    }
    
    // 获取所有支付记录
    func getAllPayments(req: Request) async throws -> [Payment] {
        return try await Payment.query(on: req.db).all()
    }
    
    // 获取单个支付记录
    func getPayment(req: Request) async throws -> Payment {
        guard let paymentID = req.parameters.get("paymentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid payment ID")
        }
        
        guard let payment = try await Payment.find(paymentID, on: req.db) else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        return payment
    }
    
    // 更新支付记录
    func updatePayment(req: Request) async throws -> Payment {
        guard let paymentID = req.parameters.get("paymentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid payment ID")
        }
        
        guard let payment = try await Payment.find(paymentID, on: req.db) else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        let updateDTO = try req.content.decode(UpdatePaymentDTO.self)
        
        if let status = updateDTO.status {
            payment.status = status
        }
        if let transactionID = updateDTO.transactionID {
            payment.transactionID = transactionID
        }
        if let gatewayResponse = updateDTO.gatewayResponse {
            payment.gatewayResponse = gatewayResponse
        }
        if let processedAt = updateDTO.processedAt {
            payment.processedAt = processedAt
        }
        
        try await payment.save(on: req.db)
        return payment
    }
    
    // 获取用户的支付记录
    func getUserPayments(req: Request) async throws -> [Payment] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID")
        }
        
        return try await Payment.query(on: req.db)
            .filter(\.$userID == userID)
            .sort(\.$createdAt, .descending)
            .all()
    }
    
    // 获取订单的支付记录
    func getOrderPayment(req: Request) async throws -> Payment {
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        
        guard let payment = try await Payment.query(on: req.db)
            .filter(\.$orderID == orderID)
            .first() else {
            throw Abort(.notFound, reason: "Payment not found for order")
        }
        
        return payment
    }
    
    // 处理支付
    func processPayment(req: Request) async throws -> PaymentProcessResponse {
        guard let paymentID = req.parameters.get("paymentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid payment ID")
        }
        
        guard let payment = try await Payment.find(paymentID, on: req.db) else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        // 检查支付状态
        guard payment.status == .pending else {
            throw Abort(.badRequest, reason: "Payment cannot be processed")
        }
        
        // 更新状态为处理中
        payment.status = .processing
        try await payment.save(on: req.db)
        
        do {
            // 根据支付方式选择网关
            let paymentService = PaymentGatewayFactory.create(for: payment.method)
            let result = try await paymentService.processPayment(
                amount: payment.amount,
                currency: payment.currency,
                orderID: payment.orderID.uuidString
            )
            
            // 更新支付状态
            payment.status = result.success ? .completed : .failed
            payment.transactionID = result.transactionID
            payment.gatewayResponse = result.message
            payment.processedAt = Date()
            
            try await payment.save(on: req.db)
            
            return PaymentProcessResponse(
                paymentID: payment.id!,
                success: result.success,
                message: result.message,
                transactionID: result.transactionID
            )
        } catch {
            // 处理失败，更新状态
            payment.status = .failed
            payment.gatewayResponse = error.localizedDescription
            payment.processedAt = Date()
            try await payment.save(on: req.db)
            
            throw Abort(.internalServerError, reason: "Payment processing failed: \(error.localizedDescription)")
        }
    }
    
    // 取消支付
    func cancelPayment(req: Request) async throws -> Payment {
        guard let paymentID = req.parameters.get("paymentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid payment ID")
        }
        
        guard let payment = try await Payment.find(paymentID, on: req.db) else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        guard payment.status == .pending || payment.status == .processing else {
            throw Abort(.badRequest, reason: "Payment cannot be cancelled")
        }
        
        payment.status = .cancelled
        payment.processedAt = Date()
        try await payment.save(on: req.db)
        
        return payment
    }
    
    // 退款
    func refundPayment(req: Request) async throws -> Payment {
        guard let paymentID = req.parameters.get("paymentID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid payment ID")
        }
        
        guard let payment = try await Payment.find(paymentID, on: req.db) else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        guard payment.status == .completed else {
            throw Abort(.badRequest, reason: "Only completed payments can be refunded")
        }
        
        // 处理退款逻辑
        let paymentService = PaymentGatewayFactory.create(for: payment.method)
        
        do {
            let refundResult = try await paymentService.refundPayment(
                transactionID: payment.transactionID!,
                amount: payment.amount
            )
            
            if refundResult.success {
                payment.status = .refunded
                payment.gatewayResponse = refundResult.message
                try await payment.save(on: req.db)
            } else {
                throw Abort(.internalServerError, reason: refundResult.message)
            }
        } catch {
            throw Abort(.internalServerError, reason: "Refund failed: \(error.localizedDescription)")
        }
        
        return payment
    }
    
    // 处理支付网关回调
    func handleWebhook(req: Request) async throws -> HTTPStatus {
        let webhookData = try req.content.decode(PaymentWebhookDTO.self)
        
        guard let payment = try await Payment.query(on: req.db)
            .filter(\.$transactionID == webhookData.transactionID)
            .first() else {
            throw Abort(.notFound, reason: "Payment not found")
        }
        
        // 验证签名（实际项目中需要验证）
        // let isValid = verifyWebhookSignature(req, webhookData)
        // guard isValid else { throw Abort(.unauthorized) }
        
        // 更新支付状态
        payment.status = webhookData.status
        payment.gatewayResponse = webhookData.message
        if payment.processedAt == nil {
            payment.processedAt = Date()
        }
        
        try await payment.save(on: req.db)
        
        return .ok
    }
}
