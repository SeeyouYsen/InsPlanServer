#!/bin/bash

# InsPlan 微服务部署脚本

set -e

echo "🚀 开始部署 InsPlan 微服务架构..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查系统依赖...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 依赖检查完成${NC}"
}

# 构建服务
build_services() {
    echo -e "${BLUE}构建微服务镜像...${NC}"
    
    # 构建 API 网关
    echo -e "${YELLOW}构建 API Gateway...${NC}"
    cd api-gateway
    docker build -t insplan/api-gateway:latest .
    cd ..
    
    # 构建用户服务
    echo -e "${YELLOW}构建 User Service...${NC}"
    cd services/user-service
    docker build -t insplan/user-service:latest .
    cd ../..
    
    # 构建计划服务
    echo -e "${YELLOW}构建 Plan Service...${NC}"
    cd services/plan-service
    docker build -t insplan/plan-service:latest .
    cd ../..
    
    # 构建订单服务
    echo -e "${YELLOW}构建 Order Service...${NC}"
    cd services/order-service
    docker build -t insplan/order-service:latest .
    cd ../..
    
    # 构建支付服务
    echo -e "${YELLOW}构建 Payment Service...${NC}"
    cd services/payment-service
    docker build -t insplan/payment-service:latest .
    cd ../..
    
    # 构建通知服务
    echo -e "${YELLOW}构建 Notification Service...${NC}"
    cd services/notification-service
    docker build -t insplan/notification-service:latest .
    cd ../..
    
    echo -e "${GREEN}✅ 服务构建完成${NC}"
}

# 启动基础设施
start_infrastructure() {
    echo -e "${BLUE}启动基础设施服务...${NC}"
    
    # 启动数据库和消息队列
    docker-compose up -d postgres redis consul
    
    # 等待服务启动
    echo -e "${YELLOW}等待数据库启动...${NC}"
    sleep 10
    
    # 检查数据库连接
    docker-compose exec postgres pg_isready -U postgres
    
    echo -e "${GREEN}✅ 基础设施启动完成${NC}"
}

# 启动应用服务
start_services() {
    echo -e "${BLUE}启动应用服务...${NC}"
    
    # 启动所有服务
    docker-compose up -d
    
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 15
    
    # 检查服务健康状态
    check_health
    
    echo -e "${GREEN}✅ 应用服务启动完成${NC}"
}

# 健康检查
check_health() {
    echo -e "${BLUE}检查服务健康状态...${NC}"
    
    services=(
        "api-gateway:8080"
        "user-service:8001"
        "plan-service:8002"
        "order-service:8083"
        "payment-service:8003"
        "notification-service:8004"
    )
    
    for service in "${services[@]}"; do
        name=$(echo $service | cut -d: -f1)
        port=$(echo $service | cut -d: -f2)
        
        echo -n "检查 $name (端口 $port)... "
        
        max_attempts=30
        attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s http://localhost:$port/health > /dev/null 2>&1; then
                echo -e "${GREEN}✅ 健康${NC}"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${RED}❌ 不健康${NC}"
                echo "查看日志: docker-compose logs $name"
            fi
            
            sleep 2
            ((attempt++))
        done
    done
}

# 运行数据库迁移
run_migrations() {
    echo -e "${BLUE}运行数据库迁移...${NC}"
    
    # 用户服务迁移
    echo -e "${YELLOW}运行用户服务迁移...${NC}"
    docker-compose exec user-service ./UserService migrate --yes
    
    # 计划服务迁移
    echo -e "${YELLOW}运行计划服务迁移...${NC}"
    docker-compose exec plan-service ./PlanService migrate --yes
    
    # 订单服务迁移
    echo -e "${YELLOW}运行订单服务迁移...${NC}"
    docker-compose exec order-service ./OrderService migrate --yes
    
    # 支付服务迁移
    echo -e "${YELLOW}运行支付服务迁移...${NC}"
    docker-compose exec payment-service ./PaymentService migrate --yes
    
    # 通知服务迁移
    echo -e "${YELLOW}运行通知服务迁移...${NC}"
    docker-compose exec notification-service ./NotificationService migrate --yes
    
    echo -e "${GREEN}✅ 迁移完成${NC}"
}

