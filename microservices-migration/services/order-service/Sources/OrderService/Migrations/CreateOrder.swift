import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let orderStatus = try await database.enum("order_status")
            .case("pending")
            .case("confirmed")
            .case("paid")
            .case("active")
            .case("cancelled")
            .case("expired")
            .create()
        
        try await database.schema("orders")
            .id()
            .field("user_id", .uuid, .required)
            .field("plan_id", .uuid, .required)
            .field("order_number", .string, .required)
            .field("status", orderStatus, .required)
            .field("premium_amount", .double, .required)
            .field("coverage_amount", .double, .required)
            .field("duration_months", .int, .required)
            .field("start_date", .date)
            .field("end_date", .date)
            .field("notes", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "order_number")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("orders").delete()
        try await database.enum("order_status").delete()
    }
}

struct CreateOrderItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("order_items")
            .id()
            .field("order_id", .uuid, .required, .references("orders", "id", onDelete: .cascade))
            .field("feature_name", .string, .required)
            .field("feature_description", .string, .required)
            .field("cost", .double, .required)
            .field("is_included", .bool, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("order_items").delete()
    }
}
