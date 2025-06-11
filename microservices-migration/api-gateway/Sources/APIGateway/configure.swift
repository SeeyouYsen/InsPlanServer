import Vapor
import AsyncHTTPClient
import JWT
import NIOCore

public func configure(_ app: Application) async throws {
    // HTTP 客户端配置
    app.http.client.configuration.timeout = HTTPClient.Configuration.Timeout(
        connect: .seconds(10),
        read: .seconds(30)
    )
    
    // JWT 配置 - 使用新的JWT 5.x API
    let jwtSecret: String = Environment.get("JWT_SECRET") ?? "secret"
    await app.jwt.keys.add(hmac: jwtSecret, digestAlgorithm: .sha256)
    
    // 服务发现和负载均衡器
    let serviceDiscovery: StaticServiceDiscovery = StaticServiceDiscovery()
    let loadBalancer: RoundRobinLoadBalancer = RoundRobinLoadBalancer()
    
    // 中间件配置
    app.middleware.use(CORSMiddleware())
    app.middleware.use(RateLimitMiddleware())
    app.middleware.use(AuthenticationMiddleware())
    app.middleware.use(ProxyMiddleware(
        serviceDiscovery: serviceDiscovery,
        httpClient: app.http.client.shared,
        loadBalancer: loadBalancer
    ))
    
    // 路由配置
    try routes(app)
}

func routes(_ app: Application) throws {
    // 网关健康检查
    app.get("health") { req async in
        return [
            "status": "healthy",
            "service": "api-gateway",
            "timestamp": Date().ISO8601Format()
        ]
    }
    
    // 网关状态
    app.get("gateway", "status") { req async in
        struct StatusResponse: Content {
            let gateway: String
            let version: String
            let uptime: TimeInterval
            let services: [String: String]
        }
        
        return StatusResponse(
            gateway: "api-gateway",
            version: "1.0.0",
            uptime: ProcessInfo.processInfo.systemUptime,
            services: [
                "user-service": "http://localhost:8081",
                "plan-service": "http://localhost:8082",
                "order-service": "http://localhost:8083",
                "payment-service": "http://localhost:8084"
            ]
        )
    }
    
    // API 文档路由
    app.get("docs") { req async in
        return """
        # InsPlan API Gateway
        
        ## Available Services:
        - User Service: /api/v1/users/*
        - Plan Service: /api/v1/plans/*
        - Order Service: /api/v1/orders/*
        - Payment Service: /api/v1/payments/*
        
        ## Authentication:
        - POST /api/v1/users/register
        - POST /api/v1/users/login
        - Use Bearer token for authenticated requests
        
        ## Rate Limiting:
        - 100 requests per minute per IP
        """
    }
    
    // 所有其他请求将被代理中间件处理
}
