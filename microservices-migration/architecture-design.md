# 微服务架构设计文档

## 1. 业务域分析

### 1.1 从当前 Todo 业务到保险计划业务的映射

```swift
// 当前简单的 Todo 模型
final class Todo: Model {
    @ID var id: UUID?
    @Field(key: "title") var title: String
}

// 扩展为保险计划相关的业务模型
final class InsurancePlan: Model {
    @ID var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String
    @Field(key: "premium") var premium: Decimal
    @Field(key: "coverage") var coverage: String
    @Field(key: "duration") var duration: Int
}
```

### 1.2 业务边界划分 (Domain-Driven Design)

#### 用户上下文 (User Context)
- **实体**: User, Profile, Authentication
- **职责**: 用户注册、登录、资料管理
- **数据**: 用户基本信息、认证信息

#### 计划上下文 (Plan Context) 
- **实体**: InsurancePlan, Category, Coverage
- **职责**: 保险产品管理、分类、覆盖范围定义
- **数据**: 产品信息、价格、条款

#### 订单上下文 (Order Context)
- **实体**: Order, OrderItem, Contract
- **职责**: 订单创建、管理、合同生成
- **数据**: 订单详情、状态流转

#### 支付上下文 (Payment Context)
- **实体**: Payment, Transaction, Invoice
- **职责**: 支付处理、账单管理
- **数据**: 支付记录、交易状态

## 2. 服务间通信设计

### 2.1 同步通信 - gRPC
```proto
// plan-service.proto
service PlanService {
    rpc GetPlan(GetPlanRequest) returns (PlanResponse);
    rpc ListPlans(ListPlansRequest) returns (ListPlansResponse);
    rpc CreatePlan(CreatePlanRequest) returns (PlanResponse);
}

message PlanResponse {
    string id = 1;
    string name = 2;
    string description = 3;
    double premium = 4;
}
```

### 2.2 异步通信 - 事件驱动
```swift
// 订单创建事件
struct OrderCreatedEvent: Codable {
    let orderId: String
    let userId: String
    let planId: String
    let amount: Decimal
    let timestamp: Date
}

// 支付完成事件
struct PaymentCompletedEvent: Codable {
    let orderId: String
    let paymentId: String
    let status: PaymentStatus
    let timestamp: Date
}
```

## 3. 数据一致性策略

### 3.1 Saga 模式
```swift
// 订单创建 Saga
class CreateOrderSaga {
    enum Step {
        case validateUser
        case reservePlan  
        case processPayment
        case createContract
        case sendNotification
    }
    
    func execute() async {
        // 分布式事务协调
    }
}
```

### 3.2 事件溯源 (Event Sourcing)
```swift
// 订单状态变更事件
protocol OrderEvent {
    var orderId: String { get }
    var timestamp: Date { get }
}

struct OrderCreated: OrderEvent { }
struct PaymentProcessed: OrderEvent { }
struct ContractGenerated: OrderEvent { }
```

## 4. 服务发现和负载均衡

### 4.1 Consul + Vapor 集成
```swift
// ServiceRegistry.swift
class ServiceRegistry {
    func register(service: ServiceInfo) async throws {
        // 向 Consul 注册服务
    }
    
    func discover(serviceName: String) async throws -> [ServiceInstance] {
        // 从 Consul 发现服务
    }
}
```

## 5. API 网关设计

### 5.1 路由配置
```yaml
# gateway-config.yaml
routes:
  - path: "/api/v1/users/*"
    service: "user-service"
    port: 8081
  
  - path: "/api/v1/plans/*"
    service: "plan-service"
    port: 8082
    
  - path: "/api/v1/orders/*"
    service: "order-service"
    port: 8083
```

### 5.2 网关中间件
```swift
// APIGateway.swift
struct APIGateway {
    func configure(_ app: Application) throws {
        // 认证中间件
        app.middleware.use(AuthenticationMiddleware())
        
        // 限流中间件
        app.middleware.use(RateLimitMiddleware())
        
        // 路由代理
        app.middleware.use(ProxyMiddleware())
    }
}
```
