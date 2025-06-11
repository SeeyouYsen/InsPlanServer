import Vapor
import Fluent
import FluentPostgresDriver

public func configure(_ app: Application) async throws {
    // Configure database
    let postgresConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "insplan",
        password: Environment.get("DATABASE_PASSWORD") ?? "insplan_password",
        database: Environment.get("DATABASE_NAME") ?? "notification_service",
        tls: .prefer(try .init(configuration: .clientDefault))
    )
    
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

    // Configure migrations
    app.migrations.add(CreateNotification())

    // Configure middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // Configure routes
    try routes(app)

    // Run migrations
    try await app.autoMigrate()
}
