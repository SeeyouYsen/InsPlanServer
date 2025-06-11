# 🚀 InsPlan 微服务快速启动指南

## 一键启动

```bash
# 1. 进入项目目录
cd /Users/yuancan/Demos/InsPlan/microservices-migration

# 2. 验证项目完整性
./verify-project.sh

# 3. 启动所有服务
make start

# 4. 等待服务启动（约1-2分钟）
make health

# 5. 运行API测试
make test
```

## 服务访问地址

- **API Gateway**: http://localhost:8080
- **User Service**: http://localhost:8001
- **Plan Service**: http://localhost:8002  
- **Order Service**: http://localhost:8083
- **Payment Service**: http://localhost:8003
- **Notification Service**: http://localhost:8004

## 监控面板

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Kibana**: http://localhost:5601

## 快速测试

```bash
# 测试用户注册
curl -X POST http://localhost:8001/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"password123"}'

# 测试保险计划创建  
curl -X POST http://localhost:8002/api/plans \
  -H "Content-Type: application/json" \
  -d '{"name":"健康保险","premium":1000,"coverage":100000}'

# 查看所有保险计划
curl http://localhost:8002/api/plans
```

## 常用命令

```bash
make help      # 查看所有可用命令
make logs      # 查看服务日志
make stop      # 停止所有服务
make clean     # 清理容器和镜像
make scale     # 扩展服务实例
```

## 故障排除

如果遇到问题：

1. 检查 Docker 是否运行：`docker ps`
2. 查看服务日志：`make logs`
3. 重启服务：`make restart`
4. 验证项目：`./verify-project.sh`

享受你的微服务之旅！🎉
