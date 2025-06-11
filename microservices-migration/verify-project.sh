#!/bin/bash

# InsPlan 微服务项目完整性验证脚本

set -e

echo "🔍 InsPlan 微服务项目完整性验证"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查函数
check_file() {
    local file_path=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌${NC} $description (文件不存在: $file_path)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_directory() {
    local dir_path=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✅${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌${NC} $description (目录不存在: $dir_path)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo -e "${BLUE}检查项目结构...${NC}"

# 检查根目录文件
check_file "README.md" "项目说明文档"
check_file "docker-compose.yml" "Docker Compose 配置"
check_file "docker-compose.prod.yml" "生产环境 Docker Compose 配置"
check_file "deploy.sh" "部署脚本"
check_file "test-apis.sh" "API 测试脚本"
check_file "Makefile" "项目管理 Makefile"
check_file "LICENSE" "开源许可证"
check_file ".gitignore" "Git 忽略文件配置"
check_file ".env.example" "环境变量示例"
check_file "architecture-design.md" "架构设计文档"
check_file "PROJECT_COMPLETION_REPORT.md" "项目完成报告"

echo ""
echo -e "${BLUE}检查 API 网关...${NC}"

check_directory "api-gateway" "API 网关目录"
check_file "api-gateway/Package.swift" "API 网关 Package.swift"
check_file "api-gateway/Dockerfile" "API 网关 Dockerfile"
check_directory "api-gateway/Sources/APIGateway" "API 网关源码目录"

echo ""
echo -e "${BLUE}检查用户服务...${NC}"

check_directory "services/user-service" "用户服务目录"
check_file "services/user-service/Package.swift" "用户服务 Package.swift"
check_file "services/user-service/Dockerfile" "用户服务 Dockerfile"
check_directory "services/user-service/Sources/UserService" "用户服务源码目录"
check_directory "services/user-service/Sources/UserService/Controllers" "用户服务控制器目录"
check_directory "services/user-service/Sources/UserService/Models" "用户服务模型目录"
check_directory "services/user-service/Sources/UserService/DTOs" "用户服务 DTO 目录"
check_directory "services/user-service/Sources/UserService/Migrations" "用户服务迁移目录"

echo ""
echo -e "${BLUE}检查计划服务...${NC}"

check_directory "services/plan-service" "计划服务目录"
check_file "services/plan-service/Package.swift" "计划服务 Package.swift"
check_file "services/plan-service/Dockerfile" "计划服务 Dockerfile"
check_directory "services/plan-service/Sources/PlanService" "计划服务源码目录"

echo ""
echo -e "${BLUE}检查订单服务...${NC}"

check_directory "services/order-service" "订单服务目录"
check_file "services/order-service/Package.swift" "订单服务 Package.swift"
check_file "services/order-service/Dockerfile" "订单服务 Dockerfile"
check_directory "services/order-service/Sources/OrderService" "订单服务源码目录"

echo ""
echo -e "${BLUE}检查支付服务...${NC}"

check_directory "services/payment-service" "支付服务目录"
check_file "services/payment-service/Package.swift" "支付服务 Package.swift"
check_file "services/payment-service/Dockerfile" "支付服务 Dockerfile"
check_directory "services/payment-service/Sources/PaymentService" "支付服务源码目录"
check_file "services/payment-service/Sources/PaymentService/main.swift" "支付服务主文件"
check_file "services/payment-service/Sources/PaymentService/Controllers/PaymentController.swift" "支付控制器"
check_file "services/payment-service/Sources/PaymentService/Models/Payment.swift" "支付模型"
check_file "services/payment-service/Sources/PaymentService/DTOs/PaymentDTO.swift" "支付 DTO"
check_file "services/payment-service/Sources/PaymentService/Services/PaymentGateway.swift" "支付网关服务"
check_file "services/payment-service/Sources/PaymentService/Migrations/CreatePayment.swift" "支付迁移"

echo ""
echo -e "${BLUE}检查通知服务...${NC}"

check_directory "services/notification-service" "通知服务目录"
check_file "services/notification-service/Package.swift" "通知服务 Package.swift"
check_file "services/notification-service/Dockerfile" "通知服务 Dockerfile"
check_directory "services/notification-service/Sources/NotificationService" "通知服务源码目录"
check_file "services/notification-service/Sources/NotificationService/main.swift" "通知服务主文件"
check_file "services/notification-service/Sources/NotificationService/Controllers/NotificationController.swift" "通知控制器"
check_file "services/notification-service/Sources/NotificationService/Models/Notification.swift" "通知模型"
check_file "services/notification-service/Sources/NotificationService/DTOs/NotificationDTO.swift" "通知 DTO"
check_file "services/notification-service/Sources/NotificationService/Services/NotificationService.swift" "通知服务"
check_file "services/notification-service/Sources/NotificationService/Migrations/CreateNotification.swift" "通知迁移"

echo ""
echo -e "${BLUE}检查共享组件...${NC}"

check_directory "services/shared" "共享组件目录"
check_file "services/shared/ServiceClients.swift" "服务间通信客户端"

echo ""
echo -e "${BLUE}检查基础设施配置...${NC}"

check_directory "infrastructure" "基础设施目录"
check_directory "infrastructure/kubernetes" "Kubernetes 配置目录"
check_file "infrastructure/kubernetes/deployment.yaml" "Kubernetes 部署配置"
check_directory "infrastructure/monitoring" "监控配置目录"
check_file "infrastructure/monitoring/prometheus.yml" "Prometheus 配置"
check_file "infrastructure/monitoring/logstash.conf" "Logstash 配置"

echo ""
echo -e "${BLUE}检查脚本权限...${NC}"

if [ -x "deploy.sh" ]; then
    echo -e "${GREEN}✅${NC} deploy.sh 脚本可执行"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠️${NC} deploy.sh 脚本不可执行，正在修复..."
    chmod +x deploy.sh
fi

if [ -x "test-apis.sh" ]; then
    echo -e "${GREEN}✅${NC} test-apis.sh 脚本可执行"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠️${NC} test-apis.sh 脚本不可执行，正在修复..."
    chmod +x test-apis.sh
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 2))

echo ""
echo "========================================"
echo -e "${BLUE}验证结果汇总${NC}"
echo "========================================"
echo -e "总检查项: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "通过项目: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "失败项目: ${RED}$FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 恭喜！InsPlan 微服务项目完整性验证通过！${NC}"
    echo -e "${GREEN}项目已准备就绪，可以开始部署和使用。${NC}"
    echo ""
    echo -e "${BLUE}下一步操作建议：${NC}"
    echo "1. 复制 .env.example 为 .env 并配置环境变量"
    echo "2. 运行 'make start' 启动所有服务"
    echo "3. 运行 'make test' 执行 API 测试"
    echo "4. 访问 http://localhost:8080 查看 API 网关"
    echo "5. 访问 http://localhost:3000 查看 Grafana 监控面板"
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ 项目完整性验证失败！${NC}"
    echo -e "${RED}请检查并修复上述失败项目后重新运行验证。${NC}"
    
    exit 1
fi
