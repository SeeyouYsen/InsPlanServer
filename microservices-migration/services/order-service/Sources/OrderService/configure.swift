import Vapor
import Fluent
import FluentPostgresDriver
import SQLKit

public func configure(_ app: Application) async throws {
    // Configure database
    var postgresConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "insplan",
        password: Environment.get("DATABASE_PASSWORD") ?? "insplan_password",
        database: Environment.get("DATABASE_NAME") ?? "order_service",
        tls: .disable
    )
    
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: postgresConfig), as: .psql)

    // Configure migrations
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateOrderItem())

    // Configure middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // Configure routes
    try routes(app)
    
    // 服务注册
    try await registerService(app)

    // Run migrations
    try await app.autoMigrate()
}

func routes(_ app: Application) throws {
    app.get { req async in
        "Order Service is running!"
    }

    app.get("health") { req async in
        return [
            "status": "healthy", 
            "service": "order-service",
            "timestamp": Date().ISO8601Format()
        ]
    }

    try app.register(collection: OrderController())
}

func registerService(_ app: Application) async throws {
    let serviceInfo = ServiceInfo(
        id: "order-service-\(UUID())",
        name: "order-service",
        address: Environment.get("SERVICE_HOST") ?? "localhost",
        port: Environment.get("SERVICE_PORT").flatMap(Int.init(_:)) ?? 8083,
        healthCheck: "/health"
    )
    
    app.logger.info("Service registered: \(serviceInfo)")
}

struct ServiceInfo {
    let id: String
    let name: String
    let address: String
    let port: Int
    let healthCheck: String
}
