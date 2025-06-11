import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

// 配置应用
public func configure(_ app: Application) async throws {
    // 数据库配置
    try app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "user_service_db",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    // JWT 配置
    let jwtSecret = Environment.get("JWT_SECRET") ?? "secret"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // 迁移
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserProfile())

    // 注册路由
    try routes(app)
    
    // 服务注册
    try await registerService(app)
}

// 路由配置
func routes(_ app: Application) throws {
    app.get { req async in
        "User Service is running!"
    }

    app.get("health") { req async in
        return ["status": "healthy", "service": "user-service"]
    }

    try app.register(collection: UserController())
}

// 服务注册到注册中心
func registerService(_ app: Application) async throws {
    let serviceInfo = ServiceInfo(
        id: "user-service-\(UUID())",
        name: "user-service",
        address: Environment.get("SERVICE_HOST") ?? "localhost",
        port: Environment.get("SERVICE_PORT").flatMap(Int.init(_:)) ?? 8081,
        healthCheck: "/health"
    )
    
    // 这里可以集成 Consul 或其他服务注册中心
    app.logger.info("Service registered: \(serviceInfo)")
}

struct ServiceInfo {
    let id: String
    let name: String
    let address: String
    let port: Int
    let healthCheck: String
}
