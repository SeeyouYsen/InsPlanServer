import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("phone", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}

struct CreateUserProfile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_profiles")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("birth_date", .date)
            .field("gender", .string)
            .field("address", .string)
            .field("city", .string)
            .field("country", .string)
            .field("occupation", .string)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_profiles").delete()
    }
}
