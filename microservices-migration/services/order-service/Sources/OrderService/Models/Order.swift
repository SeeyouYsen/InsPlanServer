import Fluent
import Vapor

// MARK: - 订单状态枚举
enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"       // 待处理
    case confirmed = "confirmed"   // 已确认
    case paid = "paid"            // 已支付
    case active = "active"        // 生效中
    case cancelled = "cancelled"  // 已取消
    case expired = "expired"      // 已过期
}

// MARK: - 订单模型
final class Order: Model, @unchecked Sendable {
    static let schema = "orders"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var userId: UUID
    
    @Field(key: "plan_id")
    var planId: UUID
    
    @Field(key: "order_number")
    var orderNumber: String
    
    @Enum(key: "status")
    var status: OrderStatus
    
    @Field(key: "premium_amount")
    var premiumAmount: Double
    
    @Field(key: "coverage_amount")
    var coverageAmount: Double
    
    @Field(key: "duration_months")
    var durationMonths: Int
    
    @Field(key: "start_date")
    var startDate: Date?
    
    @Field(key: "end_date")
    var endDate: Date?
    
    @Field(key: "notes")
    var notes: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$order)
    var items: [OrderItem]

    init() { }

    init(id: UUID? = nil, 
         userId: UUID, 
         planId: UUID, 
         orderNumber: String, 
         premiumAmount: Double, 
         coverageAmount: Double, 
         durationMonths: Int, 
         notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.planId = planId
        self.orderNumber = orderNumber
        self.status = .pending
        self.premiumAmount = premiumAmount
        self.coverageAmount = coverageAmount
        self.durationMonths = durationMonths
        self.notes = notes
    }
}

// MARK: - 订单项模型
final class OrderItem: Model, @unchecked Sendable {
    static let schema = "order_items"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "order_id")
    var order: Order
    
    @Field(key: "feature_name")
    var featureName: String
    
    @Field(key: "feature_description")
    var featureDescription: String
    
    @Field(key: "cost")
    var cost: Double
    
    @Field(key: "is_included")
    var isIncluded: Bool
    
    init() { }
    
    init(id: UUID? = nil, 
         orderId: UUID, 
         featureName: String, 
         featureDescription: String, 
         cost: Double, 
         isIncluded: Bool = true) {
        self.id = id
        self.$order.id = orderId
        self.featureName = featureName
        self.featureDescription = featureDescription
        self.cost = cost
        self.isIncluded = isIncluded
    }
}

// MARK: - Content
