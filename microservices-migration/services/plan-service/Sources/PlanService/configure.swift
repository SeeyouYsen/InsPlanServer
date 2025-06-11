import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    // 数据库配置
    let dbConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "plan_service_db",
        tls: .disable
    )
    
    app.databases.use(.postgres(configuration: dbConfig), as: .psql)

    // 迁移
    app.migrations.add(CreateInsurancePlan())
    app.migrations.add(CreatePlanFeature())
    app.migrations.add(CreatePlanReview())

    // 注册路由
    try routes(app)
    
    // 服务注册
    try await registerService(app)
}

func routes(_ app: Application) throws {
    app.get { req async in
        "Plan Service is running!"
    }

    app.get("health") { req async in
        return [
            "status": "healthy", 
            "service": "plan-service",
            "timestamp": Date().ISO8601Format()
        ]
    }

    try app.register(collection: PlanController())
}

func registerService(_ app: Application) async throws {
    let serviceInfo = ServiceInfo(
        id: "plan-service-\(UUID())",
        name: "plan-service",
        address: Environment.get("SERVICE_HOST") ?? "localhost",
        port: Environment.get("SERVICE_PORT").flatMap(Int.init(_:)) ?? 8082,
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
