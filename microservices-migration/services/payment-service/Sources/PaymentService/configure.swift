import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    // 数据库配置
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432
    let username = Environment.get("DATABASE_USERNAME") ?? "insplan"
    let password = Environment.get("DATABASE_PASSWORD") ?? "insplan_password"
    let database = Environment.get("DATABASE_NAME") ?? "payment_service"
    let tlsConfig = try NIOSSLContext(configuration: .clientDefault)
    
    let postgresConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: .prefer(tlsConfig)
    )
    
    try app.databases.use(DatabaseConfigurationFactory.postgres(configuration: postgresConfig), as: .psql)

    // 迁移
    app.migrations.add(CreatePayment())

    // 中间件配置
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // 注册路由
    try routes(app)
}
