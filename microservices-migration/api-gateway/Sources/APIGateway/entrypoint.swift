import Vapor
import Logging
import NIOCore
import NIOPosix

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)
        
        // 设置网关端口
        app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init(_:)) ?? 8080
        
        // 设置服务器配置
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.responseCompression = .enabled
        
        do {
            try await configure(app)
            
            // 启动信息
            app.logger.info("🚀 API Gateway starting on port \(app.http.server.configuration.port)")
            app.logger.info("📚 API Documentation available at: http://localhost:\(app.http.server.configuration.port)/docs")
            
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
