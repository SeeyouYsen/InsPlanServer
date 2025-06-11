import Fluent

struct CreateInsurancePlan: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let planCategory = try await database.enum("plan_category")
            .case("health")
            .case("life")
            .case("auto")
            .case("home")
            .case("travel")
            .case("business")
            .create()
        
        try await database.schema("insurance_plans")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("premium", .double, .required)
            .field("coverage_amount", .double, .required)
            .field("duration_months", .int, .required)
            .field("category", planCategory, .required)
            .field("is_active", .bool, .required)
            .field("terms_conditions", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("insurance_plans").delete()
        try await database.enum("plan_category").delete()
    }
}

struct CreatePlanFeature: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("plan_features")
            .id()
            .field("plan_id", .uuid, .required, .references("insurance_plans", "id", onDelete: .cascade))
            .field("feature_name", .string, .required)
            .field("feature_description", .string, .required)
            .field("is_included", .bool, .required)
            .field("additional_cost", .double)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("plan_features").delete()
    }
}

struct CreatePlanReview: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("plan_reviews")
            .id()
            .field("plan_id", .uuid, .required, .references("insurance_plans", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required)
            .field("rating", .int, .required)
            .field("comment", .string)
            .field("created_at", .datetime)
            .unique(on: "plan_id", "user_id") // 每个用户对每个计划只能评价一次
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("plan_reviews").delete()
    }
}
