import Fluent
import Vapor

// MARK: - 保险计划模型
final class InsurancePlan: Model, @unchecked Sendable {
    static let schema = "insurance_plans"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "premium")
    var premium: Double
    
    @Field(key: "coverage_amount")
    var coverageAmount: Double
    
    @Field(key: "duration_months")
    var durationMonths: Int
    
    @Enum(key: "category")
    var category: PlanCategory
    
    @Field(key: "is_active")
    var isActive: Bool
    
    @Field(key: "terms_conditions")
    var termsConditions: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$plan)
    var features: [PlanFeature]
    
    @Children(for: \.$plan)
    var reviews: [PlanReview]

    init() { }

    init(id: UUID? = nil, 
         name: String, 
         description: String, 
         premium: Double, 
         coverageAmount: Double, 
         durationMonths: Int, 
         category: PlanCategory, 
         isActive: Bool = true,
         termsConditions: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.premium = premium
        self.coverageAmount = coverageAmount
        self.durationMonths = durationMonths
        self.category = category
        self.isActive = isActive
        self.termsConditions = termsConditions
    }
}

// MARK: - 计划分类枚举
enum PlanCategory: String, Codable, CaseIterable {
    case health = "health"
    case life = "life"
    case auto = "auto"
    case home = "home"
    case travel = "travel"
    case business = "business"
}

// MARK: - 计划特性模型
final class PlanFeature: Model, @unchecked Sendable {
    static let schema = "plan_features"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "plan_id")
    var plan: InsurancePlan
    
    @Field(key: "feature_name")
    var featureName: String
    
    @Field(key: "feature_description")
    var featureDescription: String
    
    @Field(key: "is_included")
    var isIncluded: Bool
    
    @Field(key: "additional_cost")
    var additionalCost: Double?
    
    init() { }
    
    init(id: UUID? = nil, 
         planID: UUID, 
         featureName: String, 
         featureDescription: String, 
         isIncluded: Bool = true, 
         additionalCost: Double? = nil) {
        self.id = id
        self.$plan.id = planID
        self.featureName = featureName
        self.featureDescription = featureDescription
        self.isIncluded = isIncluded
        self.additionalCost = additionalCost
    }
}

// MARK: - 计划评价模型
final class PlanReview: Model, @unchecked Sendable {
    static let schema = "plan_reviews"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "plan_id")
    var plan: InsurancePlan
    
    @Field(key: "user_id")
    var userId: UUID
    
    @Field(key: "rating")
    var rating: Int // 1-5 星评价
    
    @Field(key: "comment")
    var comment: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, planID: UUID, userId: UUID, rating: Int, comment: String? = nil) {
        self.id = id
        self.$plan.id = planID
        self.userId = userId
        self.rating = rating
        self.comment = comment
    }
}


