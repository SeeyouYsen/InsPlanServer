import Fluent
import Vapor

final class Payment: Model, Content, @unchecked Sendable {
    static let schema = "payments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "order_id")
    var orderID: UUID
    
    @Field(key: "user_id")
    var userID: UUID
    
    @Field(key: "amount")
    var amount: Double
    
    @Field(key: "currency")
    var currency: String
    
    @Enum(key: "status")
    var status: PaymentStatus
    
    @Enum(key: "method")
    var method: PaymentMethod
    
    @Field(key: "transaction_id")
    var transactionID: String?
    
    @Field(key: "gateway_response")
    var gatewayResponse: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "processed_at", on: .none)
    var processedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil,
         orderID: UUID,
         userID: UUID,
         amount: Double,
         currency: String = "CNY",
         status: PaymentStatus = .pending,
         method: PaymentMethod,
         transactionID: String? = nil,
         gatewayResponse: String? = nil,
         processedAt: Date? = nil) {
        self.id = id
        self.orderID = orderID
        self.userID = userID
        self.amount = amount
        self.currency = currency
        self.status = status
        self.method = method
        self.transactionID = transactionID
        self.gatewayResponse = gatewayResponse
        self.processedAt = processedAt
    }
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case refunded = "refunded"
}

enum PaymentMethod: String, Codable, CaseIterable {
    case alipay = "alipay"
    case wechatPay = "wechat_pay"
    case bankCard = "bank_card"
    case applePay = "apple_pay"
    case unionPay = "union_pay"
}

extension Payment {
    func toDTO() -> PaymentDTO {
        return PaymentDTO(
            id: self.id,
            orderID: self.orderID,
            userID: self.userID,
            amount: self.amount,
            currency: self.currency,
            status: self.status.rawValue,
            method: self.method.rawValue,
            transactionID: self.transactionID,
            gatewayResponse: self.gatewayResponse,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            processedAt: self.processedAt
        )
    }
}
