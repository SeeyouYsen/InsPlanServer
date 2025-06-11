import Fluent
import Vapor

// MARK: - 创建订单请求 DTO
struct CreateOrderRequest: Content {
    let planId: UUID
    let notes: String?
    let additionalFeatures: [AdditionalFeature]?
    
    func validate() throws {
        // 验证计划ID不为空
        if planId.uuidString.isEmpty {
            throw Abort(.badRequest, reason: "Plan ID is required")
        }
    }
}

// MARK: - 附加特性 DTO
struct AdditionalFeature: Content {
    let featureName: String
    let featureDescription: String
    let cost: Double
}

// MARK: - 更新订单请求 DTO
struct UpdateOrderRequest: Content {
    let status: OrderStatus?
    let notes: String?
    let startDate: Date?
}

// MARK: - 订单查询 DTO
struct OrderQueryRequest: Content {
    let status: OrderStatus?
    let userId: UUID?
    let planId: UUID?
    let startDate: Date?
    let endDate: Date?
    let page: Int?
    let pageSize: Int?
}

// MARK: - 订单响应 DTO
struct OrderResponse: Content {
    let id: UUID
    let userId: UUID
    let planId: UUID
    let orderNumber: String
    let status: OrderStatus
    let premiumAmount: Double
        let coverageAmount: Double
    let durationMonths: Int
    let startDate: Date?
    let endDate: Date?
    let notes: String?
    var items: [OrderItemResponse]?
    let planDetails: PlanDetails?
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - 订单项响应 DTO
struct OrderItemResponse: Content {
    let id: UUID
    let featureName: String
    let featureDescription: String
    let cost: Double
    let isIncluded: Bool
}

// MARK: - 计划详情 DTO (从计划服务获取)
struct PlanDetails: Content {
    let id: UUID
    let name: String
    let description: String
    let category: String
    let premium: Double
    let coverageAmount: Double
    let durationMonths: Int
}

// MARK: - 分页订单响应 DTO
struct PaginatedOrdersResponse: Content {
    let orders: [OrderResponse]
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}

// MARK: - 订单统计 DTO
struct OrderStatsResponse: Content {
    let totalOrders: Int
    let activeOrders: Int
    let pendingOrders: Int
    let totalRevenue: Double
    let averageOrderValue: Double
}

// MARK: - 订单状态更新请求 DTO
struct OrderStatusUpdateRequest: Content {
    let status: OrderStatus
}

// MARK: - Model Extensions
extension Order {
    func toResponse(includeItems: Bool = false, planDetails: PlanDetails? = nil) -> OrderResponse {
        OrderResponse(
            id: self.id!,
            userId: self.userId,
            planId: self.planId,
            orderNumber: self.orderNumber,
            status: self.status,
            premiumAmount: self.premiumAmount,
            coverageAmount: self.coverageAmount,
            durationMonths: self.durationMonths,
            startDate: self.startDate,
            endDate: self.endDate,
            notes: self.notes,
            items: includeItems ? nil : nil, // 将在控制器中加载
            planDetails: planDetails,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
    
    func generateOrderNumber() -> String {
        let timestamp = Date().timeIntervalSince1970
        let random = Int.random(in: 1000...9999)
        return "ORD-\(Int(timestamp))-\(random)"
    }
}

extension OrderItem {
    func toResponse() -> OrderItemResponse {
        OrderItemResponse(
            id: self.id!,
            featureName: self.featureName,
            featureDescription: self.featureDescription,
            cost: self.cost,
            isIncluded: self.isIncluded
        )
    }
}
