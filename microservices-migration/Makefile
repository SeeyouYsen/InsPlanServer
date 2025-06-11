# InsPlan 微服务管理 Makefile

.PHONY: help build start stop clean test logs health deploy-k8s

# 默认目标
help:
	@echo "InsPlan 微服务管理命令"
	@echo "======================="
	@echo "build       - 构建所有服务镜像"
	@echo "start       - 启动所有服务"
	@echo "stop        - 停止所有服务"
	@echo "restart     - 重启所有服务"
	@echo "clean       - 清理容器和镜像"
	@echo "test        - 运行 API 测试"
	@echo "logs        - 查看服务日志"
	@echo "health      - 检查服务健康状态"
	@echo "deploy-k8s  - 部署到 Kubernetes"
	@echo "scale       - 扩展服务实例"
	@echo "monitoring  - 启动监控服务"

# 构建所有服务
build:
	@echo "🔨 构建所有服务镜像..."
	@docker-compose build

# 启动所有服务
start:
	@echo "🚀 启动所有服务..."
	@docker-compose up -d

# 停止所有服务
stop:
	@echo "🛑 停止所有服务..."
	@docker-compose down

# 重启所有服务
restart: stop start

# 清理容器和镜像
clean:
	@echo "🧹 清理容器和镜像..."
	@docker-compose down -v --rmi all --remove-orphans
	@docker system prune -f

# 运行 API 测试
test:
	@echo "🧪 运行 API 测试..."
	@chmod +x ./test-apis.sh
	@./test-apis.sh

# 查看服务日志
logs:
	@echo "📋 查看服务日志..."
	@docker-compose logs -f

# 检查服务健康状态
health:
	@echo "💓 检查服务健康状态..."
	@echo "API Gateway: " && curl -s http://localhost:8080/health | jq .
	@echo "User Service: " && curl -s http://localhost:8001/health | jq .
	@echo "Plan Service: " && curl -s http://localhost:8002/health | jq .
	@echo "Order Service: " && curl -s http://localhost:8083/health | jq .
	@echo "Payment Service: " && curl -s http://localhost:8003/health | jq .
	@echo "Notification Service: " && curl -s http://localhost:8004/health | jq .

# 部署到 Kubernetes
deploy-k8s:
	@echo "☸️ 部署到 Kubernetes..."
	@kubectl apply -f infrastructure/kubernetes/deployment.yaml

# 扩展服务实例
scale:
	@echo "📈 扩展服务实例..."
	@docker-compose up --scale user-service=3 --scale plan-service=2 --scale order-service=2 -d

# 启动监控服务
monitoring:
	@echo "📊 启动监控服务..."
	@docker-compose up -d prometheus grafana elasticsearch logstash kibana

# 查看特定服务日志
logs-user:
	@docker-compose logs -f user-service

logs-plan:
	@docker-compose logs -f plan-service

logs-order:
	@docker-compose logs -f order-service

logs-payment:
	@docker-compose logs -f payment-service

logs-notification:
	@docker-compose logs -f notification-service

logs-gateway:
	@docker-compose logs -f api-gateway

# 数据库迁移
migrate:
	@echo "🗃️ 运行数据库迁移..."
	@docker-compose exec user-service ./UserService migrate --yes
	@docker-compose exec plan-service ./PlanService migrate --yes
	@docker-compose exec order-service ./OrderService migrate --yes
	@docker-compose exec payment-service ./PaymentService migrate --yes
	@docker-compose exec notification-service ./NotificationService migrate --yes

# 备份数据库
backup:
	@echo "💾 备份数据库..."
	@docker-compose exec postgres pg_dumpall -U postgres > backup_$(shell date +%Y%m%d_%H%M%S).sql

# 生成测试数据
seed:
	@echo "🌱 生成测试数据..."
	@curl -X POST http://localhost:8001/api/users/register \
		-H "Content-Type: application/json" \
		-d '{"username":"testuser","email":"test@example.com","password":"password123","phone":"13800138000"}'

# 性能测试
perf-test:
	@echo "⚡ 运行性能测试..."
	@ab -n 1000 -c 10 http://localhost:8080/api/plans
	@ab -n 1000 -c 10 http://localhost:8080/api/users

# 安全扫描
security-scan:
	@echo "🔒 运行安全扫描..."
	@docker run --rm -v $(PWD):/app -w /app securecodewarrior/docker-security-scanning

# 代码质量检查
lint:
	@echo "🧹 代码质量检查..."
	@swiftlint lint --config .swiftlint.yml

# 生成 API 文档
docs:
	@echo "📚 生成 API 文档..."
	@echo "API 文档将在各服务启动后可用"
	@echo "访问 http://localhost:8080/docs 查看 API 文档"

# 开发环境快速启动
dev:
	@echo "🛠️ 启动开发环境..."
	@docker-compose up -d postgres redis consul
	@sleep 5
	@echo "基础设施已启动，现在可以单独运行服务进行开发"

# 生产环境部署
prod-deploy:
	@echo "🚀 生产环境部署..."
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 回滚部署
rollback:
	@echo "⏪ 回滚部署..."
	@kubectl rollout undo deployment/user-service -n insplan
	@kubectl rollout undo deployment/plan-service -n insplan
	@kubectl rollout undo deployment/order-service -n insplan
	@kubectl rollout undo deployment/payment-service -n insplan
	@kubectl rollout undo deployment/notification-service -n insplan

# 查看资源使用情况
stats:
	@echo "📊 查看资源使用情况..."
	@docker stats --no-stream
