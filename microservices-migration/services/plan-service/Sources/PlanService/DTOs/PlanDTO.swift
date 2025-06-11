import Fluent
import Vapor

// MARK: - 计划创建 DTO
struct CreatePlanRequest: Content {
    let name: String
    let description: String
    let premium: Double
    let coverageAmount: Double
    let durationMonths: Int
    let category: PlanCategory
    let termsConditions: String?
    let features: [CreateFeatureRequest]?
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Plan name is required")
        }
        guard premium > 0 else {
            throw Abort(.badRequest, reason: "Premium must be greater than 0")
        }
        guard coverageAmount > 0 else {
            throw Abort(.badRequest, reason: "Coverage amount must be greater than 0")
        }
        guard durationMonths > 0 else {
            throw Abort(.badRequest, reason: "Duration must be greater than 0")
        }
    }
}

// MARK: - 特性创建 DTO
struct CreateFeatureRequest: Content {
    let featureName: String
    let featureDescription: String
    let isIncluded: Bool
    let additionalCost: Double?
}

// MARK: - 计划更新 DTO
struct UpdatePlanRequest: Content {
    let name: String?
    let description: String?
    let premium: Double?
    let coverageAmount: Double?
    let durationMonths: Int?
    let category: PlanCategory?
    let isActive: Bool?
    let termsConditions: String?
}

// MARK: - 计划查询 DTO
struct PlanQueryRequest: Content {
    let category: PlanCategory?
    let minPremium: Double?
    let maxPremium: Double?
    let minCoverage: Double?
    let maxCoverage: Double?
    let maxDuration: Int?
    let isActive: Bool?
    let page: Int?
    let pageSize: Int?
}

// MARK: - 计划响应 DTO
struct PlanResponse: Content {
    let id: UUID
    let name: String
    let description: String
    let premium: Double
    let coverageAmount: Double
    let durationMonths: Int
    let category: PlanCategory
    let isActive: Bool
    let termsConditions: String?
    let averageRating: Double?
    let reviewCount: Int
    var features: [FeatureResponse]?
    let createdAt: Date?
}

// MARK: - 特性响应 DTO
struct FeatureResponse: Content {
    let id: UUID
    let featureName: String
    let featureDescription: String
    let isIncluded: Bool
    let additionalCost: Double?
}

// MARK: - 评价创建 DTO
struct CreateReviewRequest: Content {
    let rating: Int
    let comment: String?
    
    func validate() throws {
        guard rating >= 1 && rating <= 5 else {
            throw Abort(.badRequest, reason: "Rating must be between 1 and 5")
        }
    }
}

// MARK: - 评价更新 DTO
struct UpdateReviewRequest: Content {
    let rating: Int?
    let comment: String?
    
    func validate() throws {
        if let rating = rating {
            guard rating >= 1 && rating <= 5 else {
                throw Abort(.badRequest, reason: "Rating must be between 1 and 5")
            }
        }
    }
}

// MARK: - 评价响应 DTO
struct ReviewResponse: Content {
    let id: UUID
    let userId: UUID
    let rating: Int
    let comment: String?
    let createdAt: Date?
}

// MARK: - 分页响应 DTO
struct PaginatedPlansResponse: Content {
    let plans: [PlanResponse]
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}

// MARK: - Model Extensions
extension InsurancePlan {
    func toResponse(includeFeatures: Bool = false, averageRating: Double? = nil, reviewCount: Int = 0) -> PlanResponse {
        PlanResponse(
            id: self.id!,
            name: self.name,
            description: self.description,
            premium: self.premium,
            coverageAmount: self.coverageAmount,
            durationMonths: self.durationMonths,
            category: self.category,
            isActive: self.isActive,
            termsConditions: self.termsConditions,
            averageRating: averageRating,
            reviewCount: reviewCount,
            features: includeFeatures ? nil : nil, // 将在控制器中加载
            createdAt: self.createdAt
        )
    }
}

extension PlanFeature {
    func toResponse() -> FeatureResponse {
        FeatureResponse(
            id: self.id!,
            featureName: self.featureName,
            featureDescription: self.featureDescription,
            isIncluded: self.isIncluded,
            additionalCost: self.additionalCost
        )
    }
}

extension PlanReview {
    func toResponse() -> ReviewResponse {
        ReviewResponse(
            id: self.id!,
            userId: self.userId,
            rating: self.rating,
            comment: self.comment,
            createdAt: self.createdAt
        )
    }
}
