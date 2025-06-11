import Vapor
import AsyncHTTPClient

// HTTP 客户端管理器
class HTTPClientManager {
    static let shared = HTTPClientManager()
    private let httpClient: HTTPClient
    
    private init() {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    func getClient() -> HTTPClient {
        return httpClient
    }
}

// 用户服务客户端
class UserServiceClient {
    private let baseURL: String
    private let httpClient: HTTPClient
    
    init(baseURL: String = "http://user-service:8001") {
        self.baseURL = baseURL
        self.httpClient = HTTPClientManager.shared.getClient()
    }
    
    func getUser(id: UUID) async throws -> UserDTO? {
        let url = "\(baseURL)/api/users/\(id)"
        var request = HTTPClientRequest(url: url)
        request.method = .GET
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        
        if response.status == .ok {
            let data = try await response.body.collect(upTo: 1024 * 1024) // 1MB max
            return try JSONDecoder().decode(UserDTO.self, from: data)
        }
        
        return nil
    }
    
    func validateUser(id: UUID) async throws -> Bool {
        let user = try await getUser(id: id)
        return user != nil
    }
}

// 计划服务客户端
class PlanServiceClient {
    private let baseURL: String
    private let httpClient: HTTPClient
    
    init(baseURL: String = "http://plan-service:8002") {
        self.baseURL = baseURL
        self.httpClient = HTTPClientManager.shared.getClient()
    }
    
    func getPlan(id: UUID) async throws -> InsurancePlanDTO? {
        let url = "\(baseURL)/api/plans/\(id)"
        var request = HTTPClientRequest(url: url)
        request.method = .GET
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        
        if response.status == .ok {
            let data = try await response.body.collect(upTo: 1024 * 1024)
            return try JSONDecoder().decode(InsurancePlanDTO.self, from: data)
        }
        
        return nil
    }
    
    func validatePlan(id: UUID) async throws -> Bool {
        let plan = try await getPlan(id: id)
        return plan != nil && plan!.isActive
    }
}

// 订单服务客户端
class OrderServiceClient {
    private let baseURL: String
    private let httpClient: HTTPClient
    
    init(baseURL: String = "http://order-service:8083") {
        self.baseURL = baseURL
        self.httpClient = HTTPClientManager.shared.getClient()
    }
    
    func getOrder(id: UUID) async throws -> OrderDTO? {
        let url = "\(baseURL)/api/orders/\(id)"
        var request = HTTPClientRequest(url: url)
        request.method = .GET
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        
        if response.status == .ok {
            let data = try await response.body.collect(upTo: 1024 * 1024)
            return try JSONDecoder().decode(OrderDTO.self, from: data)
        }
        
        return nil
    }
    
    func updateOrderStatus(id: UUID, status: String) async throws -> Bool {
        let url = "\(baseURL)/api/orders/\(id)/status"
        var request = HTTPClientRequest(url: url)
        request.method = .PUT
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let updateData = ["status": status]
        let jsonData = try JSONEncoder().encode(updateData)
        request.body = .bytes(jsonData)
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        return response.status == .ok
    }
}

// 支付服务客户端
class PaymentServiceClient {
    private let baseURL: String
    private let httpClient: HTTPClient
    
    init(baseURL: String = "http://payment-service:8003") {
        self.baseURL = baseURL
        self.httpClient = HTTPClientManager.shared.getClient()
    }
    
    func createPayment(orderID: UUID, userID: UUID, amount: Double, currency: String, method: String) async throws -> PaymentDTO? {
        let url = "\(baseURL)/api/payments"
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let paymentData = [
            "orderID": orderID.uuidString,
            "userID": userID.uuidString,
            "amount": amount,
            "currency": currency,
            "method": method
        ] as [String : Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: paymentData)
        request.body = .bytes(jsonData)
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        
        if response.status == .ok || response.status == .created {
            let data = try await response.body.collect(upTo: 1024 * 1024)
            return try JSONDecoder().decode(PaymentDTO.self, from: data)
        }
        
        return nil
    }
    
    func getPaymentByOrderID(orderID: UUID) async throws -> PaymentDTO? {
        let url = "\(baseURL)/api/payments/order/\(orderID)"
        var request = HTTPClientRequest(url: url)
        request.method = .GET
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        
        if response.status == .ok {
            let data = try await response.body.collect(upTo: 1024 * 1024)
            return try JSONDecoder().decode(PaymentDTO.self, from: data)
        }
        
        return nil
    }
}

// 通知服务客户端
class NotificationServiceClient {
    private let baseURL: String
    private let httpClient: HTTPClient
    
    init(baseURL: String = "http://notification-service:8004") {
        self.baseURL = baseURL
        self.httpClient = HTTPClientManager.shared.getClient()
    }
    
    func sendNotification(userID: UUID, type: String, channel: String, recipient: String, templateID: String, templateData: [String: String]) async throws -> Bool {
        let url = "\(baseURL)/api/notifications/send"
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let notificationData = [
            "userID": userID.uuidString,
            "type": type,
            "channel": channel,
            "recipient": recipient,
            "templateID": templateID,
            "templateData": templateData
        ] as [String : Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: notificationData)
        request.body = .bytes(jsonData)
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        return response.status == .ok || response.status == .created
    }
}

// 基础 DTO 结构（用于服务间通信）
struct UserDTO: Codable {
    let id: UUID
    let username: String
    let email: String
    let phone: String?
    let isActive: Bool
    let createdAt: Date?
}

struct InsurancePlanDTO: Codable {
    let id: UUID
    let name: String
    let description: String
    let category: String
    let premium: Double
    let coverage: Double
    let duration: Int
    let isActive: Bool
    let createdAt: Date?
}

struct OrderDTO: Codable {
    let id: UUID
    let userID: UUID
    let planID: UUID
    let status: String
    let totalAmount: Double
    let createdAt: Date?
    let updatedAt: Date?
}

struct PaymentDTO: Codable {
    let id: UUID
    let orderID: UUID
    let userID: UUID
    let amount: Double
    let currency: String
    let status: String
    let method: String
    let transactionID: String?
    let createdAt: Date?
}