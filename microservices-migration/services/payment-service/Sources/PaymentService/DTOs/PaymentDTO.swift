import Vapor

struct PaymentDTO: Content {
    let id: UUID?
    let orderID: UUID
    let userID: UUID
    let amount: Double
    let currency: String
    let status: String
    let method: String
    let transactionID: String?
    let gatewayResponse: String?
    let createdAt: Date?
    let updatedAt: Date?
    let processedAt: Date?
}

struct CreatePaymentRequest: Content {
    let orderID: UUID
    let amount: Double
    let currency: String?
    let method: String
}

struct PaymentResponse: Content {
    let payment: PaymentDTO
    let paymentURL: String?
    let qrCode: String?
}

struct PaymentStatusUpdate: Content {
    let status: String
    let transactionID: String?
    let gatewayResponse: String?
}

struct PaymentStatisticsDTO: Content {
    let totalAmount: Double
    let totalCount: Int
    let completedAmount: Double
    let completedCount: Int
    let failedCount: Int
    let refundedAmount: Double
    let refundedCount: Int
    let averageAmount: Double
    let successRate: Double
}

struct PaymentMethodStatsDTO: Content {
    let method: String
    let count: Int
    let totalAmount: Double
    let percentage: Double
}

struct CreatePaymentDTO: Content {
    let orderID: UUID
    let userID: UUID
    let amount: Double
    let currency: String
    let method: PaymentMethod
}

struct UpdatePaymentDTO: Content {
    let status: PaymentStatus?
    let transactionID: String?
    let gatewayResponse: String?
    let processedAt: Date?
}

struct PaymentProcessResponse: Content {
    let paymentID: UUID
    let success: Bool
    let message: String
    let transactionID: String?
}

struct PaymentWebhookDTO: Content {
    let transactionID: String
    let status: PaymentStatus
    let message: String
    let signature: String
}
