import Fluent
import Vapor

struct PlanController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let plans = routes.grouped("api", "v1", "plans")
        
        // 公开路由 - 无需认证
        plans.get(use: listPlans)
        plans.get(":planID", use: getPlan)
        plans.get(":planID", "features", use: getPlanFeatures)
        plans.get(":planID", "reviews", use: getPlanReviews)
        plans.get("categories", use: getCategories)
        
        // 需要管理员权限的路由
        let admin = plans.grouped(AdminAuthenticator())
        admin.post(use: createPlan)
        admin.put(":planID", use: updatePlan)
        admin.delete(":planID", use: deletePlan)
        admin.post(":planID", "features", use: addPlanFeature)
        admin.delete("features", ":featureID", use: removeFeature)
        
        // 需要用户认证的路由
        let authenticated = plans.grouped(UserAuthenticator())
        authenticated.post(":planID", "reviews", use: createReview)
        authenticated.put("reviews", ":reviewID", use: updateReview)
        authenticated.delete("reviews", ":reviewID", use: deleteReview)
    }

    // MARK: - 获取计划列表
    @Sendable
    func listPlans(req: Request) async throws -> PaginatedPlansResponse {
        let query = try req.query.decode(PlanQueryRequest.self)
        
        var planQuery = InsurancePlan.query(on: req.db)
            .filter(\.$isActive == (query.isActive ?? true))
        
        // 应用过滤条件
        if let category = query.category {
            planQuery = planQuery.filter(\.$category == category)
        }
        
        if let minPremium = query.minPremium {
            planQuery = planQuery.filter(\.$premium >= minPremium)
        }
        
        if let maxPremium = query.maxPremium {
            planQuery = planQuery.filter(\.$premium <= maxPremium)
        }
        
        if let minCoverage = query.minCoverage {
            planQuery = planQuery.filter(\.$coverageAmount >= minCoverage)
        }
        
        if let maxCoverage = query.maxCoverage {
            planQuery = planQuery.filter(\.$coverageAmount <= maxCoverage)
        }
        
        if let maxDuration = query.maxDuration {
            planQuery = planQuery.filter(\.$durationMonths <= maxDuration)
        }
        
        // 分页
        let page = query.page ?? 1
        let pageSize = min(query.pageSize ?? 20, 100) // 最大100条
        let offset = (page - 1) * pageSize
        
        // 获取总数
        let total = try await planQuery.count()
        
        // 获取分页数据
        let plans = try await planQuery
            .offset(offset)
            .limit(pageSize)
            .sort(\.$createdAt, .descending)
            .all()
        
        // 获取评价统计
        var planResponses: [PlanResponse] = []
        for plan in plans {
            let (avgRating, reviewCount) = try await getPlanRatingStats(planId: plan.id!, on: req.db)
            planResponses.append(plan.toResponse(averageRating: avgRating, reviewCount: reviewCount))
        }
        
        let totalPages = Int(ceil(Double(total) / Double(pageSize)))
        
        return PaginatedPlansResponse(
            plans: planResponses,
            page: page,
            pageSize: pageSize,
            total: total,
            totalPages: totalPages
        )
    }

    // MARK: - 获取单个计划
    @Sendable
    func getPlan(req: Request) async throws -> PlanResponse {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        guard let plan = try await InsurancePlan.find(planID, on: req.db) else {
            throw Abort(.notFound, reason: "Plan not found")
        }
        
        // 获取特性
        let features = try await PlanFeature.query(on: req.db)
            .filter(\.$plan.$id == planID)
            .all()
        
        // 获取评价统计
        let (avgRating, reviewCount) = try await getPlanRatingStats(planId: planID, on: req.db)
        
        var response = plan.toResponse(averageRating: avgRating, reviewCount: reviewCount)
        response.features = features.map { $0.toResponse() }
        
        return response
    }

    // MARK: - 创建计划
    @Sendable
    func createPlan(req: Request) async throws -> PlanResponse {
        let createRequest = try req.content.decode(CreatePlanRequest.self)
        try createRequest.validate()
        
        let plan = InsurancePlan(
            name: createRequest.name,
            description: createRequest.description,
            premium: createRequest.premium,
            coverageAmount: createRequest.coverageAmount,
            durationMonths: createRequest.durationMonths,
            category: createRequest.category,
            termsConditions: createRequest.termsConditions
        )
        
        try await plan.save(on: req.db)
        
        // 如果有特性，创建特性
        if let features = createRequest.features {
            for featureRequest in features {
                let feature = PlanFeature(
                    planID: plan.id!,
                    featureName: featureRequest.featureName,
                    featureDescription: featureRequest.featureDescription,
                    isIncluded: featureRequest.isIncluded,
                    additionalCost: featureRequest.additionalCost
                )
                try await feature.save(on: req.db)
            }
        }
        
        return plan.toResponse()
    }

    // MARK: - 更新计划
    @Sendable
    func updatePlan(req: Request) async throws -> PlanResponse {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        guard let plan = try await InsurancePlan.find(planID, on: req.db) else {
            throw Abort(.notFound, reason: "Plan not found")
        }
        
        let updateRequest = try req.content.decode(UpdatePlanRequest.self)
        
        if let name = updateRequest.name {
            plan.name = name
        }
        if let description = updateRequest.description {
            plan.description = description
        }
        if let premium = updateRequest.premium {
            plan.premium = premium
        }
        if let coverageAmount = updateRequest.coverageAmount {
            plan.coverageAmount = coverageAmount
        }
        if let durationMonths = updateRequest.durationMonths {
            plan.durationMonths = durationMonths
        }
        if let category = updateRequest.category {
            plan.category = category
        }
        if let isActive = updateRequest.isActive {
            plan.isActive = isActive
        }
        if let termsConditions = updateRequest.termsConditions {
            plan.termsConditions = termsConditions
        }
        
        try await plan.save(on: req.db)
        return plan.toResponse()
    }

    // MARK: - 删除计划
    @Sendable
    func deletePlan(req: Request) async throws -> HTTPStatus {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        guard let plan = try await InsurancePlan.find(planID, on: req.db) else {
            throw Abort(.notFound, reason: "Plan not found")
        }
        
        // 软删除 - 只是标记为不活跃
        plan.isActive = false
        try await plan.save(on: req.db)
        
        return .noContent
    }

    // MARK: - 获取计划特性
    @Sendable
    func getPlanFeatures(req: Request) async throws -> [FeatureResponse] {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        let features = try await PlanFeature.query(on: req.db)
            .filter(\.$plan.$id == planID)
            .all()
        
        return features.map { $0.toResponse() }
    }

    // MARK: - 添加计划特性
    @Sendable
    func addPlanFeature(req: Request) async throws -> FeatureResponse {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        guard let _ = try await InsurancePlan.find(planID, on: req.db) else {
            throw Abort(.notFound, reason: "Plan not found")
        }
        
        let featureRequest = try req.content.decode(CreateFeatureRequest.self)
        
        let feature = PlanFeature(
            planID: planID,
            featureName: featureRequest.featureName,
            featureDescription: featureRequest.featureDescription,
            isIncluded: featureRequest.isIncluded,
            additionalCost: featureRequest.additionalCost
        )
        
        try await feature.save(on: req.db)
        return feature.toResponse()
    }

    // MARK: - 获取计划分类
    @Sendable
    func getCategories(req: Request) async throws -> [String: String] {
        let categories = PlanCategory.allCases.reduce(into: [String: String]()) { result, category in
            result[category.rawValue] = category.rawValue.capitalized
        }
        return categories
    }
    
    // MARK: - 获取计划评价
    @Sendable
    func getPlanReviews(req: Request) async throws -> [ReviewResponse] {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        let reviews = try await PlanReview.query(on: req.db)
            .filter(\.$plan.$id == planID)
            .sort(\.$createdAt, .descending)
            .all()
        
        return reviews.map { $0.toResponse() }
    }
    
    // MARK: - 删除计划特性
    @Sendable
    func removeFeature(req: Request) async throws -> HTTPStatus {
        guard let featureID = req.parameters.get("featureID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid feature ID")
        }
        
        guard let feature = try await PlanFeature.find(featureID, on: req.db) else {
            throw Abort(.notFound, reason: "Feature not found")
        }
        
        try await feature.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - 创建计划评价
    @Sendable
    func createReview(req: Request) async throws -> ReviewResponse {
        guard let planID = req.parameters.get("planID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid plan ID")
        }
        
        guard let userId = req.storage[UserIDKey.self] else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        
        guard let _ = try await InsurancePlan.find(planID, on: req.db) else {
            throw Abort(.notFound, reason: "Plan not found")
        }
        
        let reviewRequest = try req.content.decode(CreateReviewRequest.self)
        try reviewRequest.validate()
        
        // 检查用户是否已经评价过这个计划
        if let _ = try await PlanReview.query(on: req.db)
            .filter(\.$plan.$id == planID)
            .filter(\.$userId == userId)
            .first() {
            throw Abort(.conflict, reason: "You have already reviewed this plan")
        }
        
        let review = PlanReview(
            planID: planID,
            userId: userId,
            rating: reviewRequest.rating,
            comment: reviewRequest.comment
        )
        
        try await review.save(on: req.db)
        return review.toResponse()
    }
    
    // MARK: - 更新计划评价
    @Sendable
    func updateReview(req: Request) async throws -> ReviewResponse {
        guard let reviewID = req.parameters.get("reviewID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid review ID")
        }
        
        guard let userId = req.storage[UserIDKey.self] else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        
        guard let review = try await PlanReview.find(reviewID, on: req.db) else {
            throw Abort(.notFound, reason: "Review not found")
        }
        
        // 确保只有评价作者可以更新评价
        guard review.userId == userId else {
            throw Abort(.forbidden, reason: "You can only update your own reviews")
        }
        
        let updateRequest = try req.content.decode(UpdateReviewRequest.self)
        
        if let rating = updateRequest.rating {
            review.rating = rating
        }
        if let comment = updateRequest.comment {
            review.comment = comment
        }
        
        try await review.save(on: req.db)
        return review.toResponse()
    }
    
    // MARK: - 删除计划评价
    @Sendable
    func deleteReview(req: Request) async throws -> HTTPStatus {
        guard let reviewID = req.parameters.get("reviewID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid review ID")
        }
        
        guard let userId = req.storage[UserIDKey.self] else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        
        guard let review = try await PlanReview.find(reviewID, on: req.db) else {
            throw Abort(.notFound, reason: "Review not found")
        }
        
        // 确保只有评价作者可以删除评价
        guard review.userId == userId else {
            throw Abort(.forbidden, reason: "You can only delete your own reviews")
        }
        
        try await review.delete(on: req.db)
        return .noContent
    }

    // MARK: - 私有方法
    private func getPlanRatingStats(planId: UUID, on database: any Database) async throws -> (averageRating: Double?, reviewCount: Int) {
        let reviews = try await PlanReview.query(on: database)
            .filter(\.$plan.$id == planId)
            .all()
        
        let reviewCount = reviews.count
        let averageRating = reviewCount > 0 ? Double(reviews.map(\.rating).reduce(0, +)) / Double(reviewCount) : nil
        
        return (averageRating, reviewCount)
    }
}

// MARK: - 认证中间件
struct UserAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 从网关传递的用户信息中获取用户ID
        guard let userIdString = request.headers.first(name: "X-User-ID"),
              let userId = UUID(uuidString: userIdString) else {
            throw Abort(.unauthorized, reason: "User authentication required")
        }
        
        request.storage[UserIDKey.self] = userId
        return try await next.respond(to: request)
    }
}

struct AdminAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 这里应该检查用户是否有管理员权限
        // 暂时简化处理
        guard let _ = request.headers.first(name: "X-User-ID") else {
            throw Abort(.unauthorized, reason: "Admin authentication required")
        }
        
        return try await next.respond(to: request)
    }
}

struct UserIDKey: StorageKey {
    typealias Value = UUID
}
