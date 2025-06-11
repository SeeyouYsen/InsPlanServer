import Fluent
import Vapor

struct OrderController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let orders = routes.grouped("api", "v1", "orders")
        
        // 需要用户认证的路由
        let authenticated = orders.grouped(UserAuthenticator())
        authenticated.get(use: listOrders)
        authenticated.get(":orderID", use: getOrder)
        authenticated.post(use: createOrder)
        authenticated.put(":orderID", use: updateOrder)
        authenticated.delete(":orderID", use: cancelOrder)
        
        // 用户专属路由
        authenticated.get("my", use: getMyOrders)
        authenticated.get("stats", use: getOrderStats)
        
        // 管理员路由
        let admin = orders.grouped(AdminAuthenticator())
        admin.get("all", use: getAllOrders)
        admin.put(":orderID", "status", use: updateOrderStatus)
    }

    // MARK: - 获取订单列表
    @Sendable
    func listOrders(req: Request) async throws -> PaginatedOrdersResponse {
        let userId = try getUserId(from: req)
        let query = try req.query.decode(OrderQueryRequest.self)
        
        var orderQuery = Order.query(on: req.db)
            .filter(\.$userId == userId)
        
        // 应用过滤条件
        if let status = query.status {
            orderQuery = orderQuery.filter(\.$status == status)
        }
        
        if let planId = query.planId {
            orderQuery = orderQuery.filter(\.$planId == planId)
        }
        
        if let startDate = query.startDate {
            orderQuery = orderQuery.filter(\.$createdAt >= startDate)
        }
        
        if let endDate = query.endDate {
            orderQuery = orderQuery.filter(\.$createdAt <= endDate)
        }
        
        // 分页
        let page = query.page ?? 1
        let pageSize = min(query.pageSize ?? 20, 100)
        let offset = (page - 1) * pageSize
        
        let total = try await orderQuery.count()
        let orders = try await orderQuery
            .offset(offset)
            .limit(pageSize)
            .sort(\.$createdAt, .descending)
            .all()
        
        // 获取计划详情
        var orderResponses: [OrderResponse] = []
        for order in orders {
            let planDetails = try await getPlanDetails(planId: order.planId, on: req)
            let items = try await OrderItem.query(on: req.db)
                .filter(\.$order.$id == order.id!)
                .all()
            
            let planDetailsConverted = planDetails.map { pd in
                PlanDetails(
                    id: pd.id,
                    name: pd.name,
                    description: pd.description,
                    category: pd.category,
                    premium: pd.premium,
                    coverageAmount: pd.coverageAmount,
                    durationMonths: pd.durationMonths
                )
            }
            var response = order.toResponse(planDetails: planDetailsConverted)
            response.items = items.map { $0.toResponse() }
            orderResponses.append(response)
        }
        
        let totalPages = Int(ceil(Double(total) / Double(pageSize)))
        
        return PaginatedOrdersResponse(
            orders: orderResponses,
            page: page,
            pageSize: pageSize,
            total: total,
            totalPages: totalPages
        )
    }

    // MARK: - 获取单个订单
    @Sendable
    func getOrder(req: Request) async throws -> OrderResponse {
        let userId = try getUserId(from: req)
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        
        guard let order = try await Order.query(on: req.db)
            .filter(\.$id == orderID)
            .filter(\.$userId == userId)
            .first() else {
            throw Abort(.notFound, reason: "Order not found")
        }
        
        // 获取订单项
        let items = try await OrderItem.query(on: req.db)
            .filter(\.$order.$id == orderID)
            .all()
        
        // 获取计划详情
        let planDetails = try await getPlanDetails(planId: order.planId, on: req)
        
        let planDetailsConverted = planDetails.map { pd in
            PlanDetails(
                id: pd.id,
                name: pd.name,
                description: pd.description,
                category: pd.category,
                premium: pd.premium,
                coverageAmount: pd.coverageAmount,
                durationMonths: pd.durationMonths
            )
        }
        var response = order.toResponse(planDetails: planDetailsConverted)
        response.items = items.map { $0.toResponse() }
        
        return response
    }

    // MARK: - 创建订单
    @Sendable
    func createOrder(req: Request) async throws -> OrderResponse {
        let userId = try getUserId(from: req)
        let createRequest = try req.content.decode(CreateOrderRequest.self)
        try createRequest.validate()
        
        // 验证计划存在并获取详情
        guard let planDetails = try await getPlanDetails(planId: createRequest.planId, on: req) else {
            throw Abort(.badRequest, reason: "Plan not found or inactive")
        }
        
        // 计算总金额
        var totalAmount = planDetails.premium
        if let additionalFeatures = createRequest.additionalFeatures {
            totalAmount += additionalFeatures.reduce(0) { $0 + $1.cost }
        }
        
        // 创建订单
        let order = Order(
            userId: userId,
            planId: createRequest.planId,
            orderNumber: generateOrderNumber(),
            premiumAmount: totalAmount,
            coverageAmount: planDetails.coverageAmount,
            durationMonths: planDetails.durationMonths,
            notes: createRequest.notes
        )
        
        try await order.save(on: req.db)
        
        // 创建订单项
        var orderItems: [OrderItem] = []
        
        // 基础特性
        for feature in planDetails.features ?? [] {
            let item = OrderItem(
                orderId: order.id!,
                featureName: feature.featureName,
                featureDescription: feature.featureDescription,
                cost: feature.additionalCost ?? 0,
                isIncluded: feature.isIncluded
            )
            try await item.save(on: req.db)
            orderItems.append(item)
        }
        
        // 附加特性
        if let additionalFeatures = createRequest.additionalFeatures {
            for feature in additionalFeatures {
                let item = OrderItem(
                    orderId: order.id!,
                    featureName: feature.featureName,
                    featureDescription: feature.featureDescription,
                    cost: feature.cost,
                    isIncluded: false
                )
                try await item.save(on: req.db)
                orderItems.append(item)
            }
        }
        
        // 发送订单创建事件
        try await publishOrderEvent(.orderCreated, order: order, on: req)
        
        let planDetailsConverted = PlanDetails(
            id: planDetails.id,
            name: planDetails.name,
            description: planDetails.description,
            category: planDetails.category,
            premium: planDetails.premium,
            coverageAmount: planDetails.coverageAmount,
            durationMonths: planDetails.durationMonths
        )
        var response = order.toResponse(planDetails: planDetailsConverted)
        response.items = orderItems.map { $0.toResponse() }
        
        return response
    }

    // MARK: - 更新订单
    @Sendable
    func updateOrder(req: Request) async throws -> OrderResponse {
        let userId = try getUserId(from: req)
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        
        guard let order = try await Order.query(on: req.db)
            .filter(\.$id == orderID)
            .filter(\.$userId == userId)
            .first() else {
            throw Abort(.notFound, reason: "Order not found")
        }
        
        // 只有待处理状态的订单可以更新
        guard order.status == .pending else {
            throw Abort(.badRequest, reason: "Only pending orders can be updated")
        }
        
        let updateRequest = try req.content.decode(UpdateOrderRequest.self)
        
        if let status = updateRequest.status {
            order.status = status
        }
        if let notes = updateRequest.notes {
            order.notes = notes
        }
        if let startDate = updateRequest.startDate {
            order.startDate = startDate
            // 计算结束日期
            let calendar = Calendar.current
            order.endDate = calendar.date(byAdding: .month, value: order.durationMonths, to: startDate)
        }
        
        try await order.save(on: req.db)
        
        // 发送订单更新事件
        try await publishOrderEvent(.orderUpdated, order: order, on: req)
        
        return order.toResponse()
    }

    // MARK: - 取消订单
    @Sendable
    func cancelOrder(req: Request) async throws -> HTTPStatus {
        let userId = try getUserId(from: req)
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        
        guard let order = try await Order.query(on: req.db)
            .filter(\.$id == orderID)
            .filter(\.$userId == userId)
            .first() else {
            throw Abort(.notFound, reason: "Order not found")
        }
        
        // 只有待处理或已确认状态的订单可以取消
        guard order.status == .pending || order.status == .confirmed else {
            throw Abort(.badRequest, reason: "Order cannot be cancelled")
        }
        
        order.status = .cancelled
        try await order.save(on: req.db)
        
        // 发送订单取消事件
        try await publishOrderEvent(.orderCancelled, order: order, on: req)
        
        return .noContent
    }

    // MARK: - 获取我的订单
    @Sendable
    func getMyOrders(req: Request) async throws -> [OrderResponse] {
        let userId = try getUserId(from: req)
        
        let orders = try await Order.query(on: req.db)
            .filter(\.$userId == userId)
            .sort(\.$createdAt, .descending)
            .limit(10)
            .all()
        
        var responses: [OrderResponse] = []
        for order in orders {
            let planDetails = try await getPlanDetails(planId: order.planId, on: req)
            let planDetailsConverted = planDetails.map { pd in
                PlanDetails(
                    id: pd.id,
                    name: pd.name,
                    description: pd.description,
                    category: pd.category,
                    premium: pd.premium,
                    coverageAmount: pd.coverageAmount,
                    durationMonths: pd.durationMonths
                )
            }
            responses.append(order.toResponse(planDetails: planDetailsConverted))
        }
        
        return responses
    }

    // MARK: - 获取订单统计
    @Sendable
    func getOrderStats(req: Request) async throws -> OrderStatsResponse {
        let userId = try getUserId(from: req)
        
        let allOrders = try await Order.query(on: req.db)
            .filter(\.$userId == userId)
            .all()
        
        let totalOrders = allOrders.count
        let activeOrders = allOrders.filter { $0.status == .active }.count
        let pendingOrders = allOrders.filter { $0.status == .pending }.count
        let totalRevenue = allOrders.reduce(0) { $0 + $1.premiumAmount }
        let averageOrderValue = totalOrders > 0 ? totalRevenue / Double(totalOrders) : 0
        
        return OrderStatsResponse(
            totalOrders: totalOrders,
            activeOrders: activeOrders,
            pendingOrders: pendingOrders,
            totalRevenue: totalRevenue,
            averageOrderValue: averageOrderValue
        )
    }

    // MARK: - 管理员功能
    @Sendable
    func getAllOrders(req: Request) async throws -> [OrderResponse] {
        let orders = try await Order.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()
        
        var responses: [OrderResponse] = []
        for order in orders {
            let planDetails = try await getPlanDetails(planId: order.planId, on: req)
            if let planDetails = planDetails {
                let planDetailsConverted = PlanDetails(
                    id: planDetails.id,
                    name: planDetails.name,
                    description: planDetails.description,
                    category: planDetails.category,
                    premium: planDetails.premium,
                    coverageAmount: planDetails.coverageAmount,
                    durationMonths: planDetails.durationMonths
                )
                responses.append(order.toResponse(planDetails: planDetailsConverted))
            } else {
                responses.append(order.toResponse(planDetails: nil))
            }
        }
        
        return responses
    }
    
    @Sendable
    func updateOrderStatus(req: Request) async throws -> OrderResponse {
        guard let orderIdString = req.parameters.get("orderID"),
              let orderId = UUID(uuidString: orderIdString) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }
        
        let statusUpdate = try req.content.decode(OrderStatusUpdateRequest.self)
        
        guard let order = try await Order.find(orderId, on: req.db) else {
            throw Abort(.notFound, reason: "Order not found")
        }
        
        order.status = statusUpdate.status
        try await order.save(on: req.db)
        
        // 发送状态更新事件
        try await publishOrderEvent(.orderUpdated, order: order, on: req)
        
        let planDetails = try await getPlanDetails(planId: order.planId, on: req)
        if let planDetails = planDetails {
            let planDetailsConverted = PlanDetails(
                id: planDetails.id,
                name: planDetails.name,
                description: planDetails.description,
                category: planDetails.category,
                premium: planDetails.premium,
                coverageAmount: planDetails.coverageAmount,
                durationMonths: planDetails.durationMonths
            )
            return order.toResponse(planDetails: planDetailsConverted)
        } else {
            return order.toResponse(planDetails: nil)
        }
    }

    // MARK: - 私有方法
    private func getUserId(from req: Request) throws -> UUID {
        guard let userIdString = req.headers.first(name: "X-User-ID"),
              let userId = UUID(uuidString: userIdString) else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        return userId
    }
    
    private func generateOrderNumber() -> String {
        let timestamp = Date().timeIntervalSince1970
        let random = Int.random(in: 1000...9999)
        return "ORD-\(Int(timestamp))-\(random)"
    }
    
    private func getPlanDetails(planId: UUID, on req: Request) async throws -> PlanDetailsExtended? {
        // 调用计划服务获取计划详情
        // 这里应该使用服务发现和HTTP客户端
        // 暂时返回模拟数据
        return PlanDetailsExtended(
            id: planId,
            name: "示例保险计划",
            description: "这是一个示例保险计划",
            category: "health",
            premium: 299.99,
            coverageAmount: 100000.0,
            durationMonths: 12,
            features: []
        )
    }
    
    private func publishOrderEvent(_ eventType: OrderEventType, order: Order, on req: Request) async throws {
        // 发布订单事件到消息队列
        // 这里应该集成消息队列系统（如 RabbitMQ, Apache Kafka 等）
        req.logger.info("Order event published: \(eventType) for order \(order.id?.uuidString ?? "unknown")")
    }
}

// MARK: - 扩展的计划详情
struct PlanDetailsExtended: Content {
    let id: UUID
    let name: String
    let description: String
    let category: String
    let premium: Double
    let coverageAmount: Double
    let durationMonths: Int
    let features: [PlanFeature]?
}

struct PlanFeature: Content {
    let featureName: String
    let featureDescription: String
    let isIncluded: Bool
    let additionalCost: Double?
}

// MARK: - 订单事件类型
enum OrderEventType: String {
    case orderCreated = "order.created"
    case orderUpdated = "order.updated"
    case orderCancelled = "order.cancelled"
    case orderPaid = "order.paid"
    case orderActivated = "order.activated"
}

// MARK: - 认证中间件
struct UserAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let userIdString = request.headers.first(name: "X-User-ID"),
              let _ = UUID(uuidString: userIdString) else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        
        return try await next.respond(to: request)
    }
}

struct AdminAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let _ = request.headers.first(name: "X-User-ID") else {
            throw Abort(.unauthorized, reason: "Admin authentication required")
        }
        
        // 这里应该检查用户是否有管理员权限
        return try await next.respond(to: request)
    }
}
