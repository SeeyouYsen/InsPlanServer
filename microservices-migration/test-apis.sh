#!/bin/bash

# InsPlan 微服务 API 测试脚本
# 用于测试所有微服务的基本功能

set -e

API_GATEWAY_URL="http://localhost:8080"
USER_SERVICE_URL="http://localhost:8001"
PLAN_SERVICE_URL="http://localhost:8002"
ORDER_SERVICE_URL="http://localhost:8083"
PAYMENT_SERVICE_URL="http://localhost:8003"
NOTIFICATION_SERVICE_URL="http://localhost:8004"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    local service_url=$2
    
    log_info "检查 $service_name 健康状态..."
    
    if curl -s -f "$service_url/health" > /dev/null; then
        log_success "$service_name 运行正常"
        return 0
    else
        log_error "$service_name 无法访问"
        return 1
    fi
}

# 测试用户服务
test_user_service() {
    log_info "测试用户服务..."
    
    # 注册新用户
    USER_DATA='{
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123",
        "phone": "13800138000"
    }'
    
    REGISTER_RESPONSE=$(curl -s -X POST "$USER_SERVICE_URL/api/users/register" \
        -H "Content-Type: application/json" \
        -d "$USER_DATA")
    
    if echo "$REGISTER_RESPONSE" | grep -q "id"; then
        log_success "用户注册成功"
        USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.id')
        echo "用户ID: $USER_ID"
        
        # 用户登录
        LOGIN_DATA='{
            "email": "test@example.com",
            "password": "password123"
        }'
        
        LOGIN_RESPONSE=$(curl -s -X POST "$USER_SERVICE_URL/api/users/login" \
            -H "Content-Type: application/json" \
            -d "$LOGIN_DATA")
        
        if echo "$LOGIN_RESPONSE" | grep -q "token"; then
            log_success "用户登录成功"
            JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
            echo "JWT Token: $JWT_TOKEN"
        else
            log_error "用户登录失败"
        fi
    else
        log_error "用户注册失败"
    fi
}

# 测试计划服务
test_plan_service() {
    log_info "测试计划服务..."
    
    # 创建保险计划
    PLAN_DATA='{
        "name": "测试保险计划",
        "description": "这是一个测试保险计划",
        "category": "health",
        "premium": 1000.0,
        "coverage": 100000.0,
        "duration": 12,
        "features": ["医疗保障", "意外保障"],
        "terms": "保险条款内容..."
    }'
    
    PLAN_RESPONSE=$(curl -s -X POST "$PLAN_SERVICE_URL/api/plans" \
        -H "Content-Type: application/json" \
        -d "$PLAN_DATA")
    
    if echo "$PLAN_RESPONSE" | grep -q "id"; then
        log_success "保险计划创建成功"
        PLAN_ID=$(echo "$PLAN_RESPONSE" | jq -r '.id')
        echo "计划ID: $PLAN_ID"
        
        # 获取计划列表
        PLANS_RESPONSE=$(curl -s "$PLAN_SERVICE_URL/api/plans")
        if echo "$PLANS_RESPONSE" | grep -q "\["; then
            log_success "获取计划列表成功"
        else
            log_error "获取计划列表失败"
        fi
    else
        log_error "保险计划创建失败"
    fi
}

# 测试订单服务
test_order_service() {
    log_info "测试订单服务..."
    
    if [ -z "$USER_ID" ] || [ -z "$PLAN_ID" ]; then
        log_warning "跳过订单测试，缺少用户ID或计划ID"
        return
    fi
    
    # 创建订单
    ORDER_DATA='{
        "userID": "'$USER_ID'",
        "planID": "'$PLAN_ID'",
        "quantity": 1,
        "applicantInfo": {
            "name": "张三",
            "idCard": "123456789012345678",
            "phone": "13800138000",
            "email": "test@example.com"
        },
        "beneficiaryInfo": {
            "name": "李四",
            "relationship": "spouse"
        }
    }'
    
    ORDER_RESPONSE=$(curl -s -X POST "$ORDER_SERVICE_URL/api/orders" \
        -H "Content-Type: application/json" \
        -d "$ORDER_DATA")
    
    if echo "$ORDER_RESPONSE" | grep -q "id"; then
        log_success "订单创建成功"
        ORDER_ID=$(echo "$ORDER_RESPONSE" | jq -r '.id')
        echo "订单ID: $ORDER_ID"
        
        # 获取订单详情
        ORDER_DETAIL=$(curl -s "$ORDER_SERVICE_URL/api/orders/$ORDER_ID")
        if echo "$ORDER_DETAIL" | grep -q "id"; then
            log_success "获取订单详情成功"
        else
            log_error "获取订单详情失败"
        fi
    else
        log_error "订单创建失败"
    fi
}