# 创建测试数据
create_test_data() {
    echo -e "${BLUE}创建测试数据...${NC}"
    
    # 创建测试用户
    curl -X POST http://localhost:8080/api/v1/users/register \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "password": "password123",
            "firstName": "Test",
            "lastName": "User"
        }' || true
    
    # 创建测试保险计划
    curl -X POST http://localhost:8080/api/v1/plans \
        -H "Content-Type: application/json" \
        -d '{
            "name": "基础健康保险",
            "description": "提供基本的医疗保障",
            "premium": 299.99,
            "coverageAmount": 100000.0,
            "durationMonths": 12,
            "category": "health",
            "features": [
                {
                    "featureName": "门诊医疗",
                    "featureDescription": "涵盖门诊医疗费用",
                    "isIncluded": true
                },
                {
                    "featureName": "住院医疗",
                    "featureDescription": "涵盖住院医疗费用",
                    "isIncluded": true
                }
            ]
        }' || true
    
    echo -e "${GREEN}✅ 测试数据创建完成${NC}"
}

# 显示服务信息
show_services() {
    echo -e "\n${GREEN}🎉 InsPlan 微服务部署完成!${NC}\n"
    
    echo -e "${BLUE}服务访问地址:${NC}"
    echo "  API Gateway:  http://localhost:8080"
    echo "  User Service: http://localhost:8081"
    echo "  Plan Service: http://localhost:8082"
    echo ""
    echo -e "${BLUE}管理工具:${NC}"
    echo "  Consul:       http://localhost:8500"
    echo "  Prometheus:   http://localhost:9090"
    echo "  Grafana:      http://localhost:3000 (admin/admin)"
    echo "  Kibana:       http://localhost:5601"
    echo ""
    echo -e "${BLUE}API 文档:${NC}"
    echo "  http://localhost:8080/docs"
    echo ""
    echo -e "${BLUE}健康检查:${NC}"
    echo "  curl http://localhost:8080/health"
    echo ""
    echo -e "${BLUE}测试用户:${NC}"
    echo "  Email: test@example.com"
    echo "  Password: password123"
    echo ""
    echo -e "${YELLOW}使用 'docker-compose logs [service-name]' 查看日志${NC}"
    echo -e "${YELLOW}使用 'docker-compose down' 停止所有服务${NC}"
}

# 主函数
main() {
    case "${1:-deploy}" in
        "deploy")
            check_dependencies
            build_services
            start_infrastructure
            start_services
            run_migrations
            create_test_data
            show_services
            ;;
        "build")
            build_services
            ;;
        "start")
            start_services
            ;;
        "health")
            check_health
            ;;
        "stop")
            echo -e "${YELLOW}停止所有服务...${NC}"
            docker-compose down
            echo -e "${GREEN}✅ 服务已停止${NC}"
            ;;
        "clean")
            echo -e "${YELLOW}清理所有服务和数据...${NC}"
            docker-compose down -v --remove-orphans
            docker system prune -f
            echo -e "${GREEN}✅ 清理完成${NC}"
            ;;
        "logs")
            docker-compose logs -f "${2:-}"
            ;;
        *)
            echo "用法: $0 {deploy|build|start|health|stop|clean|logs [service-name]}"
            echo ""
            echo "命令说明:"
            echo "  deploy  - 完整部署 (默认)"
            echo "  build   - 只构建镜像"
            echo "  start   - 只启动服务"
            echo "  health  - 检查服务健康状态"
            echo "  stop    - 停止所有服务"
            echo "  clean   - 清理所有服务和数据"
            echo "  logs    - 查看服务日志"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