# 测试支付服务
test_payment_service() {
    log_info "测试支付服务..."
    
    if [ -z "$ORDER_ID" ] || [ -z "$USER_ID" ]; then
        log_warning "跳过支付测试，缺少订单ID或用户ID"
        return
    fi
    
    # 创建支付
    PAYMENT_DATA='{
        "orderID": "'$ORDER_ID'",
        "userID": "'$USER_ID'",
        "amount": 1000.0,
        "currency": "CNY",
        "method": "alipay"
    }'
    
    PAYMENT_RESPONSE=$(curl -s -X POST "$PAYMENT_SERVICE_URL/api/payments" \
        -H "Content-Type: application/json" \
        -d "$PAYMENT_DATA")
    
    if echo "$PAYMENT_RESPONSE" | grep -q "id"; then
        log_success "支付创建成功"
        PAYMENT_ID=$(echo "$PAYMENT_RESPONSE" | jq -r '.id')
        echo "支付ID: $PAYMENT_ID"
        
        # 处理支付
        PROCESS_RESPONSE=$(curl -s -X POST "$PAYMENT_SERVICE_URL/api/payments/$PAYMENT_ID/process")
        if echo "$PROCESS_RESPONSE" | grep -q "success"; then
            log_success "支付处理成功"
        else
            log_error "支付处理失败"
        fi
    else
        log_error "支付创建失败"
    fi
}

# 测试通知服务
test_notification_service() {
    log_info "测试通知服务..."
    
    if [ -z "$USER_ID" ]; then
        log_warning "跳过通知测试，缺少用户ID"
        return
    fi
    
    # 发送通知
    NOTIFICATION_DATA='{
        "userID": "'$USER_ID'",
        "type": "welcome",
        "channel": "email",
        "recipient": "test@example.com",
        "templateID": "welcome_email",
        "templateData": {
            "username": "testuser"
        }
    }'
    
    NOTIFICATION_RESPONSE=$(curl -s -X POST "$NOTIFICATION_SERVICE_URL/api/notifications/send" \
        -H "Content-Type: application/json" \
        -d "$NOTIFICATION_DATA")
    
    if echo "$NOTIFICATION_RESPONSE" | grep -q "id"; then
        log_success "通知发送成功"
        
        # 获取通知统计
        STATS_RESPONSE=$(curl -s "$NOTIFICATION_SERVICE_URL/api/notifications/stats")
        if echo "$STATS_RESPONSE" | grep -q "totalCount"; then
            log_success "获取通知统计成功"
        else
            log_error "获取通知统计失败"
        fi
    else
        log_error "通知发送失败"
    fi
}

# 测试API网关
test_api_gateway() {
    log_info "测试API网关..."
    
    # 通过网关访问用户服务
    GATEWAY_RESPONSE=$(curl -s "$API_GATEWAY_URL/user-service/health")
    if echo "$GATEWAY_RESPONSE" | grep -q "healthy"; then
        log_success "API网关代理功能正常"
    else
        log_error "API网关代理功能异常"
    fi
}

# 主测试流程
main() {
    echo "========================================"
    echo "       InsPlan 微服务 API 测试"
    echo "========================================"
    
    # 检查所有服务健康状态
    log_info "检查服务健康状态..."
    check_service_health "用户服务" "$USER_SERVICE_URL"
    check_service_health "计划服务" "$PLAN_SERVICE_URL"
    check_service_health "订单服务" "$ORDER_SERVICE_URL"
    check_service_health "支付服务" "$PAYMENT_SERVICE_URL"
    check_service_health "通知服务" "$NOTIFICATION_SERVICE_URL"
    check_service_health "API网关" "$API_GATEWAY_URL"
    
    echo ""
    
    # 运行功能测试
    test_user_service
    echo ""
    
    test_plan_service
    echo ""
    
    test_order_service
    echo ""
    
    test_payment_service
    echo ""
    
    test_notification_service
    echo ""
    
    test_api_gateway
    echo ""
    
    log_success "所有API测试完成！"
}

# 检查依赖
if ! command -v curl &> /dev/null; then
    log_error "curl 未安装，请先安装 curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_error "jq 未安装，请先安装 jq"
    exit 1
fi

# 运行测试
main